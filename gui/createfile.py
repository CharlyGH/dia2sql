#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Mar  7 21:41:35 2026

@author: Charly
"""

import database_methods as dm

class CreateFile():
    
    def get_report_query_sql(self, schema, table):
        print("CreateFile.get_report_query_sql: ", schema, table)
        return  dm.get_report_query_sql(schema, table, self.project)


    def get_docu_query_sql(self, schema, table):
        print("CreateFile.get_docu_query_sql: ", schema, table)
        return  dm.get_docu_query_sql(schema, table, self.project)


    def create_absolut_file_name(self,dirname,ext=""):
        proj, vers = self.project.get_model_info()
        filename = self.root_dir + "/" + dirname + "/" + proj + "_v" + str(vers).zfill(2)
        if ext != "":
            return filename + "." + ext
        else:
            return filename
        

    def get_project_name(self):
        proj, vers = self.project.get_model_info()
        return proj.title() + " (Version " + str(vers) + ")"
        


    def get_dict_value(self, dic, key, dflt=None):
        if key in dic:
            return dic[key]
        else:
            return dflt
