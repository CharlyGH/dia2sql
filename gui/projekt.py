#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 15:14:38 2025

@author: gmd
"""

import sys
import json

import os.path       as op


class Projekt(object):
    instance = None
    data     = None
    root_dir = op.dirname(op.dirname(op.realpath(__file__)))

    def __init__(self):
        raise RuntimeError('Call get_instance() instead')

    @classmethod
    def get_instance(cls, filename=None):
        if cls.instance is None:
            cls.gtab = "   "
            cls.nl   = "\n"
            cls.instance = cls.__new__(cls)
            with open(cls.root_dir + "/" + filename) as stream:
                cls.data = json.load(stream)            
            # Put any initialization here.
        return cls.instance

    


    def get(self, key):
        if self.data == None:
            raise BufferError("databuffer not loaded")
        else:
            return self.data[key]


    def get_config_value(self,config):
        return self.data["config"][config]


    def get_schema_list(self):
        return self.data["schemas"]


    def get_table_list(self,schema_name):
        return self.data[schema_name]["tables"]
    

    def get_schema_info_list(self, kind, empty=False):
        name_list = self.data["schemas"]
        if kind == "name" or kind == "comment":
            res = list()
            for schema in name_list:
                if not schema in self.data.keys():
                    continue
                value = self.data[schema][kind]
                count = self.data[schema]["table-count"]
                if empty or count > 0:
                    res.append(value)
            return res
        else:
            return None


    def get_schema_info(self, schema_name, kind):
        if kind == "name":
            return schema_name
        elif kind == "comment":
            comment = self.data[schema_name][kind]
            return comment
        else:
            return None


    def get_table_info_list(self, schema_name, kind):
        table_list = self.data[schema_name]["tables"]
        if kind == "name":
            return table_list
        else:
            lis = list()
            for table_name in table_list:
                info = self.data[schema_name][table_name][kind]
                lis.append(info)
        return lis


    def get_table_info(self, schema_name, table_name, kind):
        return self.data[schema_name][table_name][kind]

   
    
    def get_column_list(self, schema_name, table_name):
        column_names = self.data[schema_name][table_name]["columns"]
        lis = list()
        for column_name in column_names:
            column = self.data[schema_name][table_name][column_name]
            lis.append(column)
        return  lis


    def get_column_count(self, schema_name, table_name):
        return self.data[schema_name][table_name]["column-count"]


    def get_column_info(self, schema_name, table_name, column_ref, kind):
        if type(column_ref) == type("abc"):
            column_name = column_ref
        elif type(column_ref) == type(1):
            column_name = self.data[schema_name][table_name]["columns"][column_ref]
        else:
            raise ValueError("Not a valid column reference [" + str(column_ref) + "]")
        column = self.data[schema_name][table_name][column_name]
        if kind in column:
            return column[kind]
        return None
    

    def get_reftable_info(self, ref_schema_name, ref_table_name, group, field):
        print ("schema: get_reftable_info: reftable=", ref_table_name,"  group=",group,"  field=",field)
        return self.data[ref_schema_name][ref_table_name][group][0][field]

        
    def get_column_check(self, schema_name, table_name, column_name):
        column = self.data[schema_name][table_name][column_name]
        if "check" in column:
            return column["check"]
        else:
            return None


    def to_xml(self):
        ret = "<?xml version='1.0'?>" + self.nl
        ret = ret + "<!DOCTYPE json SYSTEM 'json.dtd'>" + self.nl
        ret = ret + "<json>" + self.nl
        ret = ret +  self.to_xml_recu(self.data, self.gtab)
        ret = ret + "</json>" + self.nl
        return ret


    def is_scalar_type(self, arg):
        return ((type(arg) == type("")) or 
                (type(arg) == type(True)) or 
                (type(arg) == type(1)) or 
                (type(arg) == type(3.14)))


    def get_type_name(self, arg):
        if (type(arg) == type("")):
            return "string"
        elif (type(arg) == type(1)): 
            return "integer"
        elif (type(arg) == type(True)): 
            return "boolean"
        elif (type(arg) == type(3.14)):
            return "float"
        elif (type(arg) == type(list())):
            return "list"
        elif (type(arg) == type(dict())):
            return "dict"
        else:
            return "unknown"

    def to_xml_recu(self, arg, tab):
        if (type(arg) == type(dict())):
            ntab1 = tab + self.gtab
            ntab2 = ntab1 + self.gtab
            ret = tab + "<dict>" + self.nl
            for key in arg.keys():
                child = arg[key]
                is_scalar = self.is_scalar_type(child)
                type_name = self.get_type_name(child)
                if is_scalar:
                    ret = ret + ntab1 + "<dict-item name='" + key + "' type='" + type_name + "'>"
                    ret = ret + str(child)
                    ret = ret + "</dict-item>" + self.nl
                else:
                    ret = ret + ntab1 + "<dict-element name='" + key + "' type='" + type_name + "'>" + self.nl
                    ret = ret + self.to_xml_recu(child, ntab2)
                    ret = ret + ntab1 + "</dict-element>" + self.nl
            ret = ret + tab + "</dict>" + self.nl;
            return ret;
        elif (type(arg) == type(list())):
            ntab1 = tab + self.gtab
            ntab2 = ntab1 + self.gtab
            ret = tab + "<list>" + self.nl
            for idx in range(len(arg)):
                child = arg[idx]
                is_scalar = self.is_scalar_type(child)
                type_name = self.get_type_name(child)
                if is_scalar:
                    ret = ret + ntab1 + "<list-item index='" + str(idx) + "' type='" + type_name + "'>"
                    ret = ret + str(child)
                    ret = ret + "</list-item>" + self.nl
                else:
                    ret = ret + ntab1 + "<list-element index='" + str(idx) + "' type='" + type_name + "'>" + self.nl
                    ret = ret + self.to_xml_recu(arg[idx], ntab2)
                    ret = ret + ntab1 + "</list-element>" + self.nl
            ret = ret + tab + "</list>" + self.nl;
            return ret;
        else:
            return tab + str(type(arg)) + self.nl


if __name__ == "__main__":
    if len(sys.argv) < 2:
        filename = "data/test.json"        
    else:
        filename = sys.argv[1]

    projekt = Projekt.get_instance(filename)
    print(projekt.to_xml())
#    print ("schema_list=", projekt.get_schema_list())
#    print ("table_list=", projekt.get_table_list("dim_firma"))
#    print ("names=", projekt.get_schema_info_list("name"))
#    print ("comments=", projekt.get_schema_info_list("comment"))
    
    
    