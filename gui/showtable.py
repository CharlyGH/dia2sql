#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  2 09:48:26 2025

@author: Charly
"""

#https://www.pythontutorial.net/tkinter/tkinter-combobox/
#https://pypi.org/project/tkinterPdfViewer/
#https://pypi.org/project/tkinterweb/

import tkinter      as tk
import sys
import os.path      as op
from tkinterPdfViewer import tkinterPdfViewer as pdf
from tkinterweb       import HtmlFrame

sys.path.append(op.dirname(op.realpath(__file__)))
import window       as win
import project      as pr
import config       as cnf
import createpdf    as cp
import createhtml   as ch


class ShowTable(win.Window):
    def __init__(self, parent, title, schema_name, table_name, display_mode, format_name):
        win.Window.__init__(self, parent, "ShowTable", title, self.get_size(800,600,700,80))

        config = cnf.Config.get_instance()
        bgcolor = config.get("show.bg.color")
        print("ShowTable.init: title=" + title + ",  schema=" + schema_name + 
              ",  table=" + table_name + ",  display_mode" + display_mode + 
              ",   format_name=" + format_name)
        project = pr.Project.get_instance()
        height = 1.0/10.0
          
        head = tk.Frame(self, background=bgcolor)
        head.place(relx=0.0,rely=0.0,relheight=1.0-height, relwidth=1.0)
        self.showpdf = None
        
        if format_name == "pdf":
            pd = cp.CreatePDF.get_instance(project.project_file)
            pdffilename, rows, cols = pd.process_data(schema_name, table_name)

            if pdffilename != None:
                if display_mode == "intern":
                    self.showpdf = pdf.ShowPdf()
                    view = self.showpdf.pdf_view(head, 
                                                 pdf_location=pdffilename, 
                                                 width=800, 
                                                 height=540)
                    view.place(relx=0.0, rely=0.0, relheight=1.0, relwidth=1.0)
                else:
                    pd.display_pdf_file(pdffilename)
            else:
                label = tk.Label(head, text="Keine Daten zum Anzeigen gefunden")
                label.pack(padx=10, pady=10)
        elif format_name == "html":
            ht = ch.CreateHTML.get_instance(project.project_file)
            htmlfilename, rows, cols = ht.process_data(schema_name, table_name)

            if htmlfilename != None:
                if display_mode == "intern":
                    frame = HtmlFrame(head, 
                                      horizontal_scrollbar="auto",
                                      vertical_scrollbar="auto",
                                      messages_enabled = False)
                    frame.load_file(htmlfilename)
                    frame.place(relx=0.0, rely=0.0, relheight=1.0, relwidth=1.0)
                else:
                    ht.display_html_file(htmlfilename)
            else:
                label = tk.Label(head, text="Keine Daten zum Anzeigen gefunden")
                label.pack(padx=10, pady=10)

        foot = tk.Frame(self, background=bgcolor)
        foot.place(relx=0.0,rely=1.0-height,relheight=height, relwidth=1.0)

        self.e_button = tk.Button(foot, text="Ende", command=self.on_closing)
        self.e_button.pack(side="right", padx=10, pady=10)
        

    def disable_all_buttons(self):
        self.e_button.config(state=tk.DISABLED)
        self.control.disable_all_buttons()
        self.datamask.disable_all_buttons()
        
        
    def enable_all_buttons(self):
        self.e_button.config(state=tk.NORMAL)
        self.control.enable_all_buttons()
        self.datamask.enable_all_buttons()


    def on_closing(self):
        if self.showpdf != None:
            self.showpdf.close_pdf()
        super().on_closing()
