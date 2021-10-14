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
input group                                         "============  Level Settings  ===============";
input int                                           levelModulo = 10; // Level
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 100.0; // Stop Loss in Pips
input double                                        takeProfit = 100.0; // Take Profit in Pips
input group                                         "============  Trade Cover Settings ===============";
input double                                        CoverLotSize = 1; // Cover Lot Size
input double                                        CoverStopLoss = 100.0; // Cover Stop Loss in Pips
input double                                        CoverTakeProfit = 100.0; // Cover Take Profit in Pips
input int                                           CoverLevel = 4; // Cover Level
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          ExpertIsTakingCoverTrade = false; // Take Cover Trade

/*
NAME
Level Trader.
DESCRIPTION
Expert Advisor is design to trade levels.
On getting to a new level (Current Level[CL]).
Check the market direction (Market Direction[MD]).
Check the level that the market is coming from (Previous Level[PL]).
Take trade towards market direction (Next Level[NL]).

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
        
        trade.BuyStop(lotSize, NextLevel, Symbol(), PrevLevel, NextLevel+levelModulo);

        trade.SellStop(lotSize, PrevLevel, Symbol(), NextLevel, PrevLevel-levelModulo);
    }
       
}

/* ##################################################### Trade Position Manager ##################################################### */
void TradePositionManager() {
    Print("Account Balance: ", AccountInfoDouble(ACCOUNT_BALANCE), " - ", "Account Equity: ", AccountInfoDouble(ACCOUNT_EQUITY), " = ", AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY));
    if(AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY) >= stopLoss) 
    {
        close_all_positions();
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
            // close_all_orders();

            // Print("TP HIT");

        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {

                // Print("SL HIT");

            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            if(m_deal.Comment() == "Cover") { return ; }
            
            // if(m_deal.Volume() != lotSize) { return ; }
            // if(PositionsTotal() >= 2) { return ; }

            close_all_orders();

            TakeTrade(m_deal.Price());

            if(ExpertIsTakingCoverTrade) 
            {
                TakeCoverTrade(m_deal.Price(), m_deal.DealType());
            }
        }
    }
}


void TakeTrade(double CurrPrice) 
{
    CurrLevel = MathRound(CurrPrice/levelModulo) * levelModulo;
    NextLevel = CurrLevel + levelModulo;
    PrevLevel = CurrLevel - levelModulo;
    
    trade.BuyStop(lotSize, NextLevel, Symbol(), CurrLevel, NextLevel+levelModulo);

    trade.SellStop(lotSize, PrevLevel, Symbol(), CurrLevel, PrevLevel-levelModulo);
}

void TakeCoverTrade(double CurrPrice, ENUM_DEAL_TYPE DealType) 
{
    CurrLevel = MathRound(CurrPrice/levelModulo) * levelModulo;

    if(DealType == DEAL_TYPE_BUY)
    {
        PrevLevel = CurrLevel - CoverLevel;
        
        trade.SellStop(CoverLotSize, PrevLevel, Symbol(), CurrLevel + levelModulo, PrevLevel-(levelModulo - CoverLevel), 0, 0, "Cover");

    }

    if(DealType == DEAL_TYPE_SELL)
    {
        NextLevel = CurrLevel + CoverLevel;
        
        trade.BuyStop(CoverLotSize, NextLevel, Symbol(), CurrLevel - levelModulo, NextLevel+(levelModulo - CoverLevel), 0, 0, "Cover");
    }

}