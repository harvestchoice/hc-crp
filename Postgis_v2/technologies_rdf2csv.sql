# deprecated - moved technologies to csv, to review in case we use ontologies
# import technologies from RDF and reshape - should be done differently
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" owl_technologies.csv -nln owl_technologies

drop table cg_technologies;
create table cg_technologies ( id text, id_tmp text, name text, subclassof text, subclassof_tmp text);

insert into cg_technologies (id_tmp) select distinct field_1 from owl_technologies where field_1 like '%http://webprotege.stanford.edu/classes/%';

update cg_technologies t set
	name = (select field_3 from owl_technologies ot where ot.field_1 = t.id_tmp and ot.field_2 like '%label%' limit 1),
	subclassof_tmp = (select field_3 from owl_technologies ot where ot.field_1 = t.id_tmp and ot.field_2 like '%subClassOf%' limit 1);

update cg_technologies t set subclassof_tmp = (select id_tmp from cg_technologies where name = 'Biotechnology') where name = 'Plant biotechnology';

update cg_technologies t set id = ('x' || lpad(md5(id_tmp), 16, '0'))::bit(28)::int;
update cg_technologies t set subclassof = ('x' || lpad(md5(subclassof_tmp), 16, '0'))::bit(28)::int;

# actual:
sudo -u postgres ogr2ogr -f "PostgreSQL" PG:"host=localhost user=*** dbname=crpdata2 password=***" cg_technologies.csv
alter table cg_technologies add column id text;
alter table cg_technologies add column parent_id text;
update cg_technologies set id = ogc_fid;
update cg_technologies t1 set parent_id = (
	select t2.ogc_fid from cg_technologies t2 where t2.code = left(t1.code, length(t1.code) - 1));

