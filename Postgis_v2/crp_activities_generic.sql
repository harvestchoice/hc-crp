** Import activities data from CSVs:
cd ...crpdata/data_sources/crp_file_location
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=*** password=***" file.csv -nln tablename

** Create crp_activities table - datastore for all activities:
drop table crp_activities;
CREATE TABLE crp_activities (
id serial primary key,
cg_identifier text,
title text,
activity_status text,
last_updated date default CURRENT_TIMESTAMP,
hierarchy text,
iati_identifier text,
act_date_start_planned date,
act_date_start_actual date,
act_date_end_planned date,
act_date_end_actual date,
contact_id text,
contact_tmp text,
reporting_org text,
reporting_org_type text,
participating_org text,
participating_org_type text,
participating_org_role text,
description text,
budget_type integer,
budget_period_start date,
budget_period_end date,
budget_value integer,
budget_value_currency integer,
budget_value_date date,
collaboration_type text default '2',
cg_program text,
cg_slo text,
cg_ido text,
cg_crp_ido text,
cg_technology text,
cg_technology_tmp text,
cg_commodity text,
cg_commodity_tmp text,
document_url text,
document_format text,
document_category text,
project_website text,
source text,
remarks text,
internal_status text default 0,
completeness integer );

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
drop table crp_locations;
CREATE TABLE crp_locations (
id serial primary key,
act_id integer,
adm0_code numeric,
adm0_name text,
adm1_code numeric,
adm1_name text,
adm2_code numeric,
adm2_name text);

# Locations link table - store info the IATI way, in case at some point we want to conform to the standard's location structure (to revise)
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







