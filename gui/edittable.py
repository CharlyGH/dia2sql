#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter      as tk
import sys
import os.path      as op
import tkinter.font as tf

sys.path.append(op.dirname(op.realpath(__file__)))
import database     as db
import windows      as win
import control      as con
import datamask     as dm
import projekt      as pr
import config       as cnf


class EditTable(win.Windows):
    def __init__(self, parent, title, schema_name, table_name):
        win.Windows.__init__(self, parent, "EditTable", title, self.get_size(800,600,700,80))

        config = cnf.Config.get_instance()
        bgcolor = config.get("edit.bg.color")
        
        data = db.Database()

        projekt = pr.Projekt.get_instance()
        schema_comment = projekt.get_schema_info(schema_name, "comment")
        table_comment  = projekt.get_table_info(schema_name, table_name,"comment")


        lis_len = projekt.get_column_count(schema_name, table_name)
        
        if lis_len == 0:
            self.state = "Keine Spalten in " + table_name + " in " + schema_name + " gefunden"
            return

        offset = 4
        height = 1.0/(offset + lis_len)
        self.geometry(self.get_size(800,50*(lis_len + offset),700,80))
        self.columns = projekt.get_column_list(schema_name, table_name)

          
        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0.0,relheight=1*height, relwidth=1.0)

        label_font = tf.Font(self, size=10, weight="bold")
        label = tk.Label(head, text="Bitte " + table_comment + " in " + schema_comment + " bearbeiten", background=bgcolor)
        label.config(font=label_font)
        label.pack(padx=10, pady=10)


        mask = dm.DataMask(self, data, schema_name, table_name, background=bgcolor)
        mask.place(relx=0.0,rely=1*height,relheight=lis_len*height, relwidth=1.0)
        

        contr = con.Control(self, schema_name, table_name, data, background=bgcolor)
        contr.place(relx=0.0,rely=(lis_len +  offset - 3)*height,relheight=2*height, relwidth=1.0)

        mask.control  = contr
        contr.datamask = mask
        self.control  = contr
        self.datamask  = mask

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=(lis_len + offset - 1)*height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        

    def disable_all_buttons(self):
        self.e_button.config(state=tk.DISABLED)
        self.control.disable_all_buttons()
        self.datamask.disable_all_buttons()
        
        
    def enable_all_buttons(self):
        self.e_button.config(state=tk.NORMAL)
        self.control.enable_all_buttons()
        self.datamask.enable_all_buttons()
