select 'references';

select concat('reference',
              '#', afk.constraint_name,
              '#', afk.schema_name,
              '#', afk.table_name,
              '#', afk.column_name_list,
              '#', afk.ref_schema_name,
              '#', afk.ref_table_name,
              '#', afk.ref_column_name_list) line
  from dba.all_foreign_keys afk
 where afk.user_name   = '{user}'
   and afk.schema_name in ({schemas})
 order by afk.schema_name,afk.table_name,afk.ref_schema_name,afk.ref_table_name;


select 'end';

