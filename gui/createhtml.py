#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb  8 11:51:35 2026

@author: Charly
"""

import subprocess        as sp
import os.path           as op
import project           as pj
import database          as db
import createfile        as cf
import config            as cnf

class CreateHTML(cf.CreateFile):
    
    instance    = None
    project     = None
    root_dir    = op.dirname(op.dirname(op.realpath(__file__)))

    def __init__(self):
        raise RuntimeError('Call get_instance() instead')

    @classmethod
    def get_instance(cls, filename):
        if cls.instance is None:
            cls.instance = cls.__new__(cls)
            cls.project = pj.Project.get_instance(filename)
        return cls.instance




    def write_document_header(self, title):
        self.datafile.write("<html>" + "\n")
        self.datafile.write("  <head>" + "\n")
        self.datafile.write("    <title>" + title + "</title>" + "\n")
        self.datafile.write("    <style>" + "\n")
        self.datafile.write("      table {" + "\n")
        self.datafile.write("        border: 2px solid black;" + "\n")
        self.datafile.write("        border-collapse: collapse;" + "\n")
        self.datafile.write("      }" + "\n")
        self.datafile.write("      th, td {" + "\n")
        self.datafile.write("        border: 1px solid black;" + "\n")
        self.datafile.write("      }" + "\n")
        self.datafile.write("    </style>" + "\n")
        self.datafile.write("  </head>" + "\n")
        self.datafile.write("  <body>" + "\n")


    def write_document_footer(self):
        self.datafile.write("  </body>" + "\n")
        self.datafile.write("</html>" + "\n")


    def write_section_header(self, title, table):
        self.datafile.write("    <h1>" + title + "</h1>" + "\n")
        self.datafile.write("    <h2>" + table + "</h2>" + "\n")


    def write_section_footer(self, fmt_desc):
        if fmt_desc != None:
            self.datafile.write("    <br/>&nbsp;" + "\n")
            for idx in range(len(fmt_desc)):
                le, text, ri = self.get_desc_format(fmt_desc[idx])               
                self.datafile.write(le + text + ri + "\n")


    def write_table_header(self, hdr_list):
        #print("CreateHTML.write_table_header", fmt_list, hdr_list)
        self.datafile.write("    <table>" + "\n")
        self.datafile.write("      <tr>" + "\n")
        for hdr in hdr_list:
            self.datafile.write("        <th>" + hdr + "</th>" + "\n")
        self.datafile.write("      </tr>" + "\n")


            
    def write_table_row(self, row, fmt_list):
        self.datafile.write("      <tr>" + "\n")

        prefix = "<td>"
        suffix = "</td>"
        color = super().get_dict_value(row, "color")
        if color != None:
            prefix = prefix + "<span style='color:" + color + "'>"
            suffix = "</span>" + suffix

        for name in row:
            if name != "color":
                value  = row[name]
                self.datafile.write("        " + prefix + str(value) + suffix + "\n")

        self.datafile.write("      </tr>" + "\n")


    def write_table_footer(self):
        self.datafile.write("    </table>" + "\n")
        

        
    def write_table(self, res_list, fmt_list, hdr_list):
        #print("CreatePDF.write_table", res_list[0])
        self.write_table_header(hdr_list)
        for res in res_list:
            self.write_table_row(res, fmt_list)
        self.write_table_footer()
        

    def write_table_content_as_html(self, schema, table, filename):
        print("CreateHTML.write_table_content_as_html: ", schema, table, filename)
        proj_disp_name  = self.get_project_name()
        table_disp_name = self.project.get_table_info(schema, table, "comment")
        sql, fmt_list, hdr_list   = self.get_report_query_sql(schema, table)
        #print(sql,fmt_list,hdr_list)
        if sql == None or fmt_list == None or hdr_list == None:
            return False
        cols = len(fmt_list)
        
        data = db.Database()
        data.execute_db_query(sql, None)
        res_list = data.get_query_result_dict_list()
        rows = len(res_list)
        #print("CreatePDF.write_table_content_as_lout: ",res_list)
        with open(filename, "w") as self.datafile:
            self.write_document_header(proj_disp_name)
            self.write_section_header(proj_disp_name, table_disp_name)
            self.write_table(res_list, fmt_list, hdr_list)
            self.write_section_footer(None)
            self.write_document_footer()
            self.datafile.close()
        return True, rows, cols


    def get_desc_format(self, desc):
        desc_tab = desc.split("#")
        color = desc_tab[0]
        text  = desc_tab[1]
        le = "    <br/>" + "\n" + "    <span style='color:" + color + "'>"
        ri = "</span>"
        return le, text, ri
    

    

    def write_table_structure_as_html(self, schema, table, filename):
        print("CreateHTML.write_table_structure_as_html: ", schema, table, filename)
        proj_disp_name  = self.get_project_name()
        table_disp_name = schema + "." + table
        sql, fmt_list, hdr_list   = self.get_docu_query_sql(schema, table)
        #print(sql,fmt_list,hdr_list)
        if sql == None or fmt_list == None or hdr_list == None:
            return False
        cols = len(fmt_list)
        
        data = db.Database()
        data.execute_db_query(sql, None)
        res_list = data.get_query_result_dict_list()
        rows = len(res_list)
        #print("CreatePDF.write_table_content_as_lout: ",res_list)
        conf = cnf.Config.get_instance()
        fmt_desc = conf.get("fmt.desc")
        
        with open(filename, "w") as self.datafile:
            self.write_document_header(proj_disp_name)
            self.write_section_header(proj_disp_name, table_disp_name)
            self.write_table(res_list, fmt_list, hdr_list)
            self.write_section_footer(fmt_desc)
            self.write_document_footer()
            self.datafile.close()
        return True, rows, cols
        
    
    

    def display_html_file(self, filename):
        #show_cmd = "/usr/bin/firefox " + filename
        #print(show_cmd)
        #os.system(show_cmd)
        sp.Popen(["/usr/bin/firefox", filename])

    
    def process_data (self, schema, table):
        htmlfilename = super().create_absolut_file_name("temp","html")
        #print("CreatePDF.process_data")
        status, rows, cols = self.write_table_content_as_html(schema,table,htmlfilename)
        if not status:
            return None
        return htmlfilename, rows, cols
    

    def process_docu (self, schema, table):
        htmlfilename = super().create_absolut_file_name("temp","html")
        #print("CreatePDF.process_data")
        status, rows, cols = self.write_table_structure_as_html(schema,table,htmlfilename)
        if not status:
            return None
        return htmlfilename, rows, cols
    

if __name__ == "__main__":
    html = CreateHTML.get_instance("out/verein_v01.json")
#    sql, col_fmt, col_hdr = pdf.get_report_query_sql("dim_verein","funktion")
#    sql, col_fmt, col_hdr = pdf.get_report_query_sql("dim_verein","adresse")
#    print("sql=\n" + sql)
    html.process_data("dim_verein","funktion")
     
     