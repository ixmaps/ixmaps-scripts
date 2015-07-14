#!/bin/bash
# this script isolates all handoffs for entered asn - outputs boomerang and non-boomerang sets
# requires the following tables in the DB: boomerang_routes and non_boomerang_routes (can be generated with create-extra-db-tables.sh)

echo -e "Enter ASN: \c"
read input
NOW=$(date +"%d-%m-%Y")
boomOUT=$input"_boomerang_handoffs_"$NOW".csv"
nonboomOUT=$input"_non_boomerang_handoffs_"$NOW".csv"

echo "Calculating $input handoffs for boomerang routes..."
# generating the boomerang side of things
psql ixmaps -c "select traceroute_id, hop into boom_temp1 from boomerang_routes where asnum=$input order by traceroute_id, hop;"
psql ixmaps -c "select traceroute_id, max(hop) as hop into boom_temp2 from boom_temp1 group by traceroute_id;"
psql ixmaps -c "select b.traceroute_id, b.sub_time, b.submitter, b.zip_code, b.dest, b.hop, b.ip_addr, b.asnum, b.lat, b.long, b.mm_city, b.mm_country, b.gl_override into boom_temp1_pre from boomerang_routes as b where exists (select * from boom_temp2 where b.traceroute_id = boom_temp2.traceroute_id and b.hop = boom_temp2.hop) order by b.traceroute_id, b.hop;"
psql ixmaps -c "select b.traceroute_id, b.hop, b.ip_addr, b.asnum, b.lat, b.long, b.mm_city, b.mm_country, b.gl_override into boom_temp1_post from boomerang_routes as b where exists (select * from boom_temp2 where b.traceroute_id = boom_temp2.traceroute_id and b.hop = boom_temp2.hop+1) order by b.traceroute_id, b.hop;"

# adding the ISP names
psql ixmaps -c "select num,(case when short_name is null then name else short_name end) into temp_names from as_users order by num;"
psql ixmaps -c "select b.*, a.short_name into boom_temp2_pre from boom_temp1_pre as b join temp_names as a on b.asnum = a.num;"
psql ixmaps -c "select b.*, a.short_name into boom_temp2_post from boom_temp1_post as b join temp_names as a on b.asnum = a.num;"

# setting the tables up for the join with column name alters
psql ixmaps -c "alter table boom_temp2_pre rename column hop to from_hop;"
psql ixmaps -c "alter table boom_temp2_pre rename column ip_addr to from_ip_addr;"
psql ixmaps -c "alter table boom_temp2_pre rename column asnum to from_asnum;"
psql ixmaps -c "alter table boom_temp2_pre rename column lat to from_lat;"
psql ixmaps -c "alter table boom_temp2_pre rename column long to from_long;"
psql ixmaps -c "alter table boom_temp2_pre rename column mm_city to from_city;"
psql ixmaps -c "alter table boom_temp2_pre rename column mm_country to from_country;"
psql ixmaps -c "alter table boom_temp2_pre rename column gl_override to from_glo;"
psql ixmaps -c "alter table boom_temp2_pre rename column short_name to from_asn_name;"
psql ixmaps -c "alter table boom_temp2_post rename column hop to to_hop;"
psql ixmaps -c "alter table boom_temp2_post rename column ip_addr to to_ip_addr;"
psql ixmaps -c "alter table boom_temp2_post rename column asnum to to_asnum;"
psql ixmaps -c "alter table boom_temp2_post rename column lat to to_lat;"
psql ixmaps -c "alter table boom_temp2_post rename column long to to_long;"
psql ixmaps -c "alter table boom_temp2_post rename column mm_city to to_city;"
psql ixmaps -c "alter table boom_temp2_post rename column mm_country to to_country;"
psql ixmaps -c "alter table boom_temp2_post rename column gl_override to to_glo;"
psql ixmaps -c "alter table boom_temp2_post rename column short_name to to_asn_name;"

# and the big join and outputting of file
#psql ixmaps -c "select pre.*, post.to_hop, post.to_ip_addr, post.to_asnum, post.to_lat, post.to_long, post.to_city, post.to_country, post.to_glo, post.to_asn_name into boom_final from boom_temp2_pre as pre join boom_temp2_post as post on pre.traceroute_id = post.traceroute_id;"
psql ixmaps -c "select pre.traceroute_id, pre.sub_time, pre.submitter, pre.zip_code, pre.dest, pre.from_hop, pre.from_ip_addr, pre.from_asnum, pre.from_asn_name, pre.from_lat, pre.from_long, pre.from_city, pre.from_country, pre.from_glo, post.to_ip_addr, post.to_asnum, post.to_asn_name, post.to_lat, post.to_long, post.to_city, post.to_country, post.to_glo into boom_final from boom_temp2_pre as pre join boom_temp2_post as post on pre.traceroute_id = post.traceroute_id order by pre.traceroute_id;"
psql ixmaps -c "\copy boom_final to '$boomOUT' csv header"

# dropping the temp tables
psql ixmaps -c "drop table boom_temp1;"
psql ixmaps -c "drop table boom_temp2;"
psql ixmaps -c "drop table boom_temp1_pre;"
psql ixmaps -c "drop table boom_temp1_post;"
psql ixmaps -c "drop table boom_temp2_pre;"
psql ixmaps -c "drop table boom_temp2_post;"
psql ixmaps -c "drop table boom_final;" 


echo "Calculating $input handoffs for non-boomerang routes..."
# generating the non-boomerang side of things
psql ixmaps -c "select traceroute_id, hop into non_boom_temp1 from non_boomerang_routes where asnum=$input order by traceroute_id, hop;"
psql ixmaps -c "select traceroute_id, max(hop) as hop into non_boom_temp2 from non_boom_temp1 group by traceroute_id;"
psql ixmaps -c "select b.traceroute_id, b.sub_time, b.submitter, b.zip_code, b.dest, b.hop, b.ip_addr, b.asnum, b.lat, b.long, b.mm_city, b.mm_country, b.gl_override into non_boom_temp1_pre from non_boomerang_routes as b where exists (select * from non_boom_temp2 where b.traceroute_id = non_boom_temp2.traceroute_id and b.hop = non_boom_temp2.hop) order by b.traceroute_id, b.hop;"
psql ixmaps -c "select b.traceroute_id, b.hop, b.ip_addr, b.asnum, b.lat, b.long, b.mm_city, b.mm_country, b.gl_override into non_boom_temp1_post from non_boomerang_routes as b where exists (select * from non_boom_temp2 where b.traceroute_id = non_boom_temp2.traceroute_id and b.hop = non_boom_temp2.hop+1) order by b.traceroute_id, b.hop;"

# adding the ISP names
psql ixmaps -c "select b.*, a.short_name into non_boom_temp2_pre from non_boom_temp1_pre as b join temp_names as a on b.asnum = a.num;"
psql ixmaps -c "select b.*, a.short_name into non_boom_temp2_post from non_boom_temp1_post as b join temp_names as a on b.asnum = a.num;"

# setting the tables up for the join with column name alters
psql ixmaps -c "alter table non_boom_temp2_pre rename column hop to from_hop;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column ip_addr to from_ip_addr;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column asnum to from_asnum;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column lat to from_lat;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column long to from_long;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column mm_city to from_city;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column mm_country to from_country;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column gl_override to from_glo;"
psql ixmaps -c "alter table non_boom_temp2_pre rename column short_name to from_asn_name;"
psql ixmaps -c "alter table non_boom_temp2_post rename column hop to to_hop;"
psql ixmaps -c "alter table non_boom_temp2_post rename column ip_addr to to_ip_addr;"
psql ixmaps -c "alter table non_boom_temp2_post rename column asnum to to_asnum;"
psql ixmaps -c "alter table non_boom_temp2_post rename column lat to to_lat;"
psql ixmaps -c "alter table non_boom_temp2_post rename column long to to_long;"
psql ixmaps -c "alter table non_boom_temp2_post rename column mm_city to to_city;"
psql ixmaps -c "alter table non_boom_temp2_post rename column mm_country to to_country;"
psql ixmaps -c "alter table non_boom_temp2_post rename column gl_override to to_glo;"
psql ixmaps -c "alter table non_boom_temp2_post rename column short_name to to_asn_name;"

# and the big join and outputting of file
#psql ixmaps -c "select pre.*, post.to_hop, post.to_ip_addr, post.to_asnum, post.to_lat, post.to_long, post.to_city, post.to_country, post.to_glo, post.to_asn_name into non_boom_final from non_boom_temp2_pre as pre join non_boom_temp2_post as post on pre.traceroute_id = post.traceroute_id;"
psql ixmaps -c "select pre.traceroute_id, pre.sub_time, pre.submitter, pre.zip_code, pre.dest, pre.from_hop, pre.from_ip_addr, pre.from_asnum, pre.from_asn_name, pre.from_lat, pre.from_long, pre.from_city, pre.from_country, pre.from_glo, post.to_ip_addr, post.to_asnum, post.to_asn_name, post.to_lat, post.to_long, post.to_city, post.to_country, post.to_glo into non_boom_final from non_boom_temp2_pre as pre join non_boom_temp2_post as post on pre.traceroute_id = post.traceroute_id order by pre.traceroute_id;"
psql ixmaps -c "\copy non_boom_final to '$nonboomOUT' csv header"

# dropping the temp tables
psql ixmaps -c "drop table non_boom_temp1;"
psql ixmaps -c "drop table non_boom_temp2;"
psql ixmaps -c "drop table temp_names"
psql ixmaps -c "drop table non_boom_temp1_pre;"
psql ixmaps -c "drop table non_boom_temp1_post;"
psql ixmaps -c "drop table non_boom_temp2_pre;"
psql ixmaps -c "drop table non_boom_temp2_post;"
psql ixmaps -c "drop table non_boom_final;"