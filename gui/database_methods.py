#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Aug 10 18:44:22 2025

@author: gmd
"""

import config as cfg
import projekt            as pr
import tkinter.messagebox as mb
import window_methods     as wm


    
conf = cfg.Config()
debug = conf.get("debug")


def format(txt, typ):
    quote = "'"
    cast  = "::"
    if typ == "integer":
        ret = txt
    elif typ == "bigint":
        ret = txt
    elif typ == "double precision":
        ret = txt
    elif typ == "character":
        ret = quote + txt + quote
    elif typ == "text":
        ret = quote + txt + quote
    elif typ == "date":
        ret = quote + txt + quote + cast + typ
    else:
        raise TypeError("Unbekannter Datentyp [" + typ + "]")     
    return ret


def get_field_comment(column_list, idx):
    leng = len(column_list)
    if idx >= leng:
        raise ValueError("Index " + str(idx) + " ist größer als Länge der Liste " + str(leng))
    col = column_list[idx]
    result = col["comment"]
    if result == None or result == "":
        result = col["name"]
    return result



def get_primary_key_count(column_list):
    pk_cnt = 0
    for col in column_list:
        if col["ispk"]:
            pk_cnt = pk_cnt + 1
    return pk_cnt


def is_primary_key(column_list, idx):
    leng = len(column_list)
    if idx >= leng:
        raise ValueError("Index " + str(idx) + " ist größer als Länge der Liste " + str(leng))
    col = column_list[idx]
    return col["ispk"]


def is_auto(column_list, idx):
    leng = len(column_list)
    if idx >= leng:
        raise ValueError("Index " + str(idx) + " ist größer als Länge der Liste " + str(leng))
    col = column_list[idx]
    return col["auto"]


def is_nullable(column_list, idx):
    leng = len(column_list)
    if idx >= leng:
        raise ValueError("Index " + str(idx) + " ist größer als Länge der Liste " + str(leng))
    col = column_list[idx]
    return col["nullable"]


def is_dimension(column_list):
    pk_cnt = get_primary_key_count(column_list)
    return pk_cnt == 1


def get_sql_insert(table_name,column_list,value_list):
    is_dim = is_dimension(column_list)
    lis_len = len(column_list)
    name_strg = ""
    value_strg = ""
    requ_delim = ""
    res_strg = ""
    res_delim = ""
    for idx in range(lis_len):
        is_pk = column_list[idx]["ispk"]
        auto = column_list[idx]["auto"]
        name = column_list[idx]["name"]
        typ = column_list[idx]["type"]
        txt = value_list[idx].get()
        res_strg = res_strg + res_delim + name
        res_delim = ", "
        if (is_pk and is_dim) or auto:
            continue
        name_strg = name_strg + requ_delim + name
        value_strg = value_strg + requ_delim + format(txt,typ)
        requ_delim = ", "
    statement = "insert into " + table_name + " ("
    statement = statement + name_strg + ") values (" + value_strg 
    statement = statement + ") returning " + res_strg
    return statement


def get_sql_update(table_name,column_list,value_list):
    lis_len = len(column_list)
    set_strg = ""
    where_strg = ""
    res_strg = ""
    set_delim = ""
    where_delim = ""
    res_delim = ""
    for idx in range(lis_len):
        auto = column_list[idx]["auto"]
        is_pk = column_list[idx]["ispk"]
        name = column_list[idx]["name"]
        typ = column_list[idx]["type"]
        print ("idx=", idx, ",  name=", name,",  auto=",auto)
        txt = value_list[idx].get()
        if auto:
            new_strg = name + " = current_date"
        else:
            new_strg = name + " = " + format(txt,typ)
        res_strg = res_strg + res_delim + name
        res_delim = ", "
        if is_pk:
            where_strg = where_strg + where_delim + new_strg
            where_delim = " and "
        else:
            set_strg = set_strg + set_delim + new_strg
            set_delim = ", "
    statement = "update " + table_name + " set "
    statement = statement + set_strg + " where " + where_strg
    statement = statement + " returning " + res_strg
    return statement


def get_sql_delete(table_name,column_list,value_list):
    lis_len = len(column_list)
    where_strg = ""
    res_strg = ""
    where_delim = ""
    res_delim = ""
    for idx in range(lis_len):
        is_pk = column_list[idx]["ispk"]
        name = column_list[idx]["name"]
        typ = column_list[idx]["type"]
        txt = value_list[idx].get()
        new_strg = name + " = " + format(txt,typ)
        res_strg = res_strg + res_delim + name
        res_delim = ", "
        if is_pk:
            where_strg = where_strg + where_delim + new_strg
            where_delim = " and "
        else:
            pass
    statement = "delete from " + table_name 
    statement = statement + " where " + where_strg
    statement = statement + " returning " + res_strg
    return statement



def get_sql_search(table_name,column_list,value_list):
    lis_len = len(column_list)
    name_strg = ""
    where_strg = ""
    order_strg = ""
    name_delimiter = ""
    where_delimiter = ""
    order_delimiter = ""
    for idx in range(lis_len):
        name = column_list[idx]["name"]
        typ  = column_list[idx]["type"]
        isuk = column_list[idx]["isuk"]
        auto = column_list[idx]["auto"]
        ispk = column_list[idx]["ispk"]
        txt = value_list[idx].get()
        if "'" in txt:
            txt = txt.replace("'","")
        if "%" in txt:
            op = " like "
        else:
            op = " = "
        new_strg = name + op + format(txt,typ)
        name_strg = name_strg + name_delimiter + name
        if isuk:
            order_strg = order_strg + order_delimiter + name
            order_delimiter = ", "
        name_delimiter = ", "
        if txt != "" and not auto and not ispk:
            where_strg = where_strg + where_delimiter + new_strg
            where_delimiter = " and "
    statement = "select " + name_strg + " from " + table_name
    if where_strg != "":
        statement = statement + " where " + where_strg
    if order_strg != "":
        statement = statement + " order by " + order_strg
        
    return statement







def get_sql_controll_command(action, schema_table_name, column_list, value_list):

    if debug != "off":
        print ("get sql command for action " + action)
        
    if action == "insert":
        statement = get_sql_insert(schema_table_name,
                                   column_list,
                                   value_list)
    elif action == "update":
        statement = get_sql_update(schema_table_name,
                                    column_list,
                                    value_list)
    elif action == "delete":
        statement = get_sql_delete(schema_table_name,
                                   column_list,
                                   value_list)
    elif action == "search":
        statement = get_sql_search(schema_table_name,
                                   column_list,
                                   value_list)
    elif action == "clear":
        statement = None
    else:
        raise ValueError("Unbekannte Aktion [" + action + "]")
    return statement


def get_sql_mask_command(idx, data, mask, refschema, reftable, reffield):
    print ("idx=" + str(idx) + ",  table=" + mask.table_name + ",  reffield=" + reffield)

    projekt = pr.Projekt.get_instance()
    if reftable == None:
        ref_column_list = mask.column_list
        table_name = mask.table_name
    else:
        ref_column_list = projekt.get_column_list(refschema, reftable)
        table_name = reftable

    field_strg = ""
    delim = ""
    for col in ref_column_list:
        field = col['name']
        field_strg = field_strg + delim + field
        delim = ", "

    sql = "select " + field_strg + " from " + refschema + "." + table_name
    return sql


def set_sql_controll_result(action, contr, result_list):
    if len(result_list) == 0:
        return
    
    result = result_list[0]
    
    if action == "insert":
        lis_len = len(contr.datamask.value_list)
        for idx in range(lis_len):
            contr.datamask.value_list[idx].set(result[idx])
    elif action == "update":
        lis_len = len(contr.datamask.value_list)
        for idx in range(lis_len):
            contr.datamask.value_list[idx].set(result[idx])
    elif action == "delete":
        ##TODO value_list leeren?
        pass
    elif action == "search":
        set_mask_query_result(result_list, contr.datamask, None, True)
    elif action == "clear":
        contr.datamask.clear_data()
    else:
        raise ValueError("Unbekannte Aktion [" + action + "]")
        


def set_mask_query_result(result_list, mask, idx, ispk):
    rows = len(result_list)
    
    if rows == 0: 
        mb.showwarning("Hinweis","Keine Daten gefunden",master=mask.win)
    else:
        mask.result_window = wm.get_window(mask.win,"ResultTable",result_list,idx,ispk,mask)



def check_input(action, column_list, value_list):
    result = "OK"
    leng = len(column_list)
    if action == "insert":
        for idx in range(leng):
            val = value_list[idx].get()
            name = get_field_comment(column_list, idx)
            ispk = is_primary_key(column_list, idx)
            auto = is_auto(column_list, idx)
            isnable = is_nullable(column_list, idx)
            if ispk and val != None and val != "":
                result = "Primärschlüssel muss beim Einfügen leer sein"
                break
            if not ispk and not isnable and not auto and (val == None or val == ""):
                result = "Feld [" + name + "] darf beim Einfügen nicht leer sein"
                break
    elif action == "update":
        for idx in range(leng):
            val = value_list[idx].get()
            name = get_field_comment(column_list, idx)
            ispk = is_primary_key(column_list, idx)
            isnable = is_nullable(column_list, idx)
            if ispk and (val == None or val == ""):
                result = "Primärschlüssel darf beim Ändern nicht leer sein"
                break
            if not ispk and not isnable and (val == None or val == ""):
                result = "Feld [" + name + "] darf beim Ändern nicht leer sein"
                break
    elif action == "delete":
       for idx in range(leng):
           val = value_list[idx].get()
           ispk = is_primary_key(column_list, idx)
           if ispk and (val == None or val == ""):
               result = "Primärschlüssel darf beim Löschen nicht leer sein"
               break
    else:
        raise ValueError("Unbekannte Aktion [" + action + "]")
    print ("check_input: idx=" + str(idx) + " val=[" + str(val) + "],  result=" + result)
    return result


def get_pk_info_sql(schema, table, pk_name, uk_name, value):
    sql = "select " + uk_name + " from " + schema + "." + table 
    sql = sql + " where " + pk_name + " = " + str(value)
    return sql
