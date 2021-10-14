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

int sell_count = 0;
int buy_count = 0;

void OnDeinit(const int reason)
{
    Print("Sell: ", sell_count);
    Print("Buy: ", buy_count);

}

void OnTick() 
{
    // datetime time = iTime(Symbol(), Period(), 0);

    // if(timestamp != time) 
    // {
    
    if(wpr_signal(BUY))
    { 
        close_all_positions(); 
        takeTrade(LONG);
    }
    if(wpr_signal(SELL))
    {
        close_all_positions(); 
        takeTrade(SHORT);
    }
    
    // }
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


input group                                       "============  Williams Percentage Settings  ===============";
input bool                                         wprFactor = true; // Use WPR 
input int                                          wprPeriod = 100; // WPR Period
input int                                          wprOverBoughtLevel = -20; // WPR Overbought Level
input int                                          wprOverSoldLevel = -80; // WPR OverSold Level

bool wprSignalBuy = false;
bool wprSignalSell = false;

bool wprOverSoldSignalCrossUp = false;
bool wprOverSoldSignalCrossDown = false;

bool wprOverBoughtSignalCrossUp = false;
bool wprOverBoughtSignalCrossDown = false;

bool wprComingFromOverbought = false;
bool wprComingFromOversold = false;

bool wpr_signal(marketSignal signal){
   if(!wprFactor) return true;
   int wprHandle = iWPR(Symbol(), Period(), wprPeriod);
   double wprArray[];
   ArraySetAsSeries(wprArray, true);
   CopyBuffer(wprHandle, 0, 0, 3, wprArray);
   double wprValue = wprArray[0];
   if(signal == BUY && wprValue > wprOverBoughtLevel && !wprOverBoughtSignalCrossUp)
    {
        wprOverBoughtSignalCrossUp = true;
        wprOverBoughtSignalCrossDown = false;
        Print("WPR OverBought Level Cross Up");
        buy_count++;
        return true;
    }
    if(signal == BUY && wprComingFromOversold && wprValue > wprOverSoldLevel && wprValue < wprOverBoughtLevel && !wprOverSoldSignalCrossUp)
    {
        wprOverSoldSignalCrossDown = false;
        wprOverSoldSignalCrossUp = true;
        
        wprComingFromOversold = false;
        wprComingFromOverbought = false;

        Print("WPR Oversold Level CrossUp");
        buy_count++;
        return true;
    }
    if(signal == SELL && wprComingFromOverbought && wprValue > wprOverSoldLevel && wprValue < wprOverBoughtLevel && !wprOverBoughtSignalCrossDown)
    {
        wprOverBoughtSignalCrossUp = false;
        wprOverBoughtSignalCrossDown = true;

        wprComingFromOversold = false;
        wprComingFromOverbought = false;
        Print("WPR OverBought Level Cross down");
        sell_count++;
        return true;
    }
    if(signal == SELL && wprValue < wprOverSoldLevel && !wprOverSoldSignalCrossDown)
    {
        wprOverSoldSignalCrossDown = true;
        wprOverSoldSignalCrossUp = false;
        Print("WPR Oversold Level Cross Down");
        sell_count++;
        return true;
    }
    if(wprValue < wprOverSoldLevel)
    {
        wprComingFromOversold = true;
        wprComingFromOverbought = false;
    }
    if(wprValue > wprOverBoughtLevel)
    {
        wprComingFromOverbought = true;
        wprComingFromOversold = false;
    }
    return false;
}