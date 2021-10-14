
#include <Trade\Trade.mqh>
CTrade trade;
static datetime timestamp;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};

int sellCount = 0;
int buyCount = 0;
int totalCount = 0;

double stopLoss = 2;

double takeProfit = 0.5;

input int tPeriod = 14;

void OnTick()
{

   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
        tradeManager();
        timestamp = time;
        if(deMarker_signal(BUY)) {
           double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
           trade.Sell(1, Symbol(), ask, 0, 0);
        }
        if(deMarker_signal(SELL)) {
           double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
           trade.Sell(1, Symbol(), bid, 0, 0);
        }

        totalCount = totalCount + 1;

        if( iOpen(Symbol(), Period(), 1) > iClose(Symbol(), Period(), 1))
        {
            sellCount = sellCount + 1;
        }
        
        if( iOpen(Symbol(), Period(), 1) < iClose(Symbol(), Period(), 1))
        {
            buyCount = buyCount + 1;

        }
        Comment("Sell: ", sellCount, "\nBuy: ", buyCount, "\nTotal: ", totalCount);
        
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


int deMarkerHandle = iDeMarker(Symbol(), Period(), tPeriod);

bool deMarker_signal(marketSignal signal)
{
   double deMarkerArray[];
   ArraySetAsSeries(deMarkerArray, true);
   CopyBuffer(deMarkerHandle, 0, 0, 3, deMarkerArray);
   if(signal == BUY && deMarkerArray[0] > deMarkerArray[1])
    {
        return true;
    }
    if(signal == SELL && deMarkerArray[0] < deMarkerArray[1])
    {
        return true;
    }
    return false;
}

/*
int cciHandle = iCCI(Symbol(), Period(), cciPeriod, PRICE_CLOSE);

bool cci_signal(marketSignal signal){
   double cciArray[];
   ArraySetAsSeries(cciArray, true);
   CopyBuffer(cciHandle, 0, 0, 3, cciArray);
   if(signal == BUY && cciArray[0] > cciArray[1]) 
    { 
        return true; 
    }
    if(signal == SELL && cciArray[0] < cciArray[1]) 
    { 
        return true; 
    }
   return false;
}

*/
