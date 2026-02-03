#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter       as tk
import tkinter.font  as tf
import sys
import os.path       as op

sys.path.append(op.dirname(op.realpath(__file__)))
import windows           as win
import window_methods    as wm
import projekt           as pr
import selectbox         as sb
import config            as cnf


class Main(win.Windows):
    def __init__(self, parent, title):
        config = cnf.Config.get_instance()
        bgcolor = config.get("main.bg.color")

        height = 1.0/4.0
        win.Windows.__init__(self, parent, "Main", title, self.get_size(600,300,100,0))


        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0*height,relheight=height, relwidth=1.0)

        label_font = tf.Font(self, size=10, weight="bold")
        label = tk.Label(head, 
                         text="Bitte ein Schema und eine Funktion wählen", 
                         background=bgcolor)
        label.config(font=label_font)
        label.pack(padx=10, pady=10)

        neck = tk.Frame(self, background=bgcolor)
        neck.place(relx=0.0,rely=1*height,relheight=height, relwidth=1.0)


        projekt = pr.Projekt.get_instance()
        label_list = projekt.get_schema_info_list("comment")
        value_list = projekt.get_schema_info_list("name")
        self.selected_label = tk.StringVar(neck)

        select = sb.SelectBox(neck, self.selected_label, label_list, value_list, 0)
        select.pack(padx=10, pady=10)

        body = tk.Frame(self, background=bgcolor)
        body.place(relx=0.0,rely=2*height,relheight=height, relwidth=1.0)

        self.c_button = tk.Button(body, 
                                  text="Erfassung", 
                                  command=lambda: wm.get_window(self,
                                                           "SelectTable",
                                                           select.get_selected_value()))
        self.c_button.pack(side="left", padx=10, pady=10)
        
        self.m_button = tk.Button(body, 
                                  text="Report", 
                                  command=lambda: wm.get_window(self,
                                                           "Report",
                                                           select.get_selected_value()))
        self.m_button.pack(side="left", padx=10, pady=10)
        

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=3*height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        

    def disable_all_buttons(self):
        self.c_button.config(state=tk.DISABLED)
        self.m_button.config(state=tk.DISABLED)
        self.e_button.config(state=tk.DISABLED)
        
        
    def enable_all_buttons(self):
        self.c_button.config(state=tk.NORMAL)
        self.m_button.config(state=tk.NORMAL)
        self.e_button.config(state=tk.NORMAL)


        
        
        