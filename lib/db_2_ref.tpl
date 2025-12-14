select concat(t.schema_name, '#', t.table_name) line
  from dba.all_tables t
 where t.user_name = '{user}'
   and t.schema_name in ({schemas})
 order by t.schema_name, t.table_name;
 
