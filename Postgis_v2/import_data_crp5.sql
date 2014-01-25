# various;
alter table crp_locations add column cg_program text, add column cg_identifier text;
update crp_locations l set cg_program = (select cg_program from crp_activities a where a.id = l.act_id),
	cg_identifier = (select cg_identifier from crp_activities a where a.id = l.act_id);
# drop create tmp tables - crp_activities_generic.sql

# import activities and basins(+merge)
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=* dbname=crpdata2 password=*" WLE_activities.csv

for i in `ls *shp`; do sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=* dbname=crpdata2 password=*" $i -append -nln crp5_basins -nlt MULTIPOLYGON; done;

update wle_activities set end_planned = '31-Dec-13' where end_planned  = 'Dec-13';
update wle_activities set end_planned = NULL where end_planned = '';
update wle_activities set start_planned = NULL where start_planned = '';

delete from crp_activities_tmp;
insert into crp_activities_tmp (cg_identifier, act_date_start_planned, act_date_end_planned, contact_tmp, title, description, reporting_org_tmp, reporting_org_type_tmp, reporting_org_type, budget_value, budget_value_currency, cg_program_tmp, cg_program, project_website, cg_remarks, cg_source, cg_ido, cg_crp_ido, cg_slo, activity_status)
select cg_internal as cg_identifier,
(case when length(start_planned) = 4 then to_date(start_planned, 'YYYY') else to_date(nullif(start_planned,''),'DD-Mon-YY') end) as act_date_start_planned,
(case when length(end_planned) = 4 then to_date(end_planned, 'YYYY') else to_date(end_planned,'DD-Mon-YY') end) as act_date_end_planned,
contact as contact_tmp,
title,
description,
rep_org_name as reporting_org_tmp,
rep_org_type as reporting_org_type_tmp,
'80' as reporting_org_type,
NULLIF(yearly_budget,'')::decimal as budget_value,
currency as budget_value_currency,
'CRP 5' as cg_program_tmp,
'CRP-5' as cg_program,
'http://wle.cgiar.org/' as project_website,
effort_by_basin || '(effort_by_basin);' || "w1&2" || '(w1&2);'|| w3 || '(w3);'|| bilateral || '(bilateral);'|| total || '(total);' as cg_remarks,
'Glenn to update|MasterTable_WLE_Activities2013_v1.xlsx' as cg_source,
'to update' as cg_ido,
'to update' as cg_crp_ido,
'to update' as cg_slo,
'2' as activity_status from wle_activities;

# incomplete data: idos, crp_idos, slos, partners, technologies, commodities

# build location

# insert into crp_location table - section to review:

# select distinct ;-separated regions
select distinct trim( both ' ' from unnest(regexp_split_to_array(regions,';'))) from wle_activities;
select distinct trim( both ' ' from unnest(regexp_split_to_array(countries,';'))) from wle_activities;
create table wle_activities_tmp as select * from wle_activities;
update wle_activities_tmp set countries = ()
	where countries = '';

select distinct trim( both ' ' from unnest(regexp_split_to_array(regions,';'))) from wle_activities_tmp where countries = '';

drop table g13120_crp5;
create table g13120_crp5 as select g.* from g13120 g, crp5_basins c where ST_Intersects(g.geom, c.wkb_geometry) and ST_Area(ST_Intersection(g.geom, c.wkb_geometry))> 0.01;
alter table g13120_crp5  owner to crpuser;

update wle_activities_tmp set countries = replace(countries, 'Lao PDR', 'Lao People\'s Democratic Republic');
update wle_activities_tmp set countries = replace(countries, 'DRC','Democratic Republic of the Congo');
update wle_activities_tmp set countries = replace(countries, 'Congo DRC','Democratic Republic of the Congo');
update wle_activities_tmp set countries = replace(countries, 'Iran','Iran  (Islamic Republic of)');
update wle_activities_tmp set countries = replace(countries, 'Cote D\'Ivoire','Côte d\'Ivoire');
update wle_activities_tmp set countries = replace(countries, 'Tanzania','United Republic of Tanzania');
update wle_activities_tmp set countries = replace(countries, '','');

----imp - get countries geocoded in the xls but not intersecting any river basin:
with countries as (select distinct trim( both ' ' from unnest(regexp_split_to_array(countries,';'))) as cnt from wle_activities_tmp )
select * from countries c where not exists (select 1 from g13120_crp5 g where g.adm0_name = c.cnt);

delete from crp_locations_tmp;
insert into crp_locations_tmp (act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name, cg_location_class, cg_location_reach)
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name '1' as cg_location_class, '101' as cg_location_reach, from g13122 gl, crp2_basins b where adm0_code = (
    select adm0_code::numeric from g13120 where  ST_Intersects(b.geom, g13120.geom) and ST_Area(ST_Intersects(b.geom, g13120.geom)>0.01);

# update location_reach and cg_location_class
update crp_locations_tmp set cg_location_class = '1' where exists (select 1 from crp_activities_tmp where crp_activities_tmp.id = crp_locations_tmp.act_id);
update crp_locations_tmp set cg_location_reach = '101' where exists (select 1 from crp_activities_tmp where crp_activities_tmp.id = crp_locations_tmp.act_id);

update crp_locations l set cg_program = (select cg_program from crp_activities a where a.id = l.act_id),
	cg_identifier = (select cg_identifier from crp_activities a where a.id = l.act_id);

# insert all into crp_activities and crp_locations
insert into crp_activities select * from crp_activities_tmp;
insert into crp_locations select * from crp_locations_tmp;

