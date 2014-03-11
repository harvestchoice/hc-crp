# Dump tables
COPY crp_activities to '/tmp/crp_activities.csv' with csv header;
COPY crp_locations to '/tmp/crp_locations.csv' with csv header;
COPY iati_activity_status to '/tmp/iati_activity_status.csv' with csv header;
COPY cg_programs to '/tmp/cg_programs.csv' with csv header;
COPY cg_contacts to '/tmp/cg_contacts.csv' with csv header;
COPY cg_slos to '/tmp/cg_slos.csv' with csv header;
COPY cg_idos to '/tmp/cg_idos.csv' with csv header;
COPY cg_technologies to '/tmp/cg_technologies.csv' with csv header;
COPY cg_internal_status to '/tmp/cg_internal_status.csv' with csv header;
COPY cg_location_reach to '/tmp/cg_location_reach.csv' with csv header;
COPY cg_location_class to '/tmp/cg_location_class.csv' with csv header;

# Create crp_activities table - datastore for all activities:
drop table crp_activities cascade;
CREATE TABLE crp_activities (
id serial primary key,
cg_identifier text,
title text,
activity_status text default 2,
last_updated date default CURRENT_TIMESTAMP,
cg_activity_hierarchy text default '103',
iati_identifier text,
act_date_start_planned date,
act_date_start_actual date,
act_date_end_planned date,
act_date_end_actual date,
contact_id text,
contact_tmp text,
reporting_org text,
reporting_org_type text,
reporting_org_tmp text,
reporting_org_type_tmp text,
participating_org text,
participating_org_type text,
participating_org_role text,
participating_org_tmp text,
participating_org_type_tmp text,
participating_org_role_tmp text,
description text,
budget_period_start date,
budget_period_end date,
budget_value integer,
budget_value_currency text,
budget_value_date date,
budget_collaboration_type text default '2',
cg_program text,
cg_program_tmp text,
cg_slo text,
cg_slo_tmp text,
cg_ido text,
cg_ido_tmp text,
cg_crp_ido text,
cg_crp_ido_tmp text,
cg_technology text,
cg_technology_tmp text,
cg_commodity text,
cg_commodity_tmp text,
document_url text,
project_website text,
cg_source text,
cg_remarks text,
cg_internal_status text default 0,
cg_completeness integer );
alter table crp_activities owner to crpuser;

** Create contacts table
CREATE TABLE cg_contacts (
id serial primary key,
person_name_first text,
person_name_last text,
organisation text,
cg_organisation text,
job_title text,
website text,
telephone text,
email text,
cg_email text,
mailing_address text );

** Create crp_locations table
# Locations link table - store info the CG way: admin units
drop table crp_locations cascade;
CREATE TABLE crp_locations (
id serial primary key,
act_id integer,
cg_location_reach text,
cg_location_class text,
adm0_code numeric,
adm0_name text,
adm1_code numeric,
adm1_name text,
adm2_code numeric,
adm2_name text);
alter table crp_locations owner to crpuser;

# Locations link table - store info the IATI way, in case at some point we want to conform to the IATI location structure (to revise)
CREATE TABLE crp_locations_iati (
cg_identifier text,
precision text,
feature_class text,
latitude real,
longitude real,
);

** Create crp_partners table
CREATE TABLE crp_partners (
cg_identifier text,
participating_org_id text,
participating_org_type text,
participating_org_role text);

** Import activities data from CSVs:
cd ...crpdata/data_sources/crp_file_location
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=*** password=***" file.csv -nln tablename

# Create tmp tables for temporary import of activities
drop table crp_activities_tmp cascade;
CREATE TABLE crp_activities_tmp (
id serial primary key,
cg_identifier text,
title text,
activity_status text default 2,
last_updated date default CURRENT_TIMESTAMP,
cg_activity_hierarchy text default '103',
iati_identifier text,
act_date_start_planned date,
act_date_start_actual date,
act_date_end_planned date,
act_date_end_actual date,
contact_id text,
contact_tmp text,
reporting_org text,
reporting_org_type text,
reporting_org_tmp text,
reporting_org_type_tmp text,
participating_org text,
participating_org_type text,
participating_org_role text,
participating_org_tmp text,
participating_org_type_tmp text,
participating_org_role_tmp text,
description text,
budget_period_start date,
budget_period_end date,
budget_value integer,
budget_value_currency text,
budget_value_date date,
budget_collaboration_type text default '2',
cg_program text,
cg_program_tmp text,
cg_slo text,
cg_slo_tmp text,
cg_ido text,
cg_ido_tmp text,
cg_crp_ido text,
cg_crp_ido_tmp text,
cg_technology text,
cg_technology_tmp text,
cg_commodity text,
cg_commodity_tmp text,
document_url text,
project_website text,
cg_source text,
cg_remarks text,
cg_internal_status text default 0,
cg_completeness integer );
alter table crp_activities_tmp owner to crpuser;
SELECT setval(pg_get_serial_sequence('crp_activities_tmp', 'id'), (SELECT MAX(id) FROM crp_activities));

drop table crp_locations_tmp cascade;
CREATE TABLE crp_locations_tmp (
id serial primary key,
act_id integer,
cg_location_reach text,
cg_location_class text,
adm0_code numeric,
adm0_name text,
adm1_code numeric,
adm1_name text,
adm2_code numeric,
adm2_name text,
cg_program text,
cg_identifier text);
alter table crp_locations_tmp owner to crpuser;
SELECT setval(pg_get_serial_sequence('crp_locations_tmp', 'id'), (SELECT MAX(id) FROM crp_locations));
