select concat('project',
              '#', m.project,
              '#', m.version)
  from {base}.metadata m;



select 'tablespaces';

select concat('tablespace',
              '#', ts.tablespace_name,
              '#', ts.tablespace_location) line
  from dba.all_tablespaces ts
 where ts.tablespace_owner = '{user}'
   and ts.tablespace_name in ({schemas});

select 'end';

select 'schemas';

select concat('schema',
              '#', als.schema_name,
              '#', als.schema_comment) line
  from dba.all_schemas als
 where als.user_name = '{user}'
   and als.schema_name in ({schemas});

select 'end';


select 'domains';

select concat('domain',
              '#', ad.domain_name,
              '#', ad.schema_name,
              '#', ad.type_name,
              '#', ad.is_nullable,
              '#', ad.default_value,
              '#', ad.constraint_name,
              '#', ad.check_constraint,
              '#', ad.domain_comment) line
  from dba.all_domains ad
 where ad.user_name = '{user}'
   and ad.schema_name in ({schemas})

 order by ad.domain_name;

select 'end';


select 'sequences';

select concat('sequence',
              '#', asq.sequence_name,
              '#', asq.schema_name,
              '#', asq.sequence_type,
              '#', asq.start_value,
              '#', asq.min_value,
              '#', asq.max_value,
              '#', asq.increment_by,
              '#', asq.cycle_sequence,
              '#', asq.sequence_comment) line
  from dba.all_sequences asq
 where asq.user_name = '{user}'
   and asq.schema_name in ({schemas})
 order by asq.sequence_name;

select 'end';

