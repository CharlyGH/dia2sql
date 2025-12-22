#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 29 10:49:12 2025

@author: gmd
"""

import tkinter.ttk    as  ttk

class SelectBox(ttk.Combobox):
    def __init__(self, win, selected_label, label_list, value_list, dflt_idx, **kwargs):
        self.selected_label = selected_label


        width  = self.get_label_width(label_list)
        super().__init__(win, 
                         textvariable=self.selected_label,
                         width = width + 1,
                         state = "readonly",
                         values = label_list,
                         **kwargs)
        
        self.set(label_list[dflt_idx])
        self.label_list = label_list
        self.value_list = value_list

        self.current_value = value_list[dflt_idx]
        self.bind("<<ComboboxSelected>>", self.changed_value)


    def get_selected_value(self):
        return self.current_value

    def get_selected_label(self):
        return self.selected_label.get()


    def get_label_width(self,lis):
        text_width = 0
        for line in lis:
            text_len = len(line)
            if text_len > text_width:
                text_width = text_len
        return text_width
    
    
    def changed_value(self, event):
        idx = self.current()
        self.current_value = self.value_list[idx]
        # print ("setting current value zu " + self.current_value)
        
