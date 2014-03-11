** Import contacts
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" contacts.CSV -nln contacts

insert into cg_contacts (person_name_first, person_name_last, cg_organisation, job_title, telephone, cg_email, mailing_address) select "first name", "last name", company, "job title", "business phone", "e_mail display name", "business city" ||', ' || "business country/region" from contacts where "e_mail display name" <> '';

update cg_contacts set mailing_address = trim(both ',' from mailing_address);
delete from cg_contacts where person_name_first='' or person_name_last='';
delete from cg_contacts where position('@' in email) = 0;

# delete groups
delete from cg_contacts where person_name_last in (select distinct cg_organisation from cg_contacts) or person_name_first in (select distinct cg_organisation from cg_contacts);

# grab email
update cg_contacts set email = array_to_string(regexp_matches(cg_email, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}'),'');

# update organization_id
update cg_contacts set organisation = (select code from iati_organisation_identifier where iati_organisation_identifier.abbreviation = cg_contacts.cg_organisation limit 1) where cg_organisation<>'';


** Import data CRP4 into crp_activities and crp_locations; docs from Amanda Wyatt (IFPRI), geocoded by DG
delete from crp_activities;
insert into crp_activities (cg_identifier, act_date_start_planned, act_date_end_planned, contact_tmp, reporting_org_tmp, reporting_org_type_tmp, participating_org_tmp, description, budget_value, cg_program_tmp, cg_technology_tmp,
cg_commodity_tmp, project_website, cg_remarks)
select "activity code" as cg_identifier, "activity start date"::date as act_date_start_planned, "activity end date"::date as act_date_end_planned,
"contact name" as contact_tmp, "reporting organization" as reporting_org_tmp, "reporting organization type" as reporting_org_type_tmp,
partners as participating_org_tmp, description, NULLIF("activity budget",'')::int as budget_value,
'CRP 4' as cg_program_tmp, "target technology(ies)" as cg_technology_tmp, commodity as cg_commodity_tmp,
website as project_website, theme || '(theme)' as cg_remarks from dg_crp4_activity_analysis;

# update title, source, cg_program
update crp_activities set title = (select title from dg_crp4_geocoding where dg_crp4_geocoding.source_project_id = crp_activities.cg_identifier limit 1) where cg_program_tmp = 'CRP 4';
update crp_activities set cg_source = (select "source detail" || 'Amanda Wyatt (IFPRI)' from dg_crp4_geocoding where dg_crp4_geocoding.source_project_id = crp_activities.cg_identifier limit 1) where cg_program_tmp = 'CRP 4';
update crp_activities set cg_program = 'CRP-4' where cg_program_tmp = 'CRP 4';
update crp_activities set cg_slo = 'CG-SLO-3' where cg_program_tmp = 'CRP 4';

# update CG IDOs, CRP IDOs
update crp_activities set cg_ido = 'CRP4-IDO-02' where cg_remarks = 'Agriculture Associated Diseases(theme)' and cg_program_tmp = 'CRP 4';
update crp_activities set cg_ido = 'CRP4-IDO-01', cg_crp_ido = 'CG-IDO-03' where cg_remarks = 'Biofortification(theme)'  and cg_program_tmp = 'CRP 4';
update crp_activities set cg_ido = 'CRP4-IDO-04', cg_crp_ido = 'CG-IDO-08' where cg_remarks = 'Integrated Programs and Policies(theme)' and cg_program_tmp = 'CRP 4';
update crp_activities set cg_ido = 'CRP4-IDO-01', cg_crp_ido = 'CG-IDO-03' where cg_remarks = 'Nutrition Sensitive Value Chains(theme)' and cg_program_tmp = 'CRP 4';
update crp_activities set cg_ido = 'CRP4-IDO-03', cg_crp_ido = 'CG-IDO-05' where lower(title) like '%gender%' and cg_program_tmp = 'CRP 4';

# update technologies, commodities
update crp_activities set cg_technology_tmp = replace(cg_technology_tmp, 'Education', 'Educational');
update crp_activities set cg_technology_tmp = replace(cg_technology_tmp, 'Educational policy', 'Educational technology');
update crp_activities a set cg_technology = (select string_agg(t.id::varchar,'|') from cg_technologies t where
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',1)) or
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',2)) or
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',3))) where cg_program_tmp = 'CRP 4';

# update contacts ids - from cg_contacts table
update crp_activities a set contact_id = (select string_agg(c.id::varchar,'|') from cg_contacts c where
position(lower(c.person_name_first) in lower(a.contact_tmp)) > 0
and position(lower(c.person_name_last) in lower(a.contact_tmp)) > 0) where cg_program_tmp = 'CRP 4';

# other updates: Partners - trim pipes ("|"), Source
update crp_activities set participating_org_tmp = trim(both '|' from participating_org_tmp);
update crp_activities set reporting_org_type = '70' where reporting_org_type_tmp = 'Private Sector (70)';
update crp_activities set reporting_org_type = '21' where reporting_org_type_tmp = 'International NGO (21)';
update crp_activities set cg_source = 'A4NH_where we work (updated 2013)|Amanda Wyatt (IFPRI)|DG_CRP4_activity analysis.xlsx,DG_CRP4 geocoding.xlsx(DG)';

# update location
# add point geometry to dg_crp4_geocoding
alter table dg_crp4_geocoding add column geom geometry(Point,4326);
update dg_crp4_geocoding set geom = st_geomfromtext('POINT(' || longitude || ' ' || latitude || ')', 4326) where latitude != '';
create index dg_crp4_geocoding_geom_gist ON dg_crp4_geocoding USING GIST (geom);

# add temp act_id
alter table dg_crp4_geocoding add column act_id integer;
update dg_crp4_geocoding g set act_id = (select id from crp_activities a where a.cg_identifier = g.source_project_id);

# insert into crp_location table
delete from crp_locations;
insert into crp_locations (act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name)
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name from g13122 gl, dg_crp4_geocoding g where adm0_code = (
    select adm0_code::numeric from g13120 where  ST_Intersects(g.geom, g13120.geom) and g.precision = '6')
    union all
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name from g13122 gl, dg_crp4_geocoding g where adm1_code = (
    select adm1_code::numeric from g13121 where  ST_Intersects(g.geom, g13121.geom) and g.precision = '4')
    union all
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name from g13122 gl, dg_crp4_geocoding g where adm2_code = (
    select adm2_code::numeric from g13122 where  ST_Intersects(g.geom, g13122.geom) and (g.precision = '3' or g.precision = '1'));

# update location_reach and cg_location_class
update crp_locations set cg_location_class = '1' where exists (select 1 from crp_activities where crp_activities.id = crp_locations.act_id and crp_activities.cg_program_tmp = 'CRP 4');

update crp_locations set cg_location_reach = '101' where exists (select 1 from crp_activities where crp_activities.id = crp_locations.act_id and crp_activities.cg_program_tmp = 'CRP 4');

# update cg_identifier - later
# select replace ('CRP4_3', 'CRP4_', '');
# update crp_activities set cg_identifier = replace(cg_identifier, 'CRP4_', '')


** Import data CRP2 into crp_activities and crp_locations; data from Pascale Sabbagh, deogoded by DG
# use tmp table not to overflow serial key because of delete operations
delete from crp_activities_tmp;
insert into crp_activities_tmp (cg_identifier, act_date_start_planned, act_date_end_planned, contact_tmp, reporting_org_tmp, reporting_org_type_tmp, participating_org_tmp, description, budget_value, cg_program_tmp, cg_technology_tmp,
cg_commodity_tmp, project_website, cg_remarks, activity_status)
select "activity code" as cg_identifier, (case when length("activity start date") = 4 then to_date("activity start date", 'YYYY') else to_date("activity start date",'Month YYYY') end) as act_date_start_planned, (case when length("activity end date") = 4 then to_date("activity end date", 'YYYY') else to_date("activity end date",'Month YYYY') end) as act_date_end_planned,
"contact name" as contact_tmp, "reporting organization" as reporting_org_tmp, "reporting organization type" as reporting_org_type_tmp,
partners as participating_org_tmp, description, NULLIF("activity budget",'')::decimal as budget_value,
'CRP 2' as cg_program_tmp, "target technology(ies)" as cg_technology_tmp, commodity as cg_commodity_tmp,
website as project_website, theme || '(theme);' || "st number" || '(st);'|| "op number" || '(op)' as cg_remarks, status as activity_status from dg_crp2_activity_analysis;

# update title, source, cg_program, slo
update crp_activities_tmp set
	title = (select title from dg_crp2_geocoding where dg_crp2_geocoding."activity id" = crp_activities_tmp.cg_identifier limit 1),
	cg_source = (select source || '| Pascale Sabbagh (IFPRI), geocoded by DG - IFPRI_CRP2 geoANDanalysis_final.xlsx' from dg_crp2_geocoding where dg_crp2_geocoding."activity id" = crp_activities_tmp.cg_identifier limit 1),
	cg_program = 'CRP-2',
	cg_ido = 'CG-IDO-08',
	cg_slo = 'to_update',
	reporting_org_type = '21';

# update status;
update crp_activities_tmp set activity_status = '1' where activity_status = 'Pipeline/identification';
update crp_activities_tmp set activity_status = '2' where activity_status = 'Implementation';
update crp_activities_tmp set activity_status = '3' where activity_status = 'Completion';

# update CG IDOs, CRP IDOs;
update crp_activities_tmp set cg_ido = 'CG-IDO-05' where cg_remarks like '%G.1(st)%' or cg_remarks like '%G.2(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-01' where cg_remarks like '%1.1(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-02' where cg_remarks like '%1.2(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-03' where cg_remarks like '%1.3(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-04' where cg_remarks like '%2.1(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-05' where cg_remarks like '%3.1(st)%' or cg_remarks like '%3.2(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-06' where cg_remarks like '%1.4(st)%' or cg_remarks like '%2.4(st)%';
update crp_activities_tmp set cg_crp_ido = 'CRP2-IDO-07' where cg_remarks like '%2.2(st)%' or cg_remarks like '%2.3(st)%';

update crp_activities_tmp set cg_remarks = replace(cg_remarks, '1.1(st)','Foresight and Strategic Scenarios-1.1(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '1.2(st)','Macroeconomic, Trade, and Investment Policies-1.2(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '1.3(st)','Production and Technology Policies-1.3(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '1.4(st)','Social Protection Policies-1.4(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '2.1(st)','Policy Processes-2.1(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '2.2(st)','Governance of Rural Services-2.2(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '2.3(st)','Collective Action and Property Rights-2.3(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '2.4(st)','Institutions to Strengthen the Assets of the Poor-2.4(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '3.1(st)','Innovations across the Value Chain-3.1(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, '3.2(st)','Impact of Upgrading Value Chains-3.2(st)');
update crp_activities_tmp set cg_remarks = replace(cg_remarks, 'G.2(st)','Strategic Gender Research-G.2(st)');

# update technologies, commodities;
update crp_activities_tmp a set cg_technology = (select string_agg(t.id::varchar,'|') from cg_technologies t where
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',1)) or
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',2)) or
lower(t.name) = lower(split_part(a.cg_technology_tmp,'|',3)));
update crp_activities_tmp set cg_technology_tmp = replace(cg_technology_tmp, 'Education ', 'Educational ');
update crp_activities_tmp set cg_technology_tmp = replace(cg_technology_tmp, 'Educational policy', 'Educational technology');

# update contacts ids - from cg_contacts table;
update crp_activities_tmp a set contact_id = (select string_agg(c.id::varchar,'|') from cg_contacts c where
position(lower(c.person_name_first) in lower(a.contact_tmp)) > 0
and position(lower(c.person_name_last) in lower(a.contact_tmp)) > 0);

# other updates: Partners - trim pipes ("|"), Source;
update crp_activities_tmp set participating_org_tmp = trim(both '|' from participating_org_tmp);
# to come back to this if we get better participating organisation names
update crp_activities a set participating_org = (select string_agg(t.code::varchar,'|') from iati_organisation_identifier t where array(select unnest(regexp_split_to_array(lower(t.name), E'\\s+')) intersect select unnest(regexp_split_to_array(regexp_split_to_table(lower(a.participating_org_tmp),E'\\|'),E'\\s+')) order by 1) = array(select unnest(regexp_split_to_array(lower(t.name), E'\\s+')) order by 1)) where id in (87,75);

select id, participating_org,participating_org_type,participating_org_role,participating_org_tmp,participating_org_type_tmp,participating_org_role_tmp from crp_activities where id in (87,75);

select array( select unnest(regexp_split_to_array('World Bank', E'\\s+')) intersect select unnest(regexp_split_to_array(regexp_split_to_table('World Bank|Yale University',E'\\|'),E'\\s+')));



select array(select unnest(regexp_split_to_array(lower('World Bank'), E'\\s+')) intersect select unnest(regexp_split_to_array(regexp_split_to_table(lower('World Bank|Yale University'),E'\\|'),E'\\s+')) order by 1) = array(select unnest(regexp_split_to_array(lower('World Bank'), E'\\s+')) order by 1);


SELECT @(array_length(array(select unnest(regexp_split_to_array(t.name, E'\\s+')) intersect
              select unnest(regexp_split_to_array(regexp_split_to_table(a.participating_org_tmp,E'\\|'),E'\\s+'))),1) - array_length(regexp_split_to_array(t.name, E'\\s+'),1)) <= 2;


# update location
# add point geometry to dg_crp4_geocoding
alter table dg_crp2_geocoding add column geom geometry(Point,4326);
update dg_crp2_geocoding set geom = st_geomfromtext('POINT(' || longitude || ' ' || latitude || ')', 4326) where latitude != '';
create index dg_crp2_geocoding_geom_gist ON dg_crp2_geocoding USING GIST (geom);

# add temp act_id
alter table dg_crp2_geocoding add column act_id integer;
update dg_crp2_geocoding g set act_id = (select id from crp_activities_tmp a where a.cg_identifier = g."activity id");

# insert into crp_location table
delete from crp_locations_tmp;
insert into crp_locations_tmp (act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name)
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name from g13122 gl, dg_crp2_geocoding g where adm0_code = (
    select adm0_code::numeric from g13120 where  ST_Intersects(g.geom, g13120.geom) and g.precision = '6')
    union all
select g.act_id, adm0_code, adm0_name, adm1_code, adm1_name, adm2_code,adm2_name from g13122 gl, dg_crp2_geocoding g where adm0_code = (
    select adm0_code::numeric from g13120 where  ST_Intersects(g.geom, g13120.geom) and g.precision = '8');

# update location_reach and cg_location_class
update crp_locations_tmp set cg_location_class = '1' where exists (select 1 from crp_activities_tmp where crp_activities_tmp.id = crp_locations_tmp.act_id);
update crp_locations_tmp set cg_location_reach = '101' where exists (select 1 from crp_activities_tmp where crp_activities_tmp.id = crp_locations_tmp.act_id);

# insert all into crp_activities and crp_locations
insert into crp_activities select * from crp_activities_tmp;
insert into crp_locations select * from crp_locations_tmp;
