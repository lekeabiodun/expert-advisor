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

void OnTick() 
{
   datetime time = iTime(_Symbol, PERIOD_M1, 0);

   if(timestamp != time) 
   {
        timestamp = time;
        if(rsi_signal(BUY))
        { 
            close_opposite_trade(LONG);  
            enterFor(LONG);
        }
        if(rsi_signal(SELL))
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


input group                                       "============  rsi Settings  ===============";
input bool                                         rsiFactor = true; // Use RSI
input ENUM_TIMEFRAMES                              rsiTimeframe = PERIOD_CURRENT; // RSI Timeframe
input int                                          rsiPeriod = 9; // RSI Period
input ENUM_APPLIED_PRICE                           rsiAppliedPrice = PRICE_CLOSE; // RSI Applied Price
input int                                          rsiOverSoldLevel = 30; // RSI Oversold Level
input int                                          rsiOverBoughtLevel = 70; // RSI Overbought Level


bool rsiSignalBuy = false;
bool rsiSignalSell = false;

int rsiHandle = iRSI(Symbol(), rsiTimeframe, rsiPeriod, rsiAppliedPrice);
bool rsi_signal(marketSignal signal){
    if(!rsiFactor) return true;
    double rsiArray[];
    ArraySetAsSeries(rsiArray, true);
    CopyBuffer(rsiHandle, 0, 0, 3, rsiArray);
    double rsiValue = NormalizeDouble(rsiArray[0],2);
    if(signal == BUY && rsiValue > rsiOverSoldLevel && rsiValue < rsiOverBoughtLevel && rsiSignalBuy) 
    {
        return true; 
    }
    if(signal == SELL && rsiValue < rsiOverBoughtLevel && rsiValue > rsiOverSoldLevel && rsiSignalSell) 
    {
        return true;
    }
    if(rsiValue < rsiOverSoldLevel)
    {
        rsiSignalBuy = true;
        rsiSignalSell = false;
        close_all_positions();
    }
    if(rsiValue > rsiOverBoughtLevel)
    {
        rsiSignalSell = true;
        rsiSignalBuy = false;
        close_all_positions();
    }
    return false;
}

