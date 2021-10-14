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

ENUM_MARKET_DIRECTION MarketDirection;

double MaxPrice = 0;
double MinPrice = 0; 

void OnTick() 
{
    TradePositionManager();

    if(!OrdersTotal() && !PositionsTotal())
    {
        int CurrPrice = (int) iClose(Symbol(), Period(), 0);
        int Pricediff = 10 - (MathMod(CurrPrice, levelModulo));
        NextLevel = CurrPrice + Pricediff;
        PrevLevel = CurrPrice - (10 - Pricediff);
        
        trade.BuyStop(lotSize, NextLevel, Symbol(), 0, NextLevel+levelModulo);

        trade.SellStop(lotSize, PrevLevel, Symbol(), 0, PrevLevel-levelModulo);
    }
       
}

/* ##################################################### Trade Position Manager ##################################################### */
void TradePositionManager() {
    // Print("Account Balance: ", AccountInfoDouble(ACCOUNT_BALANCE), " - ", "Account Equity: ", AccountInfoDouble(ACCOUNT_EQUITY), " = ", AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY));
    // if(AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY) >= stopLoss) 
    // {
    //     close_all_positions();
    // }
    return ;
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

void close_all(ENUM_DEAL_TYPE DealType)
{
    if(DealType == DEAL_TYPE_SELL && PositionsTotal())
    {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
    }
    
    if(DealType == DEAL_TYPE_BUY && PositionsTotal())
    {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
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

                // Print("DealType: ", m_deal.DealType());

                // close_all(m_deal.DealType());

                if(m_deal.DealType() == DEAL_TYPE_SELL && PositionsTotal())
                {
                    // Comment("Buy TP");
                    for(int i = PositionsTotal()-1; i >= 0; i--) {
                        PositionGetSymbol(i);
                        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) // && PositionGetDouble(POSITION_PROFIT) > 50)
                        {
                            // if(PositionGetDouble(POSITION_PROFIT) < -(TakeProfit))
                            // {
                            //     ulong ticket = PositionGetTicket(i);
                            //     trade.PositionClose(ticket);
                            //     return;
                            // }
                            
                            ulong ticket = PositionGetTicket(i);
                            trade.PositionClose(ticket);
                        }
                    }
                }
                
                if(m_deal.DealType() == DEAL_TYPE_BUY && PositionsTotal()) // && PositionGetDouble(POSITION_PROFIT) > 50)
                {
                    // Comment("Sell TP");
                    for(int i = PositionsTotal()-1; i >= 0; i--) {
                        PositionGetSymbol(i);
                        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                        {
                            // if(PositionGetDouble(POSITION_PROFIT) < -(TakeProfit))
                            // {
                            //     ulong ticket = PositionGetTicket(i);
                            //     trade.PositionClose(ticket);
                            //     return;
                            // }
                            ulong ticket = PositionGetTicket(i);
                            trade.PositionClose(ticket);
                        }
                    }
                }

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
    
    trade.BuyStop(lotSize, NextLevel, Symbol(), 0, NextLevel+levelModulo);

    trade.SellStop(lotSize, PrevLevel, Symbol(), 0, PrevLevel-levelModulo);
}
