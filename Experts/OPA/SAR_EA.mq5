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

enum signalFREQ {
    candle,          // Check signal on every candle 
    tick           // Check signal on every tick 
};
input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input signalFREQ                                    expertSignalFREQ = tick; // Signal Frequency
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

void OnTick() 
{
   datetime time = iTime(_Symbol, PERIOD_M1, 0);

   if(timestamp != time && expertSignalFREQ == candle) 
   {
        timestamp = time;
        if(parabolic_sar_signal(BUY))
        { 
            close_opposite_trade(LONG);  
            enterFor(LONG);
        }
        if(parabolic_sar_signal(SELL))
        {
            close_opposite_trade(SHORT);  
            enterFor(SHORT);
        }
   } else {
        if(parabolic_sar_signal(BUY))
        { 
            close_opposite_trade(LONG);  
            enterFor(LONG);
        }
        if(parabolic_sar_signal(SELL))
        {
            close_opposite_trade(SHORT);  
            enterFor(SHORT);
        }
   }



}


void takeTrade(marketEntry entry) 
{
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
      
   if(expertBehaviour == OPPOSITE)
   {
        if(entry == LONG){ entry = SHORT; }
        if(entry == SHORT){ entry = LONG; }   
   }
   
   if(entry == LONG)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
   }
   if(entry == SHORT)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double bid, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(bid, entry);
}

double calculateStopLoss(double bid, marketEntry entry)
{
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(bid, entry);
}

double calculateTakeProfit(double bid, marketEntry entry)
{
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}

void close_all_positions()
{
    if(PositionsTotal())
    {
        for(int i=0; i < PositionsTotal(); i++)
        {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void close_opposite_trade(marketEntry entry)
{

    if(PositionsTotal() && entry == LONG && closeOnOppositeSignal)
    {
        PositionGetSymbol(0);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            close_all_positions();
        }
    }
    if(PositionsTotal() && entry == SHORT && closeOnOppositeSignal)
    {
        PositionGetSymbol(0);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            close_all_positions();
        }
    }
}

void enterFor(marketEntry entry)
{
    if(entry == LONG && expertIsTakingBuyTrade && PositionsTotal() < 1)
    {
        takeTrade(LONG);
    }
    if(entry == SHORT && expertIsTakingSellTrade && PositionsTotal() < 1)
    {
        takeTrade(SHORT);
    }
}


input group                                       "============  Parabolic SAR Settings  ===============";
input double                                       step = 0.02; // Parabolic SAR Step | price increment step - acceleration factor 
input double                                       maximum = 0.2; // Parabolic SAR Maximum value of step 

int paraBolicSARHandle = iSAR(Symbol(), Period(), step, maximum);

bool parabolic_sar_signal(marketSignal signal){
    double parabolicSARArray[];
    ArraySetAsSeries(parabolicSARArray, true);
    CopyBuffer(paraBolicSARHandle, 0, 0, 3, parabolicSARArray);
    if(signal == BUY && parabolicSARArray[1] < iLow(Symbol(), Period(), 1)) 
    { 
        return true; 
    }
    else if(signal == SELL && parabolicSARArray[1] > iHigh(Symbol(), Period(), 1)) 
    { 
        return true; 
    }
    return false;
}

