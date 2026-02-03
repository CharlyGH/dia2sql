#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 15:14:38 2025

@author: gmd
"""

import json
import os.path       as op


class Config():
    instance = None
    data     = None
    root_dir = op.dirname(op.dirname(op.realpath(__file__)))


    def __init__(self):
        raise RuntimeError('Call get_instance() instead')

    @classmethod
    def get_instance(cls, filename="gui/gui.json"):
        if cls.instance is None:
            cls.gtab = "   "
            cls.nl   = "\n"
            cls.instance = cls.__new__(cls)
            with open(cls.root_dir + "/" + filename) as stream:
                cls.data = json.load(stream)            
            # Put any initialization here.
        return cls.instance



    def show_item(self, key):
        print (key + "= " + str(self.data[key]))

    def get(self, key):
        return self.data[key]


if __name__ == "__main__":
    config = Config.get_instance("gui/gui.json")
    config.show_item("db_uri")   
    config.show_item("debug")


   
   