#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import tkinter as tk
import tkinter.messagebox as mb
import sys
import os.path as op

sys.path.append(op.dirname(op.realpath(__file__)))

class Windows(tk.Tk):
    window_dict = dict()
    def __init__(self, parent, name, title, size):
        tk.Tk.__init__(self)
        self.geometry(size)
        self.wm_title(title)
        self.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.name = name
        self.state = "OK"
        self.parent = parent

    def is_valid(self):
        return self.state == "OK"
    

    def on_closing(self):
        if self.check_exit_button_disabled():
            mb.showinfo("Fehler", "Schließen des Fensters zur Zeit nicht möglich",master=self)
            return
        if True or mb.askokcancel("Ende", "Wirklich beenden?"):
            Windows.window_dict.update({self.name: None})
            if (self.parent != None):
                self.parent.enable_all_buttons()
            self.state = "EXIT"
            self.destroy()


    def close(self):
        Windows.window_dict.update({self.name: None})
        if (self.parent != None):
            self.parent.enable_all_buttons()
        self.state = "EXIT"
        self.destroy()

        


    def split_param(self, param):
        schema   = param.split(":")[0]
        comment  = param.split(":")[1]
        return schema, comment

    def get_size(self,w,h,x,y):
        return str(w) + "x" + str(h) + "+" + str(x) + "+" + str(y)


    
    def check_exit_button_disabled(self):
        return self.e_button["state"] == "disabled"
