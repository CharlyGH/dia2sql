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



class Error(win.Windows):
    def __init__(self, parent, title, e_param):
        bgcolor = "#ffdfdf"
        height = 1.0/2.0
        win.Windows.__init__(self, parent, "Error", title, self.get_size(400,200,400,200))
    
        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0*height,relheight=height, relwidth=1.0)

        t_label = tk.Label(head, 
                           text="Ein Fehler ist aufgetreten",
                           background=bgcolor)
        t_label.pack(padx=10, pady=10)


        m_label = tk.Label(head, 
                           text=e_param,
                           background=bgcolor)
        m_label.pack(padx=10, pady=10)

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=1*height,relheight=height, relwidth=1.0)

        e_button = tk.Button(foot, text="Ende", command=self.close)
        e_button.pack(side="right", padx=10, pady=10)
        
        self.set_exit_button(e_button)

