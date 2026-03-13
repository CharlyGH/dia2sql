#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: Charly
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter          as tk
import tkinter.font     as tf
import sys
import os.path          as op

sys.path.append(op.dirname(op.realpath(__file__)))
import window           as win
import config           as cnf
import window_methods   as wm
import project          as pr
import selectbox        as sb
import radiobutton      as rb



class Docu(win.Window):
    def __init__(self, parent, title, schema_name):
        win.Window.__init__(self, parent, "Doku", title,self.get_size(600,300,400,40))

   
        config = cnf.Config.get_instance()
        bgcolor = config.get("report.bg.color")

        height = 1.0/5.0

        project = pr.Project.get_instance()
        comment = project.get_schema_info(schema_name, "comment")
  
        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0.0*height,relheight=height, relwidth=1.0)

        label_font = tf.Font(self, size=10, weight="bold")
        label = tk.Label(head, 
                         text="Bitte eine Tabelle aus " + comment + " wählen",
                         background=bgcolor)
        label.config(font=label_font)
        label.pack(padx=10, pady=10)


        neck = tk.Frame(self, background=bgcolor)
        neck.place(relx=0.0,rely=1.0*height,relheight=height, relwidth=1.0)

        label_list = project.get_table_info_list(schema_name, "comment")
        value_list = project.get_table_info_list(schema_name, "name")
        

        self.select_box = sb.SelectBox(neck, label_list, value_list, 0)
        self.selected_label = self.select_box.get_selected_label()
        self.select_box.pack(padx=10, pady=10)



        main = tk.Frame(self, background=bgcolor)
        main.place(relx=0.0,rely=2*height,relheight=2.0*height, relwidth=1.0)

        width = 1.0/3.0
        
        left = tk.Frame(self, background=bgcolor)
        left.place(relx=0.0,rely=2.0*height,relheight=2.0*height, relwidth=width)

        

        
        disp_title = "Bitte die Darstellungsart wählen"
        disp_label_list = ["intern","extern"]
        self.disp_radio_button = rb.RadioButton(left, disp_title, disp_label_list, bgcolor)
        self.disp_radio_button.pack(side="left")


        mid = tk.Frame(self, background=bgcolor)
        mid.place(relx=width,rely=2.0*height,relheight=2.0*height, relwidth=width)


        fmt_title = "Bitte die Dateityp wählen"
        fmt_label_list = ["html","pdf"]
        self.fmt_radio_button = rb.RadioButton(mid, fmt_title, fmt_label_list, bgcolor)
        self.fmt_radio_button.pack(side="left")





        right = tk.Frame(self, background=bgcolor)
        right.place(relx=2.0*width,rely=2.0*height,relheight=2.0*height, relwidth=width)
        



        self.d_button = tk.Button(right, 
                                  text="Anzeigen", 
                                  command=lambda: wm.get_window(self,
                                                                "ShowDocu",
                                                                schema_name,
                                                                self.select_box.get_selected_value(),
                                                                self.disp_radio_button.get_selected_value(),
                                                                self.fmt_radio_button.get_selected_value()))
        self.d_button.pack(side="right", padx=10, pady=10)




        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=4.0*height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)


        
    
    def disable_all_buttons(self):
        self.d_button.config(state=tk.DISABLED)
        self.e_button.config(state=tk.DISABLED)
        self.disp_radio_button.config(state=tk.DISABLED)
        self.fmt_radio_button.config(state=tk.DISABLED)
        self.select_box.config(state=tk.DISABLED)
        
        
    def enable_all_buttons(self):
        self.d_button.config(state=tk.NORMAL)
        self.e_button.config(state=tk.NORMAL)
        self.disp_radio_button.config(state=tk.NORMAL)
        self.fmt_radio_button.config(state=tk.NORMAL)
        self.select_box.config(state=tk.NORMAL)


