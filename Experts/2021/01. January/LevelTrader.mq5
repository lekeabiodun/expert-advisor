#include <Trade\Trade.mqh>
CTrade trade;
CDealInfo m_deal;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 567891234; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Level Settings  ===============";
input int                                           levelModulo = 10; // Level
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        TakeProfit = 100.0; // Take Profit in Pips
input double                                        StopLoss = 200.0; // Stop Loss in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

/*
NAME
No Stop Loss Level Trader.
DESCRIPTION
Expert Advisor is design to trade levels without stop loss.

EXAMPLE
If market is fast approaching level 700
& the market is coming from level 600

BEGIN
Current Level[CL] = 700;
Previous Level[PL] = 600;
IF
Market Direction[MD] = UP;
THEN
Next Level[NL] = 800;
IF
Market Direction[MD] = DOWN;
THEN
Next Level[NL] = 600;
END

*/

int OnInit() {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

int PrevLevel = 0;
int CurrLevel = 0;
int NextLevel = 0;

void OnTick() 
{
    if(!OrdersTotal() && !PositionsTotal())
    {
        int CurrPrice = (int) iClose(Symbol(), Period(), 0);
        int Pricediff = 10 - (MathMod(CurrPrice, levelModulo));
        NextLevel = CurrPrice + Pricediff;
        PrevLevel = CurrPrice - (10 - Pricediff);

        TakePendingOrder(MARKET_ENTRY_LONG, NextLevel);

        TakePendingOrder(MARKET_ENTRY_SHORT, PrevLevel);
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
        for(int i = OrdersTotal()-1; i >= 0; i--) {
            ulong ticket = OrderGetTicket(i);
            trade.OrderDelete(ticket);
        }
    }
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


            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            close_all_orders();

            TakeTrade(m_deal.Price());
        }
    }
}


void TakeTrade(double CurrPrice) 
{
    CurrLevel = MathRound(CurrPrice/levelModulo) * levelModulo;
    NextLevel = CurrLevel + levelModulo;
    PrevLevel = CurrLevel - levelModulo;    

    TakePendingOrder(MARKET_ENTRY_LONG, NextLevel);

    TakePendingOrder(MARKET_ENTRY_SHORT, PrevLevel);

}

void TakePendingOrder(ENUM_MARKET_ENTRY Entry, double Price)
{
    if(Entry == MARKET_ENTRY_LONG)
    {
        double sl			= NormalizeDouble(Price - StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(Price + TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.BuyStop(lotSize, Price, Symbol(), sl, tp);

    }
    if(Entry == MARKET_ENTRY_SHORT)
    {
        double sl			= NormalizeDouble(Price + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(Price - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SellStop(lotSize, Price, Symbol(), sl, tp);
    }
}
