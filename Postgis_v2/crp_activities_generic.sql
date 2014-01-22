* DB structure
** Main tables:
- crp_activities - list of activities
- crp_locations - list of locations, linked to crp_activities with crp_locations.act_id

** Activities Vocabularies (linked to crp_activities.fields as '|'-separated lists of IDs):
- iati_activity_status - list of IATI /activity-status, crp_activities.activity_status, imported, default 2
- cg_activity_hierarchy - list of CG-styled /iati-activity/@hierarchy, crp_activities.activity_hierarchy, imported, default 103
- cg_contacts - list of cg_contacts, crp_activities.contact_id, imported, id-linked ('|'-separated id for multiple)
- cg_organizations - not yet in place, list to come from CO, crp_activities.reporting_org (1-1) and crp_activities.participating_org (1-many)
- cg_programs - list of programs, crp_activities.cg_program, imported, id-linked
- cg_slos - list of SLOs, crp_activities.cg_slo, imported, id-linked
- cg_idos - list of CG IDOs, crp_activities.cg_ido, imported, id-linked
- cg_crp_idos - list of CRP IDOs, crp_activities.cg_crp_ido, imported, id-linked
- cg_technologies - list of technologies(ontology Soonho), crp_activities.cg_technology, imported csv (rdf alternative), id-link
- cg_commodities - list of commodities(Agrovoc), crp_activities.cg_commodity, to import(?) and id-link
- cg_internal_status - list of internal status values, crp_activities.internal_status, default 0

** Location Vocabularies (linked to crp_locations.fields as '|'-separated lists of IDs):
- cg_location_reach - list of CG-styled /location-reach/, crp_locations.cg_location_reach, imported draft version, id-linked
- cg_location_class - list of CG-styled /location-class/, crp_locations.cg_location_class, imported draft version, id-linked

*** Dropped vocabularies:
- cg_themes - list of initial CG themes

# Create crp_activities table - datastore for all activities:
drop table crp_activities cascade;
CREATE TABLE crp_activities (
id serial primary key,
cg_identifier text,
title text,
activity_status text default 2,
last_updated date default CURRENT_TIMESTAMP,
activity_hierarchy text default '103',
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
participating_org_tmp text,
description text,
budget_period_start date,
budget_period_end date,
budget_value integer,
budget_value_currency integer,
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

alter table crp_activities owner to crpuser;
alter table crp_locations owner to crpuser;

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

** Import activities data from CSVs:
cd ...crpdata/data_sources/crp_file_location
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=*** password=***" file.csv -nln tablename






