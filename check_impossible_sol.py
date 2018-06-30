#!/usr/bin/python

import psycopg2
import psycopg2.extras
from math import radians, cos, sin, asin, sqrt

# - find the min latency for each hop, removing any -1s. I am *not* 'looking forward' for min latencies, just taking the lowest round trip of the 4 attempts (intentionally)
# - determine the 'hop_time' for each hop; that is, current_hop-min_latency minus previous_hop-min_latency
# - determine speed of light (sol_time) in fibre between the lat/longs of each hop
# - if hop_time/2 is less than the SOL number, flag both that hop and the previous hop as suspicious (since we don't know which router is at fault, *and we can't say anything more with certainty, right*)

# Step 1: create temp1 with a range of traceroute_ids (or all)
# select * into temp1 from tr_item where traceroute_id >= 1000 and traceroute_id < 2000 order by traceroute_id, hop, attempt;
# Step 2: run

# NB: these are now embedded in the code, do not need to run these manually
# alter table temp1 add column min_latency integer, add column hop_time integer;
# alter table temp1 drop column attempt, drop column status, drop column rtt_ms;
# select temp1.*,ip.mm_lat,ip.mm_long into temp2 from temp1 join ip_addr_info as ip on temp1.ip_addr = ip.ip_addr;
# alter table temp2 add column sol_time float, add column sol_flag integer;

def main():
    try:
        conn = psycopg2.connect("dbname='ixmaps' user='ixmaps' host='localhost'")
    except:
        print "I am unable to connect to the database"
    cur = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

    set_min_latency(conn, cur)
    set_speed_of_light(conn, cur)

    conn.close()

def set_min_latency(conn, cur):
    cur.execute("""ALTER TABLE temp1 ADD COLUMN min_latency integer, ADD COLUMN hop_time integer""")
    # loop over the hops in tr_item
    cur.execute("""SELECT * FROM temp1 ORDER BY traceroute_id,hop""")
    rows = cur.fetchall()
    for row in rows:
        print row['traceroute_id'],"   ", row['hop'], "   ", row['attempt']
        # set the minimum latency, ignoring negative values
        # unfortunately, we decided to have rtt_ms as type int, so we will see a lot of rtt_ms of 0. This implies we are going to need to have a higher threshold for flagging (eg if difference > 1)
        # see also in GatherTr.php:
        # "rtt_ms"=>round($latency)
        query = """UPDATE temp1 SET min_latency = (SELECT rtt_ms FROM temp1 WHERE traceroute_id=%s AND hop=%s and rtt_ms >= 0 ORDER BY rtt_ms ASC LIMIT 1) WHERE traceroute_id=%s AND hop=%s;"""
        data = (row['traceroute_id'], row['hop'], row['traceroute_id'], row['hop'])
        cur.execute(query, data)
        conn.commit()           # do I need this one?

    # now that we have the correct latency, get rid of the rest of the attempts
    cur.execute("""DELETE FROM temp1 WHERE attempt != 1""");
    cur.execute("""ALTER TABLE temp1 DROP COLUMN attempt, DROP COLUMN status, DROP COLUMN rtt_ms""")
    conn.commit()           # again, do I need this one?

    # we loop again, now that we've cut the table size by 3/4s
    # NB: this will not produce a hop_time for any non-consecutive hops (eg 14, 15, 20)
    # this is irrelevant (I think), since we don't care about comparing non-consecutive hops
    # if we want to fix this, we will need to reintroduce 'index' as in set_speed_of_light
    cur.execute("""SELECT * FROM temp1 ORDER BY traceroute_id,hop""")
    rows = cur.fetchall()
    for row in rows:
        print row['traceroute_id'],"   ", row['hop']
        query = """UPDATE temp1 SET hop_time = ((SELECT min_latency FROM temp1 WHERE traceroute_id=%s AND hop=%s) - (SELECT min_latency FROM temp1 WHERE traceroute_id=%s AND hop=%s)) WHERE traceroute_id=%s and hop=%s;"""
        data = (row['traceroute_id'], row['hop'], row['traceroute_id'], row['hop']-1, row['traceroute_id'], row['hop'])
        cur.execute(query, data)
        conn.commit()


def set_speed_of_light(conn, cur):
    # cur.execute("""SELECT temp1.*,ip.mm_lat,ip.mm_long INTO temp2 FROM temp1 JOIN ip_addr_info AS ip ON temp1.ip_addr = ip.ip_addr""")
    # cur.execute("""ALTER TABLE temp2 ADD COLUMN sol_time float, ADD COLUMN sol_flag integer""")
    # unflag everything
    # cur.execute("""UPDATE temp2 SET sol_flag = NULL""")
    # figure out how many times we're going to iterate
    cur.execute("""SELECT DISTINCT traceroute_id FROM temp2 ORDER BY traceroute_id""")
    trs = cur.fetchall()
    for tr in trs:
        print "-----",tr['traceroute_id'],"-----"

        query = """SELECT * FROM temp2 WHERE traceroute_id=%s ORDER BY hop"""
        data = (tr['traceroute_id'],)
        cur.execute(query, data)
        ips = cur.fetchall()
        for index, ip in enumerate(ips):
            print ip['hop'],": ",ip['ip_addr']

            if ip['hop'] != 1:
                prev_lat = ips[index-1]['mm_lat']
                prev_long = ips[index-1]['mm_long']
                prev_hop = ips[index-1]['hop']

                hop_distance = haversine(prev_lat, prev_long, ip['mm_lat'], ip['mm_long'])
                # SOL in fibre is about 2/3 that in ether, so roughly 200,000km/sec or 200km/ms
                time = hop_distance/200

                # we only want to do this for consecutive hops, that is if the previous hops hop number is one less than the current hop number
                if prev_hop == ip['hop']-1 and ip['hop_time'] is not None:
                    # TODO: can I use the cursor to do the updates? I've got to assume that would work, and it would be sooooo much easier
                    query = """UPDATE temp2 SET sol_time=%s WHERE traceroute_id=%s AND hop=%s"""
                    data = (time, tr['traceroute_id'], ip['hop'])
                    cur.execute(query, data)
                    print "            distance (km):", hop_distance
                    print "            sol time (ms):", time
                    # convenience feature - flagging. This is crude tho, and does not take into account the issue of using integer with rtt_ms/min_latency/hop_time
                    if time > ip['hop_time']/2:
                        print "            hop time (ms):", ip['hop_time']/2
                        query = """UPDATE temp2 SET sol_flag=1 WHERE traceroute_id=%s AND hop=%s"""
                        data = (tr['traceroute_id'], ip['hop'])
                        cur.execute(query, data)
                        # flag previous router as well, I think this is necessary?
                        query = """UPDATE temp2 SET sol_flag=1 WHERE traceroute_id=%s AND hop=%s"""
                        data = (tr['traceroute_id'], index)
                        cur.execute(query, data)

        conn.commit()

# https://stackoverflow.com/questions/4913349/haversine-formula-in-python-bearing-and-distance-between-two-gps-points
def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])

    # haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371 # Radius of earth in kilometers. Use 3956 for miles
    return c * r

main()