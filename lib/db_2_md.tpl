select 'metadata';


select concat('table',
              '#', at.table_name,
              '#', at.schema_name,
              '#', at.tablespace_name,
              '#', at.table_comment) line
  from dba.all_tables at
 where at.user_name   = '{user}'
   and at.schema_name = '{schema}'
   and at.table_name  = '{table}';


select concat('column',
              '#', atc.column_name,
              '#', atc.domain_name,
              '#', atc.is_nullable,
              '#', atc.default_value,
              '#', atc.column_comment) line
  from dba.all_table_columns atc
 where atc.user_name   = '{user}'
   and atc.schema_name = '{schema}'
   and atc.table_name  = '{table}'
 order by atc.position;


select concat('primary',
              '#', apk.constraint_name,
              '#', apk.key_column_name_list) line
  from dba.all_primary_keys apk
 where apk.user_name   = '{user}'
   and apk.schema_name = '{schema}'
   and apk.table_name  = '{table}';

select concat('data',
              '#', m.project,
              '#', m.version) line
  from {schema}.{table} m;

select 'end';

