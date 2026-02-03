#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter    as tk
import sys
import os.path    as op

sys.path.append(op.dirname(op.realpath(__file__)))
import windows    as win
import config     as cnf



class Report(win.Windows):
    def __init__(self, parent, title, schema_name):
        win.Windows.__init__(self, parent, "Report", title, self.get_size(300,200,400,100))

   
        config = cnf.Config.get_instance()
        bgcolor = config.get("report.bg.color")

        top = tk.Frame(self, background=bgcolor)
        top.place(relx=0.0,rely=0.0,relheight=0.5, relwidth=1.0)

        label = tk.Label(top, text="Bitte einen Report wählen")
        label.pack(padx=10, pady=10)

        bottom = tk.Frame(self, background=bgcolor)
        bottom.place(relx=0.0,rely=0.5,relheight=0.5, relwidth=1.0)

        self.e_button = tk.Button(bottom, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        
    
