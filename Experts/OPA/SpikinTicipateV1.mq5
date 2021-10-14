#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};
enum marketEntry {
   LONG,                // Only Long
   SHORT                // Only Short
};
enum tradeBehaviour {   
   REGULAR,             // Regular
   OPPOSITE             // Opposite
};

enum marketTrend{
    BULLISH, 
    BEARISH, 
    SIDEWAYS
};

input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

int OnInit()
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

void OnTick() 
{
   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
       tradeManager();
        timestamp = time;
        if(q_signal(BUY))
        { 
            takeTrade(LONG);
        }
        if(q_signal(SELL))
        {
            takeTrade(SHORT);
        }  
    }
}

void takeTrade(marketEntry entry) {
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, iOpen(Symbol(), Period(), 1), 0);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
   }
}


void tradeManager() {
    if(PositionsTotal()) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -stopLoss && stopLoss) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -stopLoss && stopLoss ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
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


