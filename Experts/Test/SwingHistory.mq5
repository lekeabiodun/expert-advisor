#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};

void OnDeinit(const int reason) { }

void OnTick() 
{
    HistorySelect(0,TimeCurrent());

    Print("History Deals Total: ", HistoryDealsTotal());
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    trade.Buy(0.3, Symbol(), bid, 0, 0);
    trade.PositionClose(PositionGetSymbol(0));
}


double recentSwing(marketSignal entry) {
    double price = iHigh(Symbol(), Period(), 1);
    if(entry == BUY) {
        double price = iLow(Symbol(), Period(), 1);
        for(int i=1; i<100; i++) {
            if(price < iLow(Symbol(), Period(), i)) {
                return price;
            }
            if(price > iLow(Symbol(), Period(), i)) {
                price = iLow(Symbol(), Period(), i);
            }
        }
    }
    if(entry == SELL) {
        for(int i=1; i<100; i++) {
            if(price > iHigh(Symbol(), Period(), i)) {
                return price;
            }
            if(price < iHigh(Symbol(), Period(), i)) {
                price = iHigh(Symbol(), Period(), i);
            }
        }
    }
    return 0.0;
}