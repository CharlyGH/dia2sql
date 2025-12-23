#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 30 20:50:15 2025

@author: gmd
"""

import psycopg2    as pg
import sys
import os.path     as op

sys.path.append(op.dirname(op.realpath(__file__)))
import config            as cnf
import database_methods  as dm


class Database():
    def __init__(self):
        conf = cnf.Config()
        self.run_mode  = conf.get("run.mode")
        self.debug     = conf.get("debug")
        self.conn_strg = conf.get("conn_strg")
        self.status    = "init"



    def execute_db_query (self, sql, arglist):
        if self.debug == "read" or self.debug == "all" or self.debug == "verbose":
            print("sql=[" + sql + "]")
            print("arglist=[" + str(arglist) + "]")
        with pg.connect(self.conn_strg) as conn:
#            print ("datestyle=",conn.execute("show datestyle").fetchone()[0])
            with conn.cursor() as curs:
                curs.execute(sql)
                if arglist != None:
                    curs.execute(arglist)
                self.meta          = curs.description
                self.col_count     = len(self.meta)
                self.row_count     = curs.rowcount
                self.result_tuples = curs.fetchall()
                self.status = "read:" + str(self.row_count) + ":" + str(self.col_count)
        conn.close()
        if self.debug == "read" or self.debug == "all" or self.debug == "verbose":
            print("rows=[" + str(self.row_count) + "],  cols=[" + str(self.col_count) + "]")
        if self.debug == "verbose":
            for row in self.result_tuples:
                print (row)


    def execute_db_command (self, sql, arglist):
        if self.debug == "write" or self.debug == "all":
            print("sql=[" + sql + "]")
            print("arglist=[" + str(arglist) + "]")
        with pg.connect(self.conn_strg) as conn:
            with conn.cursor() as curs:
                curs.execute(sql)
                if arglist != None:
                    curs.execute(arglist)
                self.meta          = curs.description
                self.col_count     = len(self.meta)
                self.row_count     = curs.rowcount
                self.result_tuples = curs.fetchall()
                self.status = "write:" + str(self.row_count)
        conn.commit()
        conn.close()
        if self.debug == "write" or self.debug == "all":
            print("rows=[" + str(self.row_count) + "],  cols=[" + str(self.col_count) + "]")


    def get_query_result_dict_list(self):
        result = list()
        for line in self.result_tuples:
            row = dict()
            for col_idx in range(self.col_count):
                name  = self.meta[col_idx].name
                value = line[col_idx]
                row.update({name:  value})
            result.append(row)
        return result


    def get_query_result_pair_list(self):
        result = list()
        cols = self.col_count
        if cols != 2:
            print("Warning: result set has " + str(cols) + " columns")
        if cols < 2:
            raise ValueError("Error: result set has " + str(cols) + " columns")
            self.data              = data
        for line in self.result_tuples:
            row = str(line[0]) + ": " + str(line[1])
            result.append(row)
        return result


    def execute_controll_command(self, action, contr):
        chk = dm.check_input(action, contr.column_list, contr.datamask.value_list)
        if chk == "OK":
            sql, arglist = dm.get_sql_controll_command(action, contr.schema_name, contr.table_name, 
                                                       contr.column_list, contr.datamask.value_list)
            if self.run_mode == "dry":
                if self.debug == "write" or self.debug == "all":
                    print(sql)
                self.status = action + ":" + self.run_mode
                self.result_tuples = list()
                self.result_tuples.append(0)
                dm.set_sql_controll_result(action, contr, self.result_tuples)
            else:
                self.execute_db_command(sql, arglist)
                self.status = action + ":" + self.status 
                dm.set_sql_controll_result(action, contr, self.result_tuples)
        else:
            self.status = action + ":" + chk
    

    def execute_controll_query(self, action, contr):
        sql, arglist = dm.get_sql_controll_command(action, contr.schema_name, contr.table_name, 
                                                   contr.column_list, contr.datamask.value_list)
        self.execute_db_query(sql, arglist)
        self.status = action + ":" + self.status 
        dm.set_sql_controll_result(action, contr, self.result_tuples)


    def execute_controll_other(self, action, contr):
        self.result_tuples = list()
        self.result_tuples.append(0)
        dm.set_sql_controll_result(action, contr, self.result_tuples)


    def execute_mask_query(self, idx, ispk, mask, refschema, reftable, reffield):
        sql = dm.get_sql_mask_command(idx, self, mask, refschema, reftable, reffield)
        self.execute_db_query(sql, None)
        self.status = "read:" + self.status 
        mask.controll.message.set(self.status)
        dm.set_mask_query_result(self.result_tuples, mask, idx, ispk)


    def get_status(self):
        return self.status


    def get_query_result_string(self, sql):
        self.execute_db_query(sql)
        return self.result_tuples[0][0]
       

if __name__ == "__main__":
    data = Database()


# =============================================================================
#     data.execute_query(dm.get_sql_schema_list())
#     print (data.get_query_result_pair_list())
#     
#     data.execute_query(dm.get_sql_table_list("firma"))
#     print (data.get_query_result_pair_list())
#     
#     data.execute_query(dm.get_sql_column_list("firma","kunde"))
#     print (data.get_query_result_dict_list())
#     
# =============================================================================
    
    sql = "insert into test (name, descr) values ('fünf','fünfter')"
    data.execute_command(sql)
    print ("nach insert " + str(data.row_count))
    
    sql = "delete from test where id > 3"
    data.execute_command(sql)
    print ("nach insert " + str(data.row_count))
    
    