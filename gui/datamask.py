#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 21:38:04 2025

@author: Charly
"""

import tkinter            as tk
import tkinter.font       as tf
#import tkinter.messagebox as mb

import functools          as  ft

import sys
import os.path            as op

sys.path.append(op.dirname(op.realpath(__file__)))
import window_methods     as wm
import project            as pr
import selectbox          as sb
import config             as cnf


class DataMask(tk.Frame):
    def __init__(self, win, data, schema_name, table_name, **kwargs):
        tk.Frame.__init__(self, win, **kwargs)
        
        config = cnf.Config.get_instance()
        bgcolor = config.get("data.bg.color")

        project = pr.Project.get_instance()

        #print ("datamask.init: schema_name=" , schema_name, ",  table_name=", table_name)
        self.column_list   = project.get_column_list(schema_name, table_name)
        self.value_list    = list()
        self.lis_len       = project.get_column_count(schema_name, table_name)
        self.data          = data
        self.schema_name   = schema_name
        self.table_name    = table_name
        self.win           = win
        self.descr_list    = list()
        height = 1.0/self.lis_len

        self.clear_value_list = list()
        self.s_button_list = list()
        label_list = list()
        self.ref_comment_list = list()
        self.ref_schema_list = list()
        self.ref_table_list = list()
        
        for idx in range(self.lis_len):
            field       = self.column_list[idx]["name"]
            #print("datamask.init: field=", field)
            var_type    = self.column_list[idx]["type"]
            #print("datamask.init: var_type=", var_type)
            col_size    = config.get(var_type + ".width")
            descr_size  = config.get("text.width")
            lbl_txt     = self.column_list[idx]["comment"]
            ispk        = self.column_list[idx]["ispk"]
            isfk        = self.column_list[idx]["isfk"]
            auto        = self.column_list[idx]["auto"]
            if lbl_txt == "":
                lbl_txt = wm.format_label(field)
            
            if isfk:
                refschema   = self.column_list[idx]["refschema"]
                reftable    = self.column_list[idx]["reftable"]
                refcomment  = self.column_list[idx]["refcomment"]
            else:
                refschema   = None
                reftable    = None
                refcomment  = None
            self.ref_schema_list.append(refschema)
            self.ref_table_list.append(reftable)
            self.ref_comment_list.append(refcomment)


            if ispk:
                label_font = tf.Font(self,size=10, weight="bold")
            else:
                label_font = tf.Font(self,size=10, weight="normal")
            if refcomment != None:
                lbl_txt = refcomment

            body = tk.Frame(self, background=bgcolor)
            body.place(relx=0.0,rely=height*idx,relheight=height, relwidth=1.0)
        
            label = tk.Label(body, text=lbl_txt, background=bgcolor)
            label.config(font=label_font)
            label.pack(side="left", padx=10, pady=5)
            label_list.append(label)
        
            if refcomment != None:
                if ispk:
                    entry_bgcolor = config.get("entry.ref.pk.bg.color")
                else:
                    entry_bgcolor = config.get("entry.ref.bg.color")
            else:
                if ispk:
                    entry_bgcolor = config.get("entry.pk.bg.color")
                else:
                    entry_bgcolor = config.get("entry.bg.color")
        
            descr_var = tk.StringVar(body)
            
            check_list = project.get_column_check(schema_name, table_name, field)
            if check_list == None:
                value_var = tk.StringVar(body)
                self.clear_value_list.append("")
                v_entry = tk.Entry(body, 
                                   width=col_size, 
                                   textvariable=value_var,
                                   background=entry_bgcolor)
            else:
                # (win, selected_label, label_list, value_list, dflt_idx)
                dflt_idx = 0
                self.clear_value_list.append(check_list[dflt_idx])
                v_entry = sb.SelectBox(body,
                                       check_list,
                                       check_list,
                                       dflt_idx,
                                       background=entry_bgcolor)
                value_var = v_entry.get_selected_label()

            v_entry.pack(side="right", padx=10, pady=5)

            if isfk or ispk or auto: 
                v_entry.configure (state = "readonly")

            if isfk:
                s_button = tk.Button(body, text="Suchen", 
                                   command=ft.partial(self.execute_mask_query, idx, ispk, table_name, refschema, reftable, field))
                s_button.pack(side="right", padx=10, pady=10)
                self.s_button_list.append(s_button)

            if isfk: 
                d_entry = tk.Entry(body, 
                                   width=descr_size, 
                                   textvariable=descr_var,
                                   background=entry_bgcolor)
                d_entry.pack(side="right", padx=10, pady=5)
                d_entry.configure (state = "readonly")

            self.value_list.append(value_var)
            self.descr_list.append(descr_var)


    def disable_all_buttons(self):
        for s_button in self.s_button_list:
            s_button.config(state=tk.DISABLED)
        
    
    def enable_all_buttons(self):
        for s_button in self.s_button_list:
            s_button.config(state=tk.NORMAL)
        


    def execute_mask_query(self, idx, ispk, table, refschema, reftable, reffield):
        print ("DataMask: execute_mask_query idx=", idx, "  ispk=", ispk, 
               "  refschema=", refschema, "  reftable=", reftable, "  reffield=", reffield)
        self.data.execute_mask_query(idx, ispk, self, refschema, reftable, reffield)
        
    
    
    def clear_data(self):
        lis_len = len(self.value_list)

        for idx in range(lis_len):
            self.value_list[idx].set(self.clear_value_list[idx])
            self.descr_list[idx].set("")

    