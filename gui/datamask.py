#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 21:38:04 2025

@author: gmd
"""

import tkinter            as tk
import tkinter.font       as tf
#import tkinter.messagebox as mb

import functools          as  ft

import sys
import os.path            as op

sys.path.append(op.dirname(op.realpath(__file__)))
import config             as cf
import window_methods     as wm
import projekt            as pr
import selectbox          as sb


class DataMask(tk.Frame):
    def __init__(self, win, data, schema_name, table_name, **kwargs):
        tk.Frame.__init__(self, win, **kwargs)
        self.conf = cf.Config()
        
        bgcolor = "#dfdfff"
        projekt = pr.Projekt.get_instance()

        #print ("datamask.init: schema_name=" , schema_name, ",  table_name=", table_name)
        self.column_list   = projekt.get_column_list(schema_name, table_name)
        self.value_list    = list()
        self.lis_len       = projekt.get_column_count(schema_name, table_name)
        self.data          = data
        self.schema_name   = schema_name
        self.table_name    = table_name
        self.win           = win
        self.descr_list    = list()
        height = 1.0/self.lis_len

        self.clear_value_list = list()
        self.s_button_list = list()
        label_list = list()
        for idx in range(self.lis_len):
            field       = self.column_list[idx]["name"]
            #print("datamask.init: field=", field)
            var_type    = self.column_list[idx]["type"]
            #print("datamask.init: var_type=", var_type)
            col_size    = self.conf.get(var_type + ".width")
            descr_size  = self.conf.get("text.width")
            lbl_txt     = self.column_list[idx]["comment"]
            ispk        = self.column_list[idx]["ispk"]
            isfk        = self.column_list[idx]["isfk"]
            auto        = self.column_list[idx]["auto"]
            if lbl_txt == "":
                lbl_txt = wm.format_label(field)
            
            if isfk:
                refcomment  = self.column_list[idx]["refcomment"]
                reftable    = self.column_list[idx]["reftable"]
                refschema   = self.column_list[idx]["refschema"]
            else:
                refcomment  = None
                reftable    = None
                refschema   = None
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
                entry_bgcolor = "#dfffff"
                if ispk:
                    entry_bgcolor = "#bfdfff"
                else:
                    entry_bgcolor = "#dfffdf"
            else:
                if ispk:
                    entry_bgcolor = "#ffdfdf"
                else:
                    entry_bgcolor = "#ffffdf"
        
            self.value_list.append(tk.StringVar(body))
            self.descr_list.append(tk.StringVar(body))
            
            check_list = projekt.get_column_check(schema_name, table_name, field)
            if check_list == None:
                self.clear_value_list.append("")
                v_entry = tk.Entry(body, 
                                   width=col_size, 
                                   textvariable=self.value_list[idx],
                                   background=entry_bgcolor)
            else:
                # (win, selected_label, label_list, value_list, dflt_idx)
                dflt_idx = 0
                self.clear_value_list.append(check_list[dflt_idx])
                v_entry = sb.SelectBox(body,
                                       self.value_list[idx],
                                       check_list,
                                       check_list,
                                       dflt_idx,
                                       background=entry_bgcolor)


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
                                   textvariable=self.descr_list[idx],
                                   background=entry_bgcolor)
                d_entry.pack(side="right", padx=10, pady=5)
                d_entry.configure (state = "readonly")


    def disable_all_buttons(self):
        for s_button in self.s_button_list:
            s_button.config(state=tk.DISABLED)
        
    
    def enable_all_buttons(self):
        for s_button in self.s_button_list:
            s_button.config(state=tk.NORMAL)
        


    def execute_mask_query(self, idx, ispk, table, refschema, reftable, reffield):
        #print ("datamask: execute_mask_query idx=", idx, "  ispk=", ispk, 
        #       "  refschema=", refschema, "  reftable=", reftable, "  reffield=", reffield)
        self.data.execute_mask_query(idx, ispk, self, refschema, reftable, reffield)
        
    
    
    def clear_data(self):
        lis_len = len(self.value_list)

        for idx in range(lis_len):
            self.value_list[idx].set(self.clear_value_list[idx])
            self.descr_list[idx].set("")

    