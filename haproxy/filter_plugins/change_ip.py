#!/usr/bin/env python

class FilterModule(object):
  @staticmethod
  def get_ip_list(*args):
    ip_list = args.splite(",")
    return ip_list
  def filters(self):
    return {"get_ip_list":self.get_ip_list,}    
