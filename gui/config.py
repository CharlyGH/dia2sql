#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 15:14:38 2025

@author: gmd
"""

import json
import os.path       as op

class Config():
    def __init__(self, filename=op.dirname(op.realpath(__file__)) + "/gui.json"):
        with open(filename) as stream:
            self.config = json.load(stream)            

    def show_item(self, key):
        print (key + "= " + str(self.config[key]))

    def get(self, key):
        return self.config[key]


if __name__ == "__main__":
    config = Config()
    config.show_item("db_uri")   
    config.show_item("debug")


   
   