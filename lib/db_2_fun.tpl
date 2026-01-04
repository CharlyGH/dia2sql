
select concat('function',
              '#', af.function_name,
              '#', af.language,
              '#', at.event_table,
              '#', af.description) line
  from dba.all_functions af
  join dba.all_triggers at
    on at.trigger_user    = af.user_name
   and at.function_schema = af.schema_name
   and at.function_name   = af.function_name
 where af.user_name   = '{user}'
   and af.schema_name = '{schema}'
   and at.event_table = '{table}'
 group by af.function_name, af.language, at.event_table, af.description
 order by af.function_name;


select concat('definition',
              '#', afd.function_name, chr(10),
                   lower(afd.function_definition), chr(10),
              '###') line
  from dba.all_function_definitions afd
  join dba.all_functions af
    on af.user_name     = afd.user_name
   and af.schema_name   = afd.schema_name
   and af.function_name = afd.function_name
  join dba.all_triggers at
    on at.trigger_user    = afd.user_name
   and at.function_schema = afd.schema_name
   and at.function_name   = af.function_name
 where af.user_name   = '{user}'
   and af.schema_name = '{schema}'
   and at.event_table = '{table}'
 group by afd.function_name, afd.function_definition
 order by afd.function_name;


