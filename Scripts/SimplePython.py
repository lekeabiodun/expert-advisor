# Copyright 2020, MetaQuotes Software Corp.
# https://www.mql5.com

from datetime import datetime
import MetaTrader5 as mt5
# import tensorflow as tf
# import numpy as np
# import matplotlib.pyplot as plt

mt5.initialize()

# display data on the MetaTrader 5 package
print("MetaTrader5 package author: ",mt5.__author__)
print("MetaTrader5 package version: ",mt5.__version__)
 
# establish connection to the MetaTrader 5 terminal
if not mt5.initialize():
    print("initialize() failed, error code =",mt5.last_error())
    quit()
 
# attempt to enable the display of the Boom 500 Index symbol in MarketWatch
selected=mt5.symbol_select("Boom 500 Index",True)
if not selected:
    print("Failed to select Boom 500 Index")
    mt5.shutdown()
    quit()
 
# display Boom 500 Index symbol properties
symbol_info=mt5.symbol_info("Boom 500 Index")
if symbol_info!=None:
    # display the terminal data 'as is'    
    print(symbol_info)
    print("Boom 500 Index: spread =",symbol_info.spread,"  digits =",symbol_info.digits)
    # display symbol properties as a list
    print("Show symbol_info(\"Boom 500 Index\")._asdict():")
    symbol_info_dict = mt5.symbol_info("Boom 500 Index")._asdict()
    for prop in symbol_info_dict:
        print("  {}={}".format(prop, symbol_info_dict[prop]))
 
# shut down connection to the MetaTrader 5 terminal

mt5.shutdown()
