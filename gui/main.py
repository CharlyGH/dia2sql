#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: Charly
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter       as tk
import tkinter.font  as tf
import sys
import os.path       as op

sys.path.append(op.dirname(op.realpath(__file__)))
import mainwindow        as win
import window_methods    as wm
import project           as pr
import selectbox         as sb
import config            as cnf


class Main(win.MainWindow):
    def __init__(self, parent, title):
        config = cnf.Config.get_instance()
        bgcolor = config.get("main.bg.color")

        height = 1.0/4.0
        win.MainWindow.__init__(self, parent, "Main", title, self.get_size(600,300,100,0))


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


        project = pr.Project.get_instance()
        label_list = project.get_schema_info_list("comment")
        value_list = project.get_schema_info_list("name")

        self.select = sb.SelectBox(neck, label_list, value_list, 0)
        self.selected_label = self.select.get_selected_label()
        self.select.pack(padx=10, pady=10)

        body = tk.Frame(self, background=bgcolor)
        body.place(relx=0.0,rely=2*height,relheight=height, relwidth=1.0)

        self.i_button = tk.Button(body, 
                                  text="Erfassung", 
                                  command=lambda: wm.get_window(self,
                                                           "SelectTable",
                                                           self.select.get_selected_value()))
        self.i_button.pack(side="left", padx=10, pady=10)
        
        self.r_button = tk.Button(body, 
                                  text="Report", 
                                  command=lambda: wm.get_window(self,
                                                           "Report",
                                                           self.select.get_selected_value()))
        self.r_button.pack(side="left", padx=10, pady=10)
        
        self.d_button = tk.Button(body, 
                                  text="Doku", 
                                  command=lambda: wm.get_window(self,
                                                           "Docu",
                                                           self.select.get_selected_value()))
        self.d_button.pack(side="left", padx=10, pady=10)
        

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=3*height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        

    def disable_all_buttons(self):
        self.i_button.config(state=tk.DISABLED)
        self.r_button.config(state=tk.DISABLED)
        self.d_button.config(state=tk.DISABLED)
        self.e_button.config(state=tk.DISABLED)
        self.select.config(state=tk.DISABLED)
        
        
    def enable_all_buttons(self):
        self.i_button.config(state=tk.NORMAL)
        self.r_button.config(state=tk.NORMAL)
        self.d_button.config(state=tk.NORMAL)
        self.e_button.config(state=tk.NORMAL)
        self.select.config(state=tk.NORMAL)


        
        
        