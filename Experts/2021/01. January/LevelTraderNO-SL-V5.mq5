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
int SellLotSizeSupport = 0;
int BuyLotSizeSupport = 0;

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
    // if(AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY) >= StopLoss) 
    // {
    //     close_all_positions();
    // }
    ENUM_POSITION_TYPE positionType = POSITION_TYPE_SELL;
    bool opposite = false;

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetDouble(POSITION_PROFIT) <= -StopLoss) {
            if(PositionGetDouble(POSITION_VOLUME) == 2)
            {
                opposite = true;
            }
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
            if(opposite)
            {
                ulong ticket = PositionGetTicket(PositionsTotal()-1);
                trade.PositionClose(ticket);
                opposite = false;
            }

        }
    }
    if(PositionsTotal() == 2 && AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE) >= 0 && AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE) < 50) 
    {
        close_all_positions();
        close_all_orders();
    }
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

    PositionGetSymbol(1);

    if(PositionsTotal() && PositionsTotal() < 2 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
    {
        BuyLotSizeSupport = 0;
        SellLotSizeSupport = 1;
    } else if(PositionsTotal() && PositionsTotal() < 2 && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
    {
        BuyLotSizeSupport = 1;
        SellLotSizeSupport = 0;
    } else {
        BuyLotSizeSupport = 0;
        SellLotSizeSupport = 0;
    }

    
    trade.BuyStop(lotSize + BuyLotSizeSupport, NextLevel, Symbol(), 0, NextLevel+levelModulo);

    trade.SellStop(lotSize + SellLotSizeSupport, PrevLevel, Symbol(), 0, PrevLevel-levelModulo);
}
