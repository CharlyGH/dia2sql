select concat(t.schema_name,
              '#', t.table_name) line
  from dba.all_tables t
  left join (select distinct 'YES' hist, t.event_schema, t.event_table 
               from dba.all_triggers t) tr
         on tr.event_schema  = t.schema_name 
        and tr.event_table   = t.table_name  
 where t.user_name = '{user}'
   and t.schema_name in ({schemas})
 order by t.schema_name, coalesce(tr.hist,'NO'), t.table_name;
 
