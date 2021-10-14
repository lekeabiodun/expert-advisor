#include <Trade\Trade.mqh>
CTrade trade;
CDealInfo m_deal;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade


int MaxPrice = 0;
int MinPrice = 0; 

int CurrSellLevel;
int PrevSellLevel;

int CurrBuyLevel;
int PrevBuyLevel;

double ticks[8];

void OnTick() 
{
    ticks[7] = ticks[6];
    ticks[6] = ticks[5];
    ticks[5] = ticks[4];
    ticks[4] = ticks[3];
    ticks[3] = ticks[2]; 
    ticks[2] = ticks[1]; 
    ticks[1] = ticks[0]; 
    ticks[0] = iClose(Symbol(), Period(), 0); 

    int zone = (int) ticks[0];
    double open = iOpen(Symbol(), Period(), 0);

    // Print("Tick 0: ", ticks[0]);
    // Print("Tick 1: ", ticks[1]);
    // Print("Tick 2: ", ticks[2]);
    // Print("Tick 3: ", ticks[3]);
    // Print("Tick 4: ", ticks[4]);
    // Print("Tick 5: ", ticks[5]);
    // Print("Zone: ", zone);
    // Print("Zone: M ", ticks[0] - zone);
    

    // if(ticks[1] <= zone && ticks[0] >= zone)
    // {
    //     Print("New buy zone enter: ", zone);

    //     if(ZoneInOrder(zone + 1))
    //     {
    //         return;
    //     }

    //     TakeOrder(MARKET_ENTRY_LONG, zone);
    // }
    

    // if(ticks[1] >= zone && ticks[0] <= zone)
    // {
    //     Print("New sell zone enter: ", zone);

    //     if(ZoneInOrder(zone - 1))
    //     {
    //         return;
    //     }
        
    //     TakeOrder(MARKET_ENTRY_SHORT, zone);
    // }

    if(ticks[1] <= zone && ticks[0] >= zone && open < zone)
    {
        Print("New buy zone enter: ", zone);

        if(ZoneInTrade(zone))
        {
            return;
        }

        if(TradeInLoss(POSITION_TYPE_BUY))
        {
            return;
        }

        close_position(POSITION_TYPE_BUY);

        TakeTrade(MARKET_ENTRY_LONG, zone);
    }
    

    if(ticks[1] >= zone && ticks[0] <= zone && open > zone)
    {
        Print("New sell zone enter: ", zone);

        if(ZoneInTrade(zone))
        {
            return;
        }

        if(TradeInLoss(POSITION_TYPE_SELL))
        {
            return;
        }

        close_position(POSITION_TYPE_SELL);

        TakeTrade(MARKET_ENTRY_SHORT, zone);
    }
    
}

void TakeOrder(ENUM_MARKET_ENTRY Entry, int zone) 
{  
    double ask = zone + 1;
    trade.BuyStop(lotSize, zone, Symbol(), ask - stopLoss, ask + takeProfit);
    double bid = zone - 1;
    trade.SellStop(lotSize, zone, Symbol(), bid + stopLoss, bid - takeProfit);
}

void TakeTrade(ENUM_MARKET_ENTRY Entry, int zone) 
{

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, zone - stopLoss, zone + takeProfit);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, zone + stopLoss, zone - takeProfit);
    }

}

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;

input group                                         "============ Latency Settings ===============";
input bool                                          expertLatency = false; // Trade Latency
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool ExpertHasLatency()
{
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);

    if(!expertLatency) {
        return false;
    } else {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return false;
        }
    }
    return true;
}

void close_position(ENUM_POSITION_TYPE PositionType) {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(PositionGetInteger(POSITION_TYPE) == PositionType) 
            { 
                trade.PositionClose(ticket);
            }
        }
    }
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

void close_all_orders() {
    if(OrdersTotal() > 0) {
        for(int i=0; i < OrdersTotal()-1; i++) {
             ulong ticket = OrderGetTicket(i);
             trade.OrderDelete(ticket);
        }
    }
}

bool ZoneInTrade(int zone)
{
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            PositionSelectByTicket(ticket);
            int pos = (int) PositionGetDouble(POSITION_PRICE_OPEN);
            if(pos == zone) { return true; }
        }
    }
    return false;
}

bool ZoneInOrder(int zone)
{
    if(OrdersTotal() > 0) {
        for(int i = OrdersTotal()-1; i >= 0; i--) {
            ulong ticket = OrderGetTicket(i);
            if(OrderSelect(ticket))
            {
                int pos = (int) OrderGetDouble(ORDER_PRICE_OPEN);
                if(pos == zone) { return true; }
            }
        }
    }
    return false;
}


bool TradeInLoss(ENUM_POSITION_TYPE PositionType) 
{
    bool result = false;

    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == PositionType) { 
                if(PositionGetDouble(POSITION_PROFIT) < 0)
                {
                    result = true; 
                }
            }
        }
    }

    return result;
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {

    ENUM_TRADE_TRANSACTION_TYPE type=trans.type;

    if(type==TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal)) {
            m_deal.Ticket(trans.deal);
        }
        else {
            Print(__FILE__," ",__FUNCTION__,", ERROR: HistoryDealSelect(",trans.deal,")");
            return;
        }
        //---
        long reason=-1;
        if(!m_deal.InfoInteger(DEAL_REASON,reason))
        {
            Print(__FILE__," ",__FUNCTION__,", ERROR: InfoInteger(DEAL_REASON,reason)");
            return;
        }
        if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL) {

            // Print("TP HIT");

        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {

                // close_all_orders();
                // close_all_positions();


            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            // close_all_orders();
        }
    }
}