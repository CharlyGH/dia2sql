#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter as tk
import sys
import os.path as op

sys.path.append(op.dirname(op.realpath(__file__)))
import windows as win



class Report(win.Windows):
    def __init__(self, parent, title):
        win.Windows.__init__(self, parent, "Report", title, self.get_size(300,200,400,100))
    
        top = tk.Frame(self, background="#ffffbf")
        top.place(relx=0.0,rely=0.0,relheight=0.5, relwidth=1.0)

        label = tk.Label(top, text="Bitte einen Report wählen")
        label.pack(padx=10, pady=10)

        bottom = tk.Frame(self, background="#bfffff")
        bottom.place(relx=0.0,rely=0.5,relheight=0.5, relwidth=1.0)

        button = tk.Button(bottom, text="Ende", command=self.on_closing)
        button.pack(side="right", padx=10, pady=10)
        
    
