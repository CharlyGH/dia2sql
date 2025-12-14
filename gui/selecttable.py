#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter      as tk
import tkinter.font as tf
import sys
import os.path      as op

sys.path.append(op.dirname(op.realpath(__file__)))
import windows           as win
import window_methods    as wm
import projekt           as pr
import selectbox         as sb


class SelectTable(win.Windows):
    
    def __init__(self, parent, title, schema_name, table_name):
        bgcolor = "#dfffff"
        height = 1.0/4.0

        win.Windows.__init__(self, parent, "SelectTable", title, self.get_size(600,300,400,40))
    
        projekt = pr.Projekt.get_instance()
        comment = projekt.get_schema_info(schema_name, "comment")
          
        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0*height,relheight=height, relwidth=1.0)

        label_font = tf.Font(self, size=10, weight="bold")
        label = tk.Label(head, text="Bitte eine Tabelle aus " + comment +" wählen", background=bgcolor)
        label.config(font=label_font)
        label.pack(padx=10, pady=10)

        main = tk.Frame(self, background=bgcolor)
        main.place(relx=0.0,rely=1*height,relheight=2*height, relwidth=1.0)

        
        label_list = projekt.get_table_info_list(schema_name, "comment")
        value_list = projekt.get_table_info_list(schema_name, "name")
        
        self.selected_label = tk.StringVar(main)

        select = sb.SelectBox(main, self.selected_label, label_list, value_list, 0)
        select.pack(padx=10, pady=10)
        

        self.b_button = tk.Button(main, 
                                  text="Bearbeiten", 
                                  command=lambda: wm.get_window(self,
                                                                "EditTable",
                                                                schema_name,
                                                                select.get_selected_value()))
        self.b_button.pack(side="right", padx=10, pady=10)

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=3*height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)


        
    def disable_all_buttons(self):
        self.b_button.config(state=tk.DISABLED)
        self.e_button.config(state=tk.DISABLED)
        
        
    def enable_all_buttons(self):
        self.b_button.config(state=tk.NORMAL)
        self.e_button.config(state=tk.NORMAL)


