
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


select concat('unique',
              '#', auk.constraint_name,
              '#', auk.key_column_name_list) line
  from dba.all_unique_keys auk
 where auk.user_name   = '{user}'
   and auk.schema_name = '{schema}'
   and auk.table_name  = '{table}';


select concat('primary',
              '#', apk.constraint_name,
              '#', apk.key_column_name_list) line
  from dba.all_primary_keys apk
 where apk.user_name   = '{user}'
   and apk.schema_name = '{schema}'
   and apk.table_name  = '{table}';


select concat('check',
              '#', ac.constraint_name,
              '#', ac.constraint_text) line
  from dba.all_constraints ac
 where ac.user_name       = '{user}'
   and ac.schema_name     = '{schema}'
   and ac.table_name      = '{table}'
   and ac.constraint_type = 'c';


select concat('trigger',
              '#', at.trigger_name,
              '#', at.event_action,
              '#', at.action_statement,
              '#', at.action_level,
              '#', at.action_timing,
              '#', at.event_table,
              '#', substring (at.action_statement from at.from_pos + 1 for (at.to_pos - at.from_pos - 1)),
              '#', at.event_column_list) line
  from (select ati.trigger_user            as trigger_user,
               ati.trigger_schema          as trigger_schema,
               ati.event_table             as event_table,
               ati.trigger_name            as trigger_name,
               lower(ati.event_action)     as event_action,
               lower(ati.action_statement) as action_statement,
               lower(ati.action_level)     as action_level,
               lower(ati.action_timing)    as action_timing,
               position ('.' in ati.action_statement) as from_pos,
               position ('(' in ati.action_statement) as to_pos,
               ati.event_column_list
          from dba.all_triggers ati) at
 where at.trigger_user    = '{user}'
   and at.trigger_schema  = '{schema}'
   and at.event_table     = '{table}';


select concat('function',
              '#', af.function_name,
              '#', af.language,
              '#', af.description) line
  from dba.all_functions af
  join dba.all_triggers at
    on at.trigger_user    = af.user_name
   and at.function_schema = af.schema_name
   and at.function_name   = af.function_name
 where af.user_name    = '{user}'
   and af.schema_name  = '{schema}'
   and at.event_table  = '{table}';


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
 where af.user_name    = '{user}'
   and af.schema_name  = '{schema}'
   and at.event_table  = '{table}';



select 'end';

