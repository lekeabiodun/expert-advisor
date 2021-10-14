
input group                                         "============  Spread Settings ===============";
input bool                                          UseTradeSpreadChecker = false; // Use Trade Spread Checker
input double                                        TradeMaxSpreadLimit = 10.0; // Trade Max Spread Limit

bool SpreadIsHigh() { 

    if(!UseTradeSpreadChecker) { return false; }
    
    //  iSpread(Symbol(), Period(), 0)
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double current_spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(current_spread < TradeMaxSpreadLimit) { return false; }

    return true; 
}