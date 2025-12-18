drop schema dba cascade;
create schema dba;
comment on schema dba is 'Views for all relevant objects';

--drop function dba.simple_name;
create or replace function dba.simple_name (string text, delimiter text) returns text
    language sql
    immutable
    returns null on null input
    return substring (string from position (delimiter in string) + 1);


--drop function dba.trigger_function_name (statement text, field text);
create or replace function dba.trigger_function_name (statement text, field text) returns text as
    $$
    declare
        ret_val      text;
        arg_len      integer := length (statement);
        prefix       text    := substring (statement from 1 for 17);
        suffix       text    := substring (statement from (arg_len - 1) for 2);
        full_name    text;
        delim_pos    integer;
        schema_name  text;
        table_name   text;
    begin
        if prefix != 'EXECUTE FUNCTION '  or suffix != '()' then
            raise exception 'invalid action statement [%][%]', prefix, suffix;
        end if;
        full_name := substring (statement from 18 for (arg_len - 19));
        delim_pos := position ('.' in full_name);
        if field = 'schema' then
            ret_val := substring (full_name from 1 for (delim_pos - 1));
        elsif field = 'table' then
            ret_val := substring (full_name from (delim_pos + 1));
        else
            raise exception 'invalid action statement field [%]', field;
        end if;
        return ret_val;
    end;
    $$
    language plpgsql
    immutable
    returns null on null input;



-- drop view dba.all_tablespaces;
create or replace view dba.all_tablespaces as
select
       ts.spcname                                as tablespace_name,
       pg_catalog.pg_get_userbyid(ts.spcowner)   as tablespace_owner,
       pg_catalog.pg_tablespace_location(ts.oid) as tablespace_location
  from pg_catalog.pg_tablespace ts;


-- drop view dba.all_domains;
create or replace view dba.all_domains as
select 
       u.usename as user_name,
       n.nspname as schema_name,
       t.typname as domain_name,
       pg_catalog.format_type(t.typbasetype, t.typtypmod) as type_name,
       case when t.typnotnull
            then 'NO'
            else 'YES'
       end          as is_nullable,
       t.typdefault as default_value,
       c.conname    as constraint_name,
       c.contype    as constraint_type,
       pg_catalog.array_to_string(array(select pg_catalog.pg_get_constraintdef(r.oid, true)
                                          from pg_catalog.pg_constraint r
                                         where t.oid = r.contypid 
                                           and r.contype = 'c'),
                                        ' ') as check_constraint,
       d.description as domain_comment
  from pg_catalog.pg_type t
 inner join pg_catalog.pg_user as u on u.usesysid = t.typowner
  left join pg_catalog.pg_namespace n on n.oid = t.typnamespace
  left join pg_catalog.pg_description d  on d.classoid = t.tableoid
                                        and d.objoid = t.oid
                                        and d.objsubid = 0
  left join pg_catalog.pg_constraint c  on c.contypid = t.oid
                                       and c.contype = 'c'
 where t.typtype = 'd'
   and n.nspname <> 'pg_catalog'
   and n.nspname <> 'information_schema';




--drop view dba.all_tables;
create or replace view dba.all_tables as
select u.usename  as user_name,
       ns.nspname as schema_name,
       c.relname  as table_name,
       t.tablespace as tablespace_name,
       pd.description as table_comment
  from pg_catalog.pg_class as c
 inner join pg_catalog.pg_class as cc on cc.relname = 'pg_class'
 inner join pg_catalog.pg_namespace as ns on ns.oid = c.relnamespace
 inner join pg_catalog.pg_user as u on u.usesysid = c.relowner
 inner join pg_catalog.pg_tables as t on t.schemaname = ns.nspname and t.tablename = c.relname
 left outer join pg_catalog.pg_description as pd on pd.objoid = c.oid and pd.objsubid = 0 and pd.classoid = cc.oid
 where c.relispartition = 'f'
   and c.relkind in ('r','p')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_views;
create or replace view dba.all_views as
select u.usename  as user_name,
       ns.nspname as schema_name,
       c.relname  as view_name,
       pd.description as view_comment
  from pg_catalog.pg_class as c
 inner join pg_catalog.pg_class as cc on cc.relname = 'pg_class'
 inner join pg_catalog.pg_namespace as ns on ns.oid = c.relnamespace
 inner join pg_catalog.pg_user as u on u.usesysid = c.relowner
 left outer join pg_catalog.pg_description as pd on pd.objoid = c.oid and pd.objsubid = 0 and pd.classoid = cc.oid
 where c.relispartition = 'f'
   and c.relkind in ('v')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_table_columns;
create or replace view dba.all_table_columns as
select co.table_catalog as user_name,
       co.table_schema as schema_name,
       co.table_name,
       co.column_name,
       co.ordinal_position as position,
       co.is_nullable,
       dba.simple_name(pg_catalog.format_type(a.atttypid, a.atttypmod),'.') as domain_name,
       co.data_type,
       co.numeric_precision as precision,
       co.numeric_scale as scale,
       pg_catalog.pg_get_expr(d.adbin, d.adrelid, true) default_value,
       pd.description as column_comment
  from information_schema.columns as co
 inner join pg_catalog.pg_class as cc on cc.relname = 'pg_class'
 inner join pg_catalog.pg_class as cl on cl.relname = co.table_name
 inner join pg_catalog.pg_attribute as a on a.attrelid = cl.oid and a.attname = co.column_name
 inner join pg_catalog.pg_namespace as ns on ns.oid = cl.relnamespace and ns.nspname = co.table_schema
 inner join pg_catalog.pg_user as u on u.usesysid = cl.relowner and u.usename = co.table_catalog
 left outer join pg_catalog.pg_attrdef as d   on d.adrelid = a.attrelid
                                             and d.adnum = a.attnum
                                             and a.atthasdef
 left outer join pg_catalog.pg_description as pd on  pd.objoid = cl.oid
                                                 and pd.objsubid = co.ordinal_position and pd.classoid = cc.oid
 where cl.relispartition = 'f'
   and cl.relkind in ('r','p')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_view_columns;
create or replace view dba.all_view_columns as
select co.table_catalog as user_name,
       co.table_schema as schema_name,
       co.table_name as view_name,
       co.column_name,
       co.ordinal_position as position,
       co.is_nullable,
       co.data_type,
       co.numeric_precision as precision,
       co.numeric_scale as scale,
       pd.description as column_comment
  from information_schema.columns as co
 inner join pg_catalog.pg_class as cc on cc.relname = 'pg_class'
 inner join pg_catalog.pg_class as cl on cl.relname = co.table_name
 inner join pg_catalog.pg_namespace as ns on ns.oid = cl.relnamespace and ns.nspname = co.table_schema
 inner join pg_catalog.pg_user as u on u.usesysid = cl.relowner and u.usename = co.table_catalog
 left outer join pg_catalog.pg_description as pd on  pd.objoid = cl.oid
                                                 and pd.objsubid = co.ordinal_position and pd.classoid = cc.oid
 where cl.relispartition = 'f'
   and cl.relkind in ('v')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_table_partitions;
create or replace view dba.all_table_partitions as
select
    u.usename       as user_name,
    nspa.nspname    as parent_schema_name,
    pa.relname      as parent_table_name,
    nsch.nspname    as child_schema_name,
    ch.relname      as child_table_name
 from pg_inherits as inh 
    inner join pg_catalog.pg_class         as pa      on inh.inhparent  = pa.oid
    inner join pg_catalog.pg_class         as ch      on inh.inhrelid   = ch.oid
    inner join pg_catalog.pg_namespace     as nspa    on nspa.oid       = pa.relnamespace
    inner join pg_catalog.pg_namespace     as nsch    on nsch.oid       = ch.relnamespace
    inner join pg_catalog.pg_user          as u       on u.usesysid     = pa.relowner
 where pa.relkind in ('p');


--drop view dba.all_index_partitions;
create or replace view dba.all_index_partitions as
select
    u.usename       as user_name,
    nspa.nspname    as parent_schema_name,
    pa.relname      as parent_index_name,
    nsch.nspname    as child_schema_name,
    ch.relname      as child_index_name
 from pg_inherits as inh 
    inner join pg_catalog.pg_class         as pa      on inh.inhparent  = pa.oid
    inner join pg_catalog.pg_class         as ch      on inh.inhrelid   = ch.oid
    inner join pg_catalog.pg_namespace     as nspa    on nspa.oid       = pa.relnamespace
    inner join pg_catalog.pg_namespace     as nsch    on nsch.oid       = ch.relnamespace
    inner join pg_catalog.pg_user          as u       on u.usesysid     = pa.relowner
  where pa.relkind in ('I');


--drop view dba.all_unique_key_columns;
create or replace view dba.all_unique_key_columns as
select tco.constraint_catalog as user_name,
       tco.constraint_schema  as schema_name,
       kcu.table_name,
       tco.constraint_name,
       kcu.column_name,
       kcu.ordinal_position as position
  from information_schema.table_constraints tco
  inner join information_schema.key_column_usage kcu on  kcu.constraint_catalog = tco.constraint_catalog
                                                     and kcu.constraint_schema  = tco.constraint_schema
                                                     and kcu.constraint_name    = tco.constraint_name
 inner join pg_catalog.pg_class as cl on cl.relname = kcu.table_name
 inner join pg_catalog.pg_namespace as ns on ns.oid = cl.relnamespace and ns.nspname = tco.table_schema
 where tco.constraint_type = 'UNIQUE'
   and cl.relispartition = 'f'
   and cl.relkind in ('r','p')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_unique_keys;
create or replace view dba.all_unique_keys as
select user_name,
       schema_name,
       table_name,
       constraint_name,
       string_agg (column_name, ',' order by position) as key_column_name_list
  from dba.all_unique_key_columns
 group by user_name, schema_name, table_name, constraint_name;
 

--drop view dba.all_primary_key_columns;
create or replace view dba.all_primary_key_columns as
select tco.constraint_catalog as user_name,
       tco.constraint_schema  as schema_name,
       kcu.table_name,
       tco.constraint_name,
       kcu.column_name,
       kcu.ordinal_position as position
  from information_schema.table_constraints tco
  inner join information_schema.key_column_usage kcu on  kcu.constraint_catalog = tco.constraint_catalog
                                                     and kcu.constraint_schema  = tco.constraint_schema
                                                     and kcu.constraint_name    = tco.constraint_name
 inner join pg_catalog.pg_class as cl on cl.relname = kcu.table_name
 inner join pg_catalog.pg_namespace as ns on ns.oid = cl.relnamespace and ns.nspname = tco.table_schema
 where tco.constraint_type = 'PRIMARY KEY'
   and cl.relispartition = 'f'
   and cl.relkind in ('r','p')
   and ns.nspname != 'information_schema'
   and ns.nspname not like 'pg_%';


--drop view dba.all_primary_keys;
create or replace view dba.all_primary_keys as
select user_name,
       schema_name,
       table_name,
       constraint_name,
       string_agg (column_name, ',' order by position) as key_column_name_list
  from dba.all_primary_key_columns
 group by user_name, schema_name, table_name, constraint_name;
 

--drop view dba.all_foreign_key_columns;
create or replace view dba.all_foreign_key_columns as
select rc.constraint_catalog     as  user_name,
       rc.constraint_schema      as schema_name,
       kcu.table_name            as table_name,
       kcu.column_name           as column_name,
       cc.ordinal_position       as position,
       rc.constraint_name        as constraint_name,
       ccu.table_schema          as ref_schema_name,
       ccu.table_name            as ref_table_name,
       ccu.column_name           as ref_column_name,
       cr.ordinal_position       as ref_position,
       rc.unique_constraint_name as ref_constraint_name
  from information_schema.referential_constraints rc
  join information_schema.key_column_usage        kcu
    on kcu.table_catalog      = rc.constraint_catalog
   and kcu.table_schema       = rc.constraint_schema
   and kcu.constraint_name    = rc.constraint_name
  join information_schema.constraint_column_usage ccu
    on ccu.constraint_catalog = rc.unique_constraint_catalog
   and ccu.constraint_schema  = rc.unique_constraint_schema
   and ccu.constraint_name    = rc.unique_constraint_name
  join information_schema.columns cc
    on cc.table_catalog = kcu.table_catalog
   and cc.table_schema  = kcu.table_schema
   and cc.table_name    = kcu.table_name
   and cc.column_name   = kcu.column_name
  join information_schema.columns cr
    on cr.table_catalog = ccu.table_catalog
   and cr.table_schema  = ccu.table_schema
   and cr.table_name    = ccu.table_name
   and cr.column_name   = ccu.column_name
 where kcu.table_schema not in ('pg_catalog','information_schema');


--drop view dba.all_foreign_keys;
create or replace view dba.all_foreign_keys as
select user_name,
       schema_name,
       table_name,
       string_agg (column_name, ',' order by position) as column_name_list,
       constraint_name,
       ref_schema_name,
       ref_table_name,
       string_agg (ref_column_name, ',' order by position) as ref_column_name_list,
       ref_constraint_name
  from dba.all_foreign_key_columns
 group by user_name, schema_name, table_name, constraint_name, ref_schema_name, ref_table_name, ref_constraint_name;


--drop view dba.all_constraints;
create or replace view dba.all_constraints as
select u.usename  as user_name,
       n.nspname  as schema_name,
       c.relname  as table_name,
       r.conname  as constraint_name,
       contype    as constraint_type,
       pg_catalog.pg_get_constraintdef(r.oid, true) as constraint_text
  from pg_catalog.pg_constraint r
  join pg_catalog.pg_class c     on c.oid      = r.conrelid
  join pg_catalog.pg_namespace n on n.oid      = c.relnamespace
  join pg_catalog.pg_user u      on u.usesysid = n.nspowner
 where n.nspname != 'information_schema'
   and n.nspname not like 'pg_%';


--drop view dba.all_schemas:
create or replace view dba.all_schemas as
select pg_catalog.pg_get_userbyid(n.nspowner) as user_name,
       n.nspname                              as schema_name,
       pg_catalog.obj_description(n.oid, 'pg_namespace') as schema_comment
  from pg_catalog.pg_namespace n
 where n.nspname !~ '^pg_'
   and n.nspname <> 'information_schema';


--drop view dba.all_sequences;
create or replace view dba.all_sequences as
select pg_catalog.pg_get_userbyid(c.relowner) as user_name,
       n.nspname           as schema_name,
       c.relname           as sequence_name,
       s.seqtypid::regtype      as sequence_type,
       s.seqstart          as start_value,
       s.seqmin            as min_value,
       s.seqmax            as max_value,
       s.seqincrement      as increment_by,
       s.seqcycle          as cycle_sequence,
       d.description sequence_comment
  from pg_catalog.pg_class c
  join pg_catalog.pg_sequence s on s.seqrelid  = c.oid
  join pg_catalog.pg_type t on t.oid = s.seqtypid
  left join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  left join pg_catalog.pg_description d  on d.objoid = c.oid
                                        and d.objsubid = 0
where c.relkind = 'S'
   and n.nspname <> 'pg_catalog'
   and n.nspname !~ '^pg_toast'
   and n.nspname <> 'information_schema';


--drop view dba.all_indexes;
create or replace view dba.all_indexes as
select pg_catalog.pg_get_userbyid(c.relowner) as user_name,
       n.nspname as schema_name,
       c2.relname as table_name,
       c.relname as index_name,
       case c.relkind
            when 'i' then 'index'
            when 'I' then 'partitioned index'
       end as index_type,
       ts.spcname index_tablespace
  from pg_catalog.pg_class c
  left join pg_catalog.pg_namespace n    on n.oid = c.relnamespace
  left join pg_catalog.pg_am am          on am.oid = c.relam
  left join pg_catalog.pg_index i        on i.indexrelid = c.oid
  left join pg_catalog.pg_class c2       on i.indrelid = c2.oid
  left join pg_catalog.pg_tablespace ts  on ts.oid = c.reltablespace
 where c.relkind in ('i','I','')
   and n.nspname <> 'pg_catalog'
   and n.nspname !~ '^pg_toast'
   and n.nspname <> 'information_schema'
;


-- drop view dba.all_triggers;
create or replace view dba.all_triggers as
select t.trigger_catalog        as trigger_user,
       t.trigger_schema         as trigger_schema,
       t.trigger_name           as trigger_name,
       t.event_manipulation     as event_action,
       t.event_object_catalog   as event_user,
       t.event_object_schema    as event_schema,
       t.event_object_table     as event_table,
       t.action_order           as event_order,
       t.action_statement       as action_statement,
       t.action_orientation     as action_level,
       t.action_timing          as action_timing,
       dba.trigger_function_name (t.action_statement, 'schema')   as function_schema,
       dba.trigger_function_name (t.action_statement, 'table')    as function_name,
       string_agg (tc.event_object_column, ',')   as event_column_list
  from information_schema.triggers as t
  join (select tuc.trigger_catalog, tuc.trigger_schema, tuc.trigger_name, tuc.event_object_column, c.ordinal_position 
          from information_schema.triggered_update_columns tuc 
          join information_schema.columns c 
            on c.table_catalog  = tuc.event_object_catalog 
           and c.table_schema   = tuc.event_object_schema 
           and c.column_name    = tuc.event_object_column 
         order by c.ordinal_position) as tc
    on tc.trigger_catalog = t.trigger_catalog
   and tc.trigger_schema  = t.trigger_schema
   and tc.trigger_name    = t.trigger_name
 group by trigger_user, t.trigger_schema, t.trigger_name, event_action,
          event_user, event_schema, event_table,
          event_order, action_statement, action_level, action_timing,
          function_schema, function_name
;

-- drop view dba.all_functions;
create or replace view dba.all_functions as 
select
       pg_catalog.pg_get_userbyid(p.proowner) as user_name,
       n.nspname as schema_name,
       p.proname as function_name,
       pg_catalog.pg_get_function_result(p.oid) as result_type,
       pg_catalog.pg_get_function_arguments(p.oid) as argument_types,
       case p.prokind
            when 'a' then 'agg'
            when 'w' then 'window'
            when 'p' then 'proc'
            else 'func'
       end as function_type,
       case
            when p.provolatile = 'i' then 'immutable'
            when p.provolatile = 's' then 'stable'
            when p.provolatile = 'v' then 'volatile'
       end as volatility,
       l.lanname as language,
       pg_catalog.obj_description(p.oid, 'pg_proc') as description
  from pg_catalog.pg_proc p
  left join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  left join pg_catalog.pg_language l on l.oid = p.prolang
 where n.nspname <> 'pg_catalog'
   and n.nspname <> 'information_schema'
;


-- drop view dba.all_function_definitions;
create or replace view dba.all_function_definitions as 
select pg_catalog.pg_get_userbyid(p.proowner) as user_name,
       n.nspname as schema_name,
       p.proname as function_name,
       pg_catalog.pg_get_functiondef(p.oid) as function_definition
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n ON n.oid = p.pronamespace
 where n.nspname <> 'pg_catalog'
   and n.nspname <> 'information_schema'
;
