

void OnTick() {

    if(TradeHasLatency()) { return; }

    if(SpreadIsHigh()) { return; }

    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double current_spread_point = MathMax(ask, bid) - MathMin(bid, ask);
    double current_spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    Print("Bid: ", bid, " Ask: ", ask, " Spread point: ", current_spread_point, " Spread: ", current_spread, " Alt: ", iSpread(Symbol(), Period(), 0));

}

#include "../../modules/SpreadIsHigh.mqh";

#include "../../modules/TradeHasLatency.mqh";