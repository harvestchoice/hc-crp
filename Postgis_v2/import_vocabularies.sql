# Crate IATI codes tables

** Copy db
# Create DB backup
sudo -u postgres pg_dump crpdata > crpdata011414.sql

# Import backup to new DB
sudo -u postgres psql -d crpdata2 < crpdata011414.sql

** Create CG vocabularies

- CGIAR Activity Hierarchy (IATI like) for crp_activities.activity_hierarchy(PG)
drop table cg_activity_hierarchy;
CREATE TABLE cg_activity_hierarchy ( code integer, name text);
INSERT INTO cg_activity_hierarchy VALUES (101, 'Flagship Project'),(102, 'Activity Cluster'),(103, 'Other');

- Theme vocabulary for crp_activities.cg_theme(PG) -> dropped
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_themes.csv -nln cg_themes

- PROGRAMS (cg_programs) vocabulary for crp_activities.cg_program(PG)
# CRP numbers, relevant CAADP Pillar, ASARECA Regional Programs, CORAF Research Programs, etc.
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_programs.csv -nln cg_programs

- CGIAr SLOs (cg_slos) for crp_activities.cg_slo(PG)
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_slos.csv -nln cg_slos

- CGIAR IDO (cg_idos) for crp_activities.cg_ido(PG)
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_idos.csv -nln cg_idos

- CGIAR CRP IDO (cg_crp_idos) for crp_activities.cg_crp_ido(PG) - includes cg_ido_id field to link to the corresponding cg_ido
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_crp_idos.csv -nln cg_crp_idos

- CGIAR TECHNOLOGIES (cg_technologies) for crp_activities.technologies(PG)
# web-protege use deprecated - to review in case we come back
python technologies_rdf2csv.py
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_technologies_owl.csv
psql technologies_rdf2csv.sql
# actual:
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_technologies.csv

- CGIAR COMMODITIES (cg_commodities) for crp_activities.commodities(PG) TODO?

- CGIAR Internal Status for crp_activities.cg_internal_status(PG)
CREATE TABLE cg_internal_status ( id integer, name text);
INSERT INTO cg_internal_status VALUES (0, 'draft'),(1, 'under review'),(2, 'validated'), (3, 'retired');

** Create location-related vocabularies
- Location-reach for crp_locations.cg_loc_reach
CREATE TABLE cg_location_reach ( id integer, name text);
INSERT INTO cg_location_reach VALUES (101, 'Action/intervention'),(102, 'Potential beneficiaries'),(103, 'Partner organization'), (104, 'Experimental farm or nursery');
or
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_location_reach.csv -nln cg_location_reach

- Location-class for crp_locations.cg_loc_class
CREATE TABLE cg_location_class ( id integer, name text);
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_location_class.csv -nln cg_location_class

** Import IATI vocabularies
cd ...crpdata/vocabularies
- ActivityStatus for /activity-status/@code(IATI) and crp_activities.activity_status(PG)
wget http://data.aidinfolabs.org/data/codelist/ActivityStatus.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" ActivityStatus.csv -nln iati_activity_status PGSQL_OGR_FID=code

- ContactType for /contact-info/@type(IATI) and contact_info.type(PG) - Contact type dropped
wget http://data.aidinfolabs.org/data/codelist/ContactType.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" ContactType.csv -nln iati_contact_type

- Organisation Identifier for /reporting-org/@ref(IATI) and crp_activities.reporting_org_id(PG) and /participating-org/@ref(IATI) and crp_activities.participating_org_id(PG) - vocabulary not yet defined
# Organization ref codes should be built starting from the registries http://bit.ly/iati-org-reg + code assigned by the registry
# Most of the CG centers don't have registry assigned codes(?) -> use codes from the list imported below:
wget "http://data.aidinfolabs.org/data/codelist/OrganisationIdentifier/version/1.0/lang/en.csv" -O OrganisationIdentifier.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" OrganisationIdentifier.csv -nln iati_organisation_identifier

- Organisation Type for /reporting-org/@type(IATI) and crp_activities.reporting_org_type(PG) and /participating-org/@type(IATI) and crp_activities.participating_org_type(PG) - not yet used, to add more CG Orgs
# for most of the centers Organization Type = 40 - Multilateral
wget "http://data.aidinfolabs.org/data/codelist/OrganisationType/version/1.0/lang/en.csv" -O OrganisationType.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" OrganisationType.csv -nln iati_organisation_type

- Organisation Role for /participating-org/@role>(IATI) and crp_activities.participating_org_role(PG) - not yet used
wget "http://data.aidinfolabs.org/data/codelist/OrganisationRole/version/1.0/lang/en.csv" -O OrganisationRole.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" OrganisationType.csv -nln iati_organisation_role

- FileFormat for /document-link/@format(IATI) and crp_activities.document_format(PG) - dropped
wget "http://data.aidinfolabs.org/data/codelist/FileFormat/version/1.0/lang/en.csv" -O FileFormat.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" FileFormat.csv -nln iati_file_format

- DocumentCategory for /document-link/category/@code(IATI) and crp_activities.document_category(PG) - not yet used, dropped
wget "http://data.aidinfolabs.org/data/codelist/DocumentCategory/version/1.0/lang/en.csv" -O DocumentCategory.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" DocumentCategory.csv -nln iati_document_category

- BudgetType for /budget/@type(IATI) and crp_activities.budget_type(PG) - dropped
wget "http://data.aidinfolabs.org/data/codelist/BudgetType/version/1.0/lang/en.csv" -O BudgetType.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" BudgetType.csv -nln iati_budget_type

- Currency for /budget/value/@currency(IATI) and crp_activities.budget_value_currency(PG)
wget "http://data.aidinfolabs.org/data/codelist/Currency/version/1.0/lang/en.csv" -O Currency.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" Currency.csv -nln iati_currency

- RelatedActivityType for /related-activity/@type(IATI) and crp_activities.related_activity_type(PG) - dropped
wget "http://data.aidinfolabs.org/data/codelist/RelatedActivityType/version/1.0/lang/en.csv" -O RelatedActivityType.csv
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" RelatedActivityType.csv -nln iati_related_activity_type













