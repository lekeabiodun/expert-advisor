#include <Trade\Trade.mqh>

CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "== Money Management Settings ==";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 25; // Stop Loss in Pips
input double                                        takeProfit = 2; // Take Profit in Pips
input int                                           lookBackPeriod = 100; // Look Back Period
input int                                           lookBackS = 5; // Look back event S
input int                                           lookBackH = 8; // Look back event H

input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

void OnTick() {

   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
        tradeManager();
        timestamp = time;
        if(q_signal(BUY) && lookback(BUY)) {
            takeTrade(LONG);
        }
        if(q_signal(SELL) && lookback(SELL)) {
            takeTrade(SHORT);
        }
   }
}

void takeTrade(marketEntry entry) {
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
   }
}

void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= takeProfit ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= stopLoss) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= takeProfit ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= stopLoss ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}

bool q_signal(marketSignal signal)
{
   if(signal == BUY && iHigh(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1))
    {
        return true;
    }
    if(signal == SELL && iLow(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1))
    {
        return true;
    }
    return false;
}

bool lookback(marketSignal signal)
{
    int spikeCount = 0;
    if(signal == BUY) {
        for( int i=1; i<= lookBackPeriod; i++ ) {
            if(iClose(Symbol(), Period(), i) > iOpen(Symbol(), Period(), i)) {
                spikeCount = spikeCount + 1;
            }
        }
        if(spikeCount > lookBackS && spikeCount < lookBackH) { return true; }
    }
    if(signal == SELL) {
        for( int i=1; i<= lookBackPeriod; i++ ) {
            if(iClose(Symbol(), Period(), i) < iOpen(Symbol(), Period(), i)) {
                spikeCount = spikeCount + 1;
            }
        }
        if(spikeCount > lookBackS && spikeCount < lookBackH) { return true; }
    }
    return false;
}