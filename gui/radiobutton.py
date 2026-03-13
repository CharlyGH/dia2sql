#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 29 10:49:12 2025

@author: Charly
"""

import tkinter    as  tk

class RadioButton(tk.Frame):
    def __init__(self, win, title, label_list, bgcolor, value_list=None, dflt_idx=0, **kwargs):
        self.selected_label = tk.StringVar(win)
        if value_list == None:
            value_list = label_list

        label_width  = self.get_label_width(label_list)
        tk.Frame.__init__(self, win, **kwargs)
        
        
        self.selected_label.set(label_list[dflt_idx])
        radio_label = tk.Label(win, 
                               text=title,
                               background=bgcolor,
                               padx=10)
        radio_label.pack(side="top")
        
        
        self.count = len(label_list)
        
        print("count=",self.count,"  value=",self.selected_label.get())
        
        self.radio_button_list = list()
        for idx in range(self.count):
            radio_button = tk.Radiobutton(win,
                                          text=label_list[idx],
                                          background=bgcolor,
                                          width=label_width,
                                          variable=self.selected_label,
                                          value=value_list[idx],
                                          padx=10)
            radio_button.pack(side="top")
            self.radio_button_list.append(radio_button)
        



    def get_selected_label(self):
        return self.selected_label


    def get_selected_value(self):
        return self.selected_label.get()


    def get_label_width(self,lis):
        text_width = 0
        for line in lis:
            text_len = len(line)
            if text_len > text_width:
                text_width = text_len
        return text_width
    
    
    def config(self, state):
        for idx in range(self.count):
            self.radio_button_list[idx].config(state=state)
            