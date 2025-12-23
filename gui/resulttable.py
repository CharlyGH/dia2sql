#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug 16 09:19:27 2025

@author: gmd
"""

import functools          as  ft

import tkinter            as tk
import sys
import os.path            as op
import tkinter.font       as tf

sys.path.append(op.dirname(op.realpath(__file__)))
import windows            as win
import projekt            as pr
import database_methods   as dm
import window_methods     as wm


class ResultTable(win.Windows):
    def __init__(self, parent, title, result_list, target_idx, ispk, mask):
        win.Windows.__init__(self, parent, "ResultTable", title, self.get_size(600,600,700,80))
        bgcolor = "#dfdfff"

        rows   = len(result_list)
        offset = 5
        height = 1.0/(rows + offset)
        self.cols   = len(result_list[0])
        #print("cols=" + str(self.cols))
        columns = parent.columns

        self.geometry(self.get_size(180*self.cols+50,35*(rows + offset),300,120))
        self.ispk        = ispk
        self.schema_name = mask.schema_name
        self.table_name  = mask.table_name
        self.target_idx  = target_idx
        self.parent      = parent
        self.projekt     = pr.Projekt.get_instance()
        self.data        = mask.data

        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0*height,relheight=2*height, relwidth=1.0)

        table_comment = self.projekt.get_table_info(self.schema_name,
                                                    self.table_name,
                                                    "comment")

        label_font = tf.Font(self, size=10, weight="bold")
        label = tk.Label(head, 
                         text="Inhalt der Tabelle " + table_comment, 
                         background=bgcolor)
        label.config(font=label_font)
        label.pack(padx=10, pady=10)


        body = tk.Frame(self, background=bgcolor)
        body.place(relx=0.0,rely=2*height,relheight=(rows+1)*height, relwidth=1.0)

        label = tk.Label(body, 
                         text="Select", 
                         background=bgcolor)
        label.config(font=label_font)
        label.grid(row=0, column=0)

        for col in range(self.cols):
            label = tk.Label(body, 
                             text=wm.format_label(columns[col]["name"]), 
                             background=bgcolor)
            label.config(font=label_font)
            label.grid(row=0, column=col+1)

        self.value_table = list()
        for row in range(rows):
            value_list = list()
            line = result_list[row]
            s_button = tk.Button(body,
                                 width=20,
                                 text="Auswahl", 
                                 command=ft.partial(self.select_line, row ))
            s_button.grid(row=row+1,column=0)
            for col in range(self.cols):
                value = tk.StringVar(body)
                entry = tk.Entry(body, 
                                 width=20, 
                                 textvariable=value,
                                 background=bgcolor)
                entry.grid(row=row+1, column=col+1)
                value.set(line[col])
                entry.configure (state = "readonly")
                value_list.append(value)
            self.value_table.append(value_list)
            

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=(rows+3)*height,relheight=2*height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        


    def select_line (self, idx):
        #print ("line " + str(idx) + " was selected, ispk=" + str(self.ispk))
        value_list = self.value_table[idx]
        if self.ispk:
            for col in range(self.cols):
                #print ("root-table=" + self.table_name + ",  col=" + str(col) )
                reftable = self.projekt.get_column_info(self.schema_name,
                                                        self.table_name,
                                                        col,"refname")
                value = value_list[col].get()
                if reftable != None:
                    pk_name = self.projekt.get_reftable_info(self.schema_name,reftable,"primary","key")
                    uk_name = self.projekt.get_reftable_info(self.schema_name,reftable,"unique","key")
                    sql = dm.get_pk_info_sql(self.schema_name, reftable, pk_name, uk_name, value)
                    descr = self.data.get_query_result_string(sql)
                    print("pk_name=" + pk_name + ",  uk_name=" + uk_name + 
                          ",  value=" + str(value) + ",  deescr=" + descr)
                    self.parent.datamask.descr_list[col].set(descr)
                self.parent.datamask.value_list[col].set(value)
        else:
            value = value_list[0].get()
            descr = value_list[1].get()
            for idx in range(2, len(value_list)):
                descr = descr + "|" + value_list[idx].get()
            self.parent.datamask.value_list[self.target_idx].set(value)
            self.parent.datamask.descr_list[self.target_idx].set(descr)
        self.on_closing()