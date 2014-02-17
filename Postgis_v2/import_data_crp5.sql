# various;
alter table crp_locations add column cg_program text, add column cg_identifier text;
update crp_locations l set cg_program = (select cg_program from crp_activities a where a.id = l.act_id),
	cg_identifier = (select cg_identifier from crp_activities a where a.id = l.act_id);
# drop create tmp tables - crp_activities_generic.sql

# import activities and basins(+merge)
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=* dbname=crpdata2 password=*" WLE_activities.csv

for i in `ls *shp`; do sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=* dbname=crpdata2 password=*" $i -append -nln crp5_basins -nlt MULTIPOLYGON; done;

# import crp5 IDO mapping
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=* dbname=crpdata2 password=*" CRP5_SRP_IDO.csv

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
(select cg_ido_code from cg_crp_idos where cg_crp_idos.code = (select "crp5 ido" from crp5_srp_ido where crp5_srp_ido."crp5 srp" = wle_activities.cluster limit 1)) as cg_ido,
(select "crp5 ido" from crp5_srp_ido where crp5_srp_ido."crp5 srp" = wle_activities.cluster) as cg_crp_ido,
'to update' as cg_slo,
'2' as activity_status from wle_activities;

# incomplete data: idos, crp_idos, slos, partners, technologies, commodities

# build location

# insert into crp_location table - section to review:

# select distinct ;-separated regions
select distinct trim( both ' ' from unnest(regexp_split_to_array(regions,';'))) from wle_activities;
select distinct trim( both ' ' from unnest(regexp_split_to_array(countries,';'))) from wle_activities;
drop table wle_activities_tmp;
create table wle_activities_tmp as select * from wle_activities;
select distinct trim( both ' ' from unnest(regexp_split_to_array(regions,';'))) from wle_activities_tmp where countries = '';
# to do this if updating countries from regions
update wle_activities_tmp set countries = ()
	where countries = '';

update wle_activities_tmp set countries = replace(countries, 'Lao PDR', 'Lao People''s Democratic Republic');
update wle_activities_tmp set countries = replace(countries, 'Congo DRC','Democratic Republic of the Congo');
update wle_activities_tmp set countries = replace(countries, 'DRC','Democratic Republic of the Congo');
update wle_activities_tmp set countries = replace(countries, 'Iran','Iran  (Islamic Republic of)');
update wle_activities_tmp set countries = replace(countries, 'Cote D''Ivoire','Côte d''Ivoire');
update wle_activities_tmp set countries = replace(countries, 'Tanzania','United Republic of Tanzania');
update wle_activities_tmp set countries = replace(countries, 'Vietnam','Viet Nam');

drop table g13120_crp5;
create table g13120_crp5 as select g.* from g13120 g, crp5_basins c where ST_Intersects(g.geom, c.wkb_geometry) and ST_Area(ST_Intersection(g.geom, c.wkb_geometry))> 0.01;
alter table g13120_crp5  owner to crpuser;

drop table g13122_crp5;
create table g13122_crp5 as select g.* from g13122 g, crp5_basins c where ST_Intersects(g.geom, c.wkb_geometry) and ST_Area(ST_Intersection(g.geom, c.wkb_geometry))> 0.001;
alter table g13122_crp5 owner to crpuser;

----imp - get countries geocoded in the xls but not intersecting any river basin:
with countries as (select distinct trim( both ' ' from unnest(regexp_split_to_array(countries,';'))) as cnt from wle_activities_tmp )
select * from countries c where not exists (select 1 from g13122_crp5 g where g.adm0_name = c.cnt);


delete from crp_locations_tmp;
insert into crp_locations_tmp (act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name, cg_location_class, cg_location_reach, cg_program, cg_identifier)
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122_crp5 g , wle_activities_tmp w
where position(g.adm0_name in w.countries ) > 0
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('madagascar' in lower(w.countries) ) > 0 and g.adm0_name = 'Madagascar'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('sri lanka' in lower(w.countries) ) > 0 and g.adm0_name = 'Sri Lanka' and g.adm2_code in (25832,
25833, 25835, 25837,25843 ,25850 ,25852)
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('liberia' in lower(w.countries) ) > 0 and g.adm0_name = 'Liberia'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('viet nam' in lower(w.countries) ) > 0 and g.adm0_name = 'Viet Nam'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('morocco' in lower(w.countries) ) > 0 and g.adm0_name = 'Morocco' and g.adm2_code in (21794, 21799, 21802,21824, 21826, 21827, 21828)
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('lebanon' in lower(w.countries) ) > 0 and g.adm0_name = 'Lebanon'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('israel' in lower(w.countries) ) > 0 and g.adm0_name = 'Israel'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('palestine' in lower(w.countries) ) > 0 and g.adm0_name = 'Gaza Strip'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('palestine' in lower(w.countries) ) > 0 and g.adm0_name = 'West Bank'
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('jordan' in lower(w.countries) ) > 0 and g.adm0_name = 'Jordan' and g.adm2_code in (
36714,36715,36716,36717,36718,36720,36722,36724,36725,36726,36728,36729,36730,36731,36732,36734,36735,36736,36737,36738,36739,36741,36745,36746,65713,65714,65715,65716,65717,65718,65719,65720,65721,65722,65723,65724,65725,65726,65727,65729,65733,65734,65735,65737,65739,65740,65741,65742,65743,65744,65745,65746)
union all
select (select id from crp_activities_tmp where crp_activities_tmp.cg_identifier = w.cg_internal) as act_id,
g.adm0_code, g.adm0_name, g.adm1_code, g.adm1_name, g.adm2_code,g.adm2_name, '1' as cg_location_class, '101' as cg_location_reach, 'CRP-5' as cg_program, w.cg_internal as cg_identifier from g13122 g , wle_activities_tmp w
where position('el salvador' in lower(w.countries) ) > 0 and g.adm0_name = 'El Salvador' and g.adm2_code in (15591,15592,15593,15594,15598,15599,15606,15613,15781,15782,15783,15786,15787)
order by cg_identifier;


# drop g13120_crp5
drop table g13120_crp5, g13122_crp5;

# insert all into crp_activities and crp_locations
insert into crp_activities select * from crp_activities_tmp;
insert into crp_locations select * from crp_locations_tmp;

