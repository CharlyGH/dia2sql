#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug  7 21:51:08 2025

@author: gmd
"""

import tkinter          as  tk
import idlelib.tooltip  as  iltt
import functools        as  ft
import projekt          as  pr


class Controll(tk.Frame):
    def __init__(self, win, schema_name, table_name, data, **kwargs):
        tk.Frame.__init__(self, win, **kwargs)
        bgcolor = "#ffffdf"

        projekt = pr.Projekt.get_instance()


        self.column_list = projekt.get_column_list(schema_name, table_name)
        self.schema_table_name = schema_name + "." + table_name
        self.data              = data

  
        head = tk.Frame(self, **kwargs)
        head.place(relx=0.0,rely=0.0,relheight=0.5, relwidth=1.0)

        foot = tk.Frame(self, **kwargs)
        foot.place(relx=0.0,rely=0.5,relheight=0.5, relwidth=1.0)


        self.i_button = tk.Button(head, text="Einfügen", 
                                  command=ft.partial(self.execute_controll_command,"insert"))
        self.i_button.pack(side="left", padx=10, pady=10)
        iltt.Hovertip(self.i_button,"Einen neuen Datensatz einfügen")


        self.u_button = tk.Button(head, text="Ändern", 
                                  command=ft.partial(self.execute_controll_command,"update"))
        self.u_button.pack(side="left", padx=10, pady=10)
        iltt.Hovertip(self.u_button,"Einen bestehenden Datensatz ändern")


        self.d_button = tk.Button(head, text="Löschen", 
                                  command=ft.partial(self.execute_controll_command,"delete"))
        self.d_button.pack(side="left", padx=10, pady=10)
        iltt.Hovertip(self.d_button,"Einen bestehenden Datensatz löschen")



        self.s_button = tk.Button(head, text="Suchen", 
                                  command=ft.partial(self.execute_controll_query,"search"))
        self.s_button.pack(side="left", padx=10, pady=10)
        iltt.Hovertip(self.s_button,"Einen bestehenden Datensatz ohne PK suchen")


        self.c_button = tk.Button(head, text="Leeren", 
                                  command=ft.partial(self.execute_controll_other,"clear"))
        self.c_button.pack(side="left", padx=10, pady=10)
        iltt.Hovertip(self.c_button,"Die Bildschirmmaske löschen")


        m_label = tk.Label(foot, text="Statusmeldung", **kwargs)
        m_label.pack(side="left", padx=10, pady=5)

        self.message = tk.StringVar(self)
        m_entry = tk.Entry(foot, 
                           width=100, 
                           textvariable=self.message,
                           background=bgcolor)
        m_entry.pack(side="right", padx=10, pady=5)



    def disable_all_buttons(self):
        self.i_button.config(state=tk.DISABLED)
        self.u_button.config(state=tk.DISABLED)
        self.d_button.config(state=tk.DISABLED)
        self.s_button.config(state=tk.DISABLED)
        self.c_button.config(state=tk.DISABLED)
        
        
    def  enable_all_buttons(self):
        self.i_button.config(state=tk.NORMAL)
        self.u_button.config(state=tk.NORMAL)
        self.d_button.config(state=tk.NORMAL)
        self.s_button.config(state=tk.NORMAL)
        self.c_button.config(state=tk.NORMAL)




    def execute_controll_command(self, action):
        self.data.execute_controll_command(action, self)
        self.message.set(self.data.get_status())
        
        
    def execute_controll_query(self, action):
        self.data.execute_controll_query(action, self)
        self.message.set(self.data.get_status())


    def execute_controll_other(self, action):
        self.data.execute_controll_other(action, self)
        self.message.set(self.data.get_status())
        
