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
input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
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

int startTime = (int)TimeCurrent();
int currentTime = (int)TimeCurrent();

void OnDeinit(const int reason)
{ 

}

void OnTick() 
{
    if(cci_signal(BUY))
    { 
        close_all_positions(); 
        takeTrade(LONG);
    }
    if(cci_signal(SELL))
    {
        close_all_positions(); 
        takeTrade(SHORT);
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
   if(entry == LONG && expertIsTakingBuyTrade)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
   }
   if(entry == SHORT && expertIsTakingSellTrade)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double bid, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
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

void recentSwing(marketEntry entry) {
    double price = 0;
    if(entry == SELL) {
        for(int i=1; i<100; i++)
        {
            Ihihg
        }
    }

}

input group                                       "============  Commondity Channel Index Settings  ===============";
input bool                                         cciFactor = true; // Use CCI 
input int                                          cciPeriod = 100; // CCI Period
input ENUM_APPLIED_PRICE                           cciAppliedPrice = PRICE_CLOSE; // CCI Applied Price
input int                                          cciOverBoughtLevel = 100; // CCI Overbought Level
input int                                          cciOverSoldLevel = -100; // CCI OverSold Level

bool cciSignalBuy = false;
bool cciSignalSell = false;

bool cciOverSoldSignalCrossUp = false;
bool cciOverSoldSignalCrossDown = false;

bool cciOverBoughtSignalCrossUp = false;
bool cciOverBoughtSignalCrossDown = false;

bool cciComingFromOverbought = false;
bool cciComingFromOversold = false;

bool cci_signal(marketSignal signal){
   if(!cciFactor) return true;
   int cciHandle = iCCI(Symbol(), Period(), cciPeriod, cciAppliedPrice);
   double cciArray[];
   ArraySetAsSeries(cciArray, true);
   CopyBuffer(cciHandle, 0, 0, 3, cciArray);
   double cciValue = cciArray[0];
//    Print("CCI: ", cciValue);
   if(signal == BUY && cciValue > cciOverBoughtLevel && !cciOverBoughtSignalCrossUp)
    {
        // Print("buy signal enter into overbought");
        cciOverBoughtSignalCrossUp = true;
        cciOverBoughtSignalCrossDown = false;

        return true;
    }
    if(signal == BUY && cciComingFromOversold && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverSoldSignalCrossUp)
    {
        // Print("buy signal coming from oversold");
        cciOverSoldSignalCrossUp = true;
        cciOverSoldSignalCrossDown = false;
        
        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(signal == SELL && cciValue < cciOverSoldLevel && !cciOverSoldSignalCrossDown)
    {
        // Print("sell signal enter into oversold");
        cciOverSoldSignalCrossUp = false;
        cciOverSoldSignalCrossDown = true;

        return true;
    }
    if(signal == SELL && cciComingFromOverbought && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverBoughtSignalCrossDown)
    {
        // Print("sell signal coming from overbought");
        cciOverBoughtSignalCrossUp = false;
        cciOverBoughtSignalCrossDown = true;

        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(cciValue < cciOverSoldLevel)
    {
        // Print("Oversold");
        cciComingFromOversold = true;
        cciComingFromOverbought = false;
    }
    if(cciValue > cciOverBoughtLevel)
    {
        // Print("Overbought");
        cciComingFromOversold = false;
        cciComingFromOverbought = true;
    }
    return false;
}