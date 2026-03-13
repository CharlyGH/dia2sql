
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
 order by atc.is_pk desc, atc.position;


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


select  concat('trigger',
              '#', trg.trigger_name,
              '#', trg.event_action,
              '#', trg.action_level,
              '#', trg.action_timing,
              '#', trg.event_schema,
              '#', trg.event_table,
              '#', trg.function_name,
              '#', af.language) line
  from (select ato.trigger_user,
               ato.trigger_schema,
               ato.trigger_name,
               ato.event_action,
               ato.action_level,
               ato.action_timing,
               ato.event_schema,
               ato.event_table,
               case when ato.from_pos = 0 
                    then substring (ato.action_statement from ato.blank_pos + 2 for (ato.to_pos - ato.blank_pos - 2))
                    else substring (ato.action_statement from ato.from_pos + 1 for (ato.to_pos - ato.from_pos - 1)) 
               end as function_name
         from (select ati.trigger_user            as trigger_user,
                      ati.trigger_schema          as trigger_schema,
                      ati.event_schema            as event_schema,
                      ati.event_table             as event_table,
                      ati.trigger_name            as trigger_name,
                      lower(ati.event_action)     as event_action,
                      lower(ati.action_statement) as action_statement,
                      lower(ati.action_level)     as action_level,
                      lower(ati.action_timing)    as action_timing,
                      length(ati.action_statement) - position (' ' in reverse(ati.action_statement)) as blank_pos,
                      position ('.' in ati.action_statement) as from_pos,
                      position ('(' in ati.action_statement) as to_pos
                 from dba.all_triggers ati) ato
                    ) trg
  join dba.all_functions af  on af.user_name     = trg.trigger_user
                            and af.schema_name   = trg.trigger_schema
                            and af.function_name = trg.function_name
 where trg.trigger_user    = '{user}'
   and trg.trigger_schema  = '{schema}'
   and trg.event_table     = '{table}'
 order by line;

select 'end';

