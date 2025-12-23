#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: gmd
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/

import sys
import os.path as op


sys.path.append(op.dirname(op.realpath(__file__)))
import windows     as win
import main        as mn
import selecttable as stb
import edittable   as etb
import report      as rep
import error       as err
import resulttable as rt


def get_window(parent, name, 
               param_1=None, param_2=None, param_3=None, param_4=None):
    title = name + "Window"
    window = win.Windows.window_dict.get(name)
    state = "Unbekannter Fehler"
    if window != None:
        state = window.state
        if state == "OK":
            return window

    if name == "Main":
        window = mn.Main(parent, title)
        if window.is_valid():
            win.Windows.window_dict.update({name: window})
        else:
            state = window.state
            window.destroy()
    elif name == "SelectTable":
        window = stb.SelectTable(parent, title, param_1, param_2)
        if window.is_valid():
            win.Windows.window_dict.update({name: window})
            parent.disable_all_buttons()
        else:
            state = window.state
            window.destroy()
    elif name == "EditTable":
        window = etb.EditTable(parent, title, param_1, param_2)
        if window.is_valid():
            win.Windows.window_dict.update({name: window})
            parent.disable_all_buttons()
        else:
            state = window.state
            window.destroy()
    elif name == "ResultTable":
        window = rt.ResultTable(parent, title, 
                                param_1, param_2, param_3, param_4)
        if window.is_valid():
            win.Windows.window_dict.update({name: window})
            parent.disable_all_buttons()
        else:
            state = window.state
            window.destroy()
    elif name == "Report":
        window = rep.Report(parent, title, param_1, param_2)
        if window.is_valid():
            win.Windows.window_dict.update({name: window})
            parent.disable_all_buttons()
        else:
            state = window.state
            window.destroy()

    if window == None or window.state != "OK":
        window = err.Error(parent, title, state)
        parent.disable_all_buttons()

    
    return window
    


def format_label(field):
    upper = True
    result = ""
    for idx in range(len(field)):
        chr = field[idx]
        if upper:
            result += chr.upper()
        else:
            result += chr.lower()
        upper = (chr == '_')
            
    return result


