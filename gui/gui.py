#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Aug 21 20:24:16 2025

@author: gmd
"""


import sys
import os.path       as op

sys.path.append(op.dirname(op.realpath(__file__)))
import window_methods    as wm
import projekt           as pr


class Gui:
    def __init__(self):
        main = wm.get_window(None, "Main")
        main.mainloop()



if __name__ == "__main__":
    if len(sys.argv) < 2:
        print ("Aufruf: gui json-file")
        sys.exit(1)
        
        
    pr.Projekt.get_instance(sys.argv[1])
    gui = Gui()
