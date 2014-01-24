# various;
alter table crp_locations add column cg_program text, add column cg_identifier text;
update crp_locations l set cg_program = (select cg_program from crp_activities a where a.id = l.act_id),
	cg_identifier = (select cg_identifier from crp_activities a where a.id = l.act_id);
# drop create tmp tables