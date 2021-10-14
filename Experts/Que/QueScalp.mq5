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
enum tradeStyle {
    timeTrade,          // Use Time Trade
    candleTrade,        // Trade Candle
    signalTrade         // Trade Signal To Signal
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
input int                                           tradeTimer = 50; // Time to trade (secs)
input tradeStyle                                    expertTradeStyle = signalTrade; // Expert Trade Style
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
static datetime timestamp;

void OnTick() 
{
   tradeCurrentTime   = (int)TimeCurrent();
   datetime time = iTime(_Symbol, _Period, 0);

   close_all_sell_trade_on_spike();

   if(timestamp != time) 
   {
        timestamp = time;
        // if(macd_signal(BUY) && perfect_trendline_signal(BUY))
        if(moving_average_signal(BUY))
        {
            close_all_positions();
            enterFor(LONG);
        }
        // if(macd_signal(SELL) && perfect_trendline_signal(SELL))
        if(moving_average_signal(SELL))
        {
            close_all_positions();
            enterFor(SHORT);
        }
   }


}


void takeTrade(marketEntry entry) 
{
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   tradeStartTime = (int)TimeCurrent();
   
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

void trade_time_management()
{
    if(PositionsTotal() && tradeTimer)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTimer)
        {
            close_all_positions();
        }
    }
    
    if(OrdersTotal() && tradeTimer)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTimer)
        {
            close_all_orders();
        }
    }
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

void close_all_orders()
{
    if(OrdersTotal())
    {
        for(int i=0; i < OrdersTotal(); i++)
        {
            trade.OrderDelete(OrderGetTicket(i));
        }
    }
}

void enterFor(marketEntry entry)
{
    if(entry == LONG && expertIsTakingBuyTrade)
    {
        takeTrade(LONG);
    }
    if(entry == SHORT && expertIsTakingSellTrade)
    {
        takeTrade(SHORT);
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


void close_all_sell_trade_on_spike()
{
    
    if(PositionsTotal() && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1))
    {
        for(int i = 0; i < PositionsTotal(); i++)
        {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}

#include "signals.mq5"