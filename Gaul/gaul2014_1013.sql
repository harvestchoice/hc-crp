#import shp to PG
shp2pgsql -I -s 4326 -W "latin1" G2014_2013_2.shp test | sudo -u postgres psql -d crpdata2

# check for duplicate geometries:
select adm0_code, adm0_name, adm1_code, adm1_name, adm2_code, adm2_name, ST_Area(geom) from g2014_2013_2 where adm2_code in (select adm2_code from g2014_2013_2 group by adm2_code having count(*) > 1) order by adm0_code, adm1_code, adm2_code;
=> duplicate_adm2_code.csv
# not sure what to do with those as they have different adm2_name, leave them as they are

# check for invalid geometires
select gid, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code, adm2_name, reason(ST_IsValidDetail(geom)), ST_AsText(location(ST_IsValidDetail(geom))) as location from g2014_2013_2 where ST_IsValid(geom) = false order by adm0_code;
=> self_intersects.csv
select adm0_code, adm0_name, count(*) from g2014_2013_2 where ST_IsValid(geom) = false group by adm0_code, adm0_name order by adm0_code;
=> self_intersects_by_country.csv

# fix geometires:
update g2014_2013_2 set geom = ST_MakeValid(geom);

## Remove very small polygons within multipolygons - doesn't work very well
# split multipolygons to polygons
create table g14_13_2 as ( select gid, adm2_code, adm2_name, status, disp_area, str_year, exp_year, adm0_code, adm0_name, adm1_code, adm1_name, (st_dump(geom)).* from g2014_2013_2 );
=> SELECT 88155
create index g14_13_2_geom_gist on g14_13_2 using gist(geom);
# delete small polygons
delete from g14_13_2 where ST_Area(geom) < 0.00000000018;
=> DELETE 31
# union back
create table g14_13_2_res as ( select gid, adm2_code, adm2_name, status, disp_area, str_year, exp_year, adm0_code, adm0_name, adm1_code, adm1_name, ST_Union(geom) as geom from g14_13_2 group by gid, adm2_code, adm2_name, status, disp_area, str_year, exp_year, adm0_code, adm0_name, adm1_code, adm1_name);
create index g14_13_2_res_geom_gist on g14_13_2_res using gist(geom);

## build gaul level 1 and 0 - TODO

create table g1413_1 as (select gid, adm2_code, adm2_name, status, disp_area, str_year, exp_year, adm0_code, adm0_name, adm1_code, adm1_name, ST_Multi(ST_Union(geom) as geom from g1413_2_top group by adm1_code);


# CLEAN TOPOLOGY - to review at some point in case I need to use topology functions to clean or simplify polygons: http://trac.osgeo.org/postgis/wiki/UsersWikiSimplifyWithTopologyExt
# enable topology extension on Posgis
sudo -u postgres psql -d crpdata2 -f topology.sql
create table g1413_2_top as (select gid, adm2_code, adm2_name, status, disp_area, str_year, exp_year, adm0_code, adm0_name, adm1_code, adm1_name, (st_dump(geom)).* from g1413_2 );
create index ng1413_2_top_geom_gist on g1413_2_top using gist(geom);

-- adds the new geom column that will contain simplified geoms
alter table g1413_2_top add column simple_geom geometry(POLYGON, 4326);
-- create new topology
select CreateTopology('topo1',4326,0);
-- add all departements polygons to topology in one operation as a collection
select ST_CreateTopoGeo('topo1',ST_Collect(geom)) from g1413_2_top;

select CreateTopology('topo2',4326,0);
select ST_CreateTopoGeo('topo2', geom)
from (
       select ST_Collect(st_simplifyPreserveTopology(geom, 1000)) as geom
       from topo1.edge_data
) as foo;

with simple_face as (
       select st_getFaceGeometry('topo2', face_id) as geom
       from topo2.face
       where face_id > 0
) update new_dept d set simple_geom = sf.geom
from simple_face sf
where st_intersects(d.geom, sf.geom)
and st_area(st_intersection(sf.geom, d.geom))/st_area(sf.geom) > 0.5;

SELECT topology.DropTopology('topo1');



## build gaul level 1 and 0














