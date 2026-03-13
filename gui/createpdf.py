#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb  8 11:51:35 2026

@author: Charly
"""

import os
import subprocess       as sp
import os.path          as op
import project          as pj
import database         as db
import createfile       as cf
import config           as cnf


class CreatePDF(cf.CreateFile):
    
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



    def write_document_header(self, title, size):
        guidoc = "guidoc." + size
        self.datafile.write("@SysInclude { tbl }" + "\n")
        self.datafile.write("@Include { " + guidoc + " }" + "\n")
        self.datafile.write("@Doc @Text @Begin" + "\n")
        self.datafile.write("@Display { 24p @Font{ " + title + " }}" + "\n")
        self.datafile.write("@BeginSections" + "\n")


    def write_document_footer(self):
        self.datafile.write("@EndSections" + "\n")
        self.datafile.write("@End @Text" + "\n")


    def write_section_header(self, table):
        self.datafile.write("@Section" + "\n")
        self.datafile.write("@Title {" + table + "}" + "\n")
        self.datafile.write("@NewPage {No}" + "\n")
        self.datafile.write("@Begin" + "\n")
        self.datafile.write("@LP" + "\n")


    def write_section_footer(self, fmt_desc):
        if fmt_desc != None:
            for idx in range(len(fmt_desc)):
                le, text, ri = self.get_desc_format(fmt_desc[idx])               
                self.datafile.write(le + text + ri + "\n")
        self.datafile.write("@End @Section" + "\n")


    def write_table_header(self, fmt_list, hdr_list, cut, lout_tab_color):
        print("CreatePDF.write_table_header", fmt_list, hdr_list)
        self.datafile.write("@Tbl" + "\n")
        self.datafile.write("rule { yes }" + "\n")
        self.datafile.write("    hformat { | ")
        start_idx = ord('A') - 1
        idx = start_idx
        for fmt in fmt_list:
            idx = idx + 1
            col = chr(idx)
            fmt_strg = " @B "
            self.datafile.write(fmt_strg + "@Cell " + col + "  |")
            if cut and col == 'Z':
                break;
        self.datafile.write(" }" + "\n")
        

        self.datafile.write("    gformat { | ")
        idx = start_idx
        for fmt in fmt_list:
            idx = idx + 1
            col = chr(idx)
            if fmt == "B":
                fmt_strg = " @B "
            else:
                fmt_strg = "    "
            self.datafile.write(fmt_strg + "@Cell " + col + "  |")
            if cut and col == 'Z':
                break;
        self.datafile.write(" }" + "\n")

        if lout_tab_color != None:
            start_kidx = ord('a')
            stop_kidx = ord('f')
            for kidx in range(start_kidx, stop_kidx):
                fmt_chr = chr(kidx)
                color = super().get_dict_value(lout_tab_color, fmt_chr,"black")
                if color == "green":
                    color = "darkgreen"
                if fmt_chr == 'g':
                    break;
                self.datafile.write("    " + fmt_chr + "format { | ")
                idx = start_idx
                for fmt in fmt_list:
                    idx = idx + 1
                    col = chr(idx)
                    self.datafile.write(color + " @Color { @Cell " + col + " }  | ")
                    if cut and col == 'Z':
                        break;
                self.datafile.write(" }" + "\n")
        
        
        self.datafile.write("{" + "\n")
        self.datafile.write("@Rowh" + "\n")
        idx = start_idx
        for hdr in hdr_list:
            idx = idx + 1
            col = chr(idx)
            if cut and col == 'Z':
                self.datafile.write("    " + col + " { usw. }" + "\n")
                break;
            else:
                self.datafile.write("    " + col + " {" + hdr + "}" + "\n")

        self.datafile.write("@HeaderRowh" + "\n")
        idx = start_idx
        for hdr in hdr_list:
            idx = idx + 1
            col = chr(idx)
            if cut and col == 'Z':
                self.datafile.write("    " + col + " { usw. }" + "\n")
                break;
            else:
                self.datafile.write("    " + col + " {" + hdr + "}" + "\n")

            
    def write_table_row(self, row, cut, lout_tab_color):
        
        if lout_tab_color != None:
            color = super().get_dict_value(row, "color")
            if color != None:
                fmt_chr = super().get_dict_value(lout_tab_color, color, 'g')
        else:
            fmt_chr = 'g'
            

        self.datafile.write("@Row" + fmt_chr + "\n")
        start_idx = ord('A') - 1
        idx = start_idx
        for col in row:
            fld = row[col]
            idx = idx + 1
            col_name = chr(idx)
            if cut and col == 'Z':
                self.datafile.write("    " + col_name + " { ... }" + "\n")
                break;
            else:
                self.datafile.write("    " + col_name + " {" + str(fld) + "}" + "\n")


    def write_table_footer(self):
        self.datafile.write("}" + "\n")
        self.datafile.write("@LP" + "\n")
        

        
    def write_table(self, res_list, fmt_list, hdr_list, lout_tab_color):
        print("CreatePDF.write_table:\n", 
              "row_fmt=",lout_tab_color,"\n")
        cut = (len(fmt_list) > 26)
        self.write_table_header(fmt_list, hdr_list, cut, lout_tab_color)
        for res in res_list:
            self.write_table_row(res, cut, lout_tab_color)
        self.write_table_footer()
        
        
    def get_page_size(self, cols):
        if cols < 8:
            size = "a4"
        elif cols < 16:
            size = "a3"
        else:
            size = "a2"
        return size
    

    def write_table_content_as_lout(self, schema, table, filename):
        print("CreatePDF.write_table_content_as_lout: ", schema, table, filename)
        proj_disp_name  = self.get_project_name()
        table_disp_name = self.project.get_table_info(schema, table, "comment")
        sql, fmt_list, hdr_list   = self.get_report_query_sql(schema, table)
        #print(sql,fmt_list,hdr_list)
        if sql == None or fmt_list == None or hdr_list == None:
            return False, 0, 0
        cols = len(fmt_list)
            
        data = db.Database()
        data.execute_db_query(sql, None)
        res_list = data.get_query_result_dict_list()
        rows = len(res_list)
        #print("CreatePDF.write_table_content_as_lout: ",res_list)

        size = self.get_page_size(cols)

        with open(filename, "w") as self.datafile:
            self.write_document_header(proj_disp_name,size)
            self.write_section_header(table_disp_name)
            self.write_table(res_list, fmt_list, hdr_list, None)
            self.write_section_footer(None)
            self.write_document_footer()
            self.datafile.close()
        return True, rows, cols
        
    
    def write_table_structure_as_lout(self, schema, table, filename):
        print("CreatePDF.write_table_structure_as_lout: ", schema, table, filename)
        proj_disp_name  = self.get_project_name()
        table_disp_name = self.project.get_table_info(schema, table, "comment")
        sql, fmt_list, hdr_list   = self.get_docu_query_sql(schema, table)
        #print(sql,fmt_list,hdr_list)
        if sql == None or fmt_list == None or hdr_list == None:
            return False, 0, 0
        cols = len(fmt_list)
            
        data = db.Database()
        data.execute_db_query(sql, None)
        res_list = data.get_query_result_dict_list()
        rows = len(res_list)
        #print("CreatePDF.write_table_content_as_lout: ",res_list)

        size = self.get_page_size(cols)

        conf = cnf.Config.get_instance()
        fmt_desc = conf.get("fmt.desc")
        lout_tab_color = self.complete_lout_tab_color(conf)
        print(lout_tab_color)

        with open(filename, "w") as self.datafile:
            self.write_document_header(proj_disp_name,size)
            self.write_section_header(table_disp_name)
            self.write_table(res_list, fmt_list, hdr_list, lout_tab_color)
            self.write_section_footer(fmt_desc)
            self.write_document_footer()
            self.datafile.close()
        return True, rows, cols
    
    
    def complete_lout_tab_color(self, conf):
        input_tab = conf.get("lout.tab.color")
        output_tab = dict()
        for key in input_tab.keys():
            clr = input_tab[key]
            output_tab[key] = clr
            output_tab[clr] = key
        return output_tab
    
    
    def get_desc_format(self, desc):
        desc_tab = desc.split("#")
        color = desc_tab[0]
        text  = desc_tab[1]
        if color == "green":
            color = "darkgreen"
        le = "@LLP" + "\n" + color + " @Color {"
        ri = "}"
        return le, text, ri



    def get_lout_format_XX(self, name, value, row_format):
        key = name + "#" + value
        if not key in row_format.keys():
            return "", ""
        else:
            fmt_strg = row_format[key]
            fmt_tab  = fmt_strg.split("#")
            kind = fmt_tab[0]
            fmt = fmt_tab[1]
            le = ""
            ri = ""
            if kind == "style":
                if fmt == "bold":
                    le = "<b>"
                    ri = "</b>"
                elif fmt == "italic":
                    le = "<i>"
                    ri = "</i>"
            elif kind == "color":
                le = "<span style='" + kind + ":" + fmt + "'>"
                ri = "</span>"
                
#            print("CreateHTML.get_html_format name=" , name, ",  value=", value,
#                  ",  kind=", kind, ",  fmt=",fmt,
#                  ",  le=", le, ",   ri=", ri)
            return le, ri
    
    
    def convert_utf_to_iso(self, utffilename, isofilename):
        iconv_cmd = "/usr/bin/iconv -f UTF-8 -t ISO8859-15 -o " + isofilename + " " + utffilename
        #print(iconv_cmd)
        os.system(iconv_cmd)
    
    
    def create_pdf_file(self, loutfile, pdffile, errorfile):
        crossref = self.create_absolut_file_name("temp")
        incldir  = self.root_dir + "/dtd"
        lout_cmd = "/usr/local/lout/bin/lout -r1 -c " + crossref + " -I " + incldir 
        lout_cmd = lout_cmd  + " -PDF -o " + pdffile + " -e " +  errorfile + " " + loutfile
        print(lout_cmd)
        os.system(lout_cmd)
    

    def rotate_pdf_file(self, rawfilename, pdffilename):
        pdftk_cmd = "/usr/bin/pdftk " + rawfilename + " cat 1-endeast output " + pdffilename
        print(pdftk_cmd)
        os.system(pdftk_cmd)
        

    def display_pdf_file(self, filename):
        #show_cmd = "/usr/bin/evince " + filename
        #print(show_cmd)
        #os.system(show_cmd)
        sp.Popen(["/usr/bin/evince", filename])

    
    def process_data(self, schema, table):
        utffilename = super().create_absolut_file_name("temp","utf.lout")
        isofilename = super().create_absolut_file_name("temp","lout")
        rawfilename = super().create_absolut_file_name("temp","raw.pdf")
        pdffilename = super().create_absolut_file_name("temp","pdf")
        errfilename = super().create_absolut_file_name("temp","err")
        #print("CreatePDF.process_data")
        status, rows, cols = self.write_table_content_as_lout(schema,table,utffilename)
        if not status:
            return None
        self.convert_utf_to_iso(utffilename,isofilename)
        self.create_pdf_file(isofilename,rawfilename,errfilename)
        self.rotate_pdf_file(rawfilename,pdffilename)
        return pdffilename, rows, cols

    
    def process_docu(self, schema, table):
        utffilename = super().create_absolut_file_name("temp","utf.lout")
        isofilename = super().create_absolut_file_name("temp","lout")
        rawfilename = super().create_absolut_file_name("temp","raw.pdf")
        pdffilename = super().create_absolut_file_name("temp","pdf")
        errfilename = super().create_absolut_file_name("temp","err")
        #print("CreatePDF.process_data")
        status, rows, cols = self.write_table_structure_as_lout(schema,table,utffilename)
        if not status:
            return None
        self.convert_utf_to_iso(utffilename,isofilename)
        self.create_pdf_file(isofilename,rawfilename,errfilename)
        self.rotate_pdf_file(rawfilename,pdffilename)
        return pdffilename, rows, cols
    

if __name__ == "__main__":
    pdf = CreatePDF.get_instance("out/verein_v01.json")
    sql, col_fmt, col_hdr = pdf.get_report_query_sql("dim_verein","funktion")
    #sql, col_fmt, col_hdr = pdf.get_report_query_sql("dim_verein","adresse")
    print("sql=\n" + sql)
