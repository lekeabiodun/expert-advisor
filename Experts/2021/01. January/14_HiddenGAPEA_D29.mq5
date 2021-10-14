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
input double                                        LotSize = 1; // Lot Size
input double                                        StopLoss = 0.0; // Stop Loss in Pips
input double                                        TakeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Cover Settings ===============";
input double                                        CoverLotSize = 1; // Cover Lot Size
input double                                        CoverStopLoss = 0.0; // Cover Stop Loss in Pips
input double                                        CoverTakeProfit = 0.0; // Cover Take Profit in Pips
input group                                         "============  Recovery Settings ===============";
// input double                                        RecoveryLotSize = 1; // Recovery Lot Size
input double                                        RecoveryStopLoss = 0.0; // Recovery Stop Loss in Pips
input double                                        RecoveryTakeProfit = 0.0; // Recovery Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          ExpertIsTakingCover = false; // Take Cover
input bool                                          ExpertIsTakingRecovery = false; // Take Recovery

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

double SupportZoneHigh;
double SupportZoneLow;
double ResistantZoneHigh;
double ResistantZoneLow;

double PrevTradeZoneHigh;
double PrevTradeZoneLow;

void OnTick() 
{

    if(!SpikeLatency()) { return ; }
    
    // TradePositionManager();

    int new_zone = NewGAP();

    if(new_zone < 4) { return; }

    if(new_zone == 4 && PrevTradeZoneHigh != ResistantZoneHigh && PrevTradeZoneLow != ResistantZoneLow)
    {
        PrevTradeZoneHigh = ResistantZoneHigh;
        PrevTradeZoneLow = ResistantZoneLow;
        TakeTrade(MARKET_ENTRY_SHORT);
    }

    if(new_zone == 5 && PrevTradeZoneHigh != SupportZoneHigh && PrevTradeZoneLow != SupportZoneLow)
    {
        PrevTradeZoneHigh = SupportZoneHigh;
        PrevTradeZoneLow = SupportZoneLow;
        TakeTrade(MARKET_ENTRY_LONG);
    }

}

input group                                         "============  WRB Hidden Gap Settings  ===============";
input bool                                          UseWholeBars = 3;                   // UseWholeBars
input int                                           WRB_LookBackBarCount = 3;           // WRB_LookBackBarCount
input int                                           WRB_WingDingsSymbol = 115;          // WRB_WingDingsSymbol
input color                                         HGColor1 = clrDodgerBlue;           // HGColor1
input color                                         HGColor2 = clrBlue;                 // HGColor2
input ENUM_LINE_STYLE                               HGStyle = STYLE_SOLID;              //HGStyle
input int                                           StartCalculationFromBar = 100;      // StartCalculationFromBar
input bool                                          HollowBoxes = false;                // HollowBoxes
input bool                                          DoAlerts = false;                   //DoAlerts


int SHVEDHandle = iCustom(NULL, Period(), "HiddenGap", UseWholeBars, WRB_LookBackBarCount, WRB_WingDingsSymbol, HGColor1, HGColor2, HGStyle, StartCalculationFromBar, HollowBoxes, DoAlerts);

int NewGAP()
{
    int level = -1;
    
    double Array1[], Array2[], Array3[], Array4[], Array5[], Array6[], Array7[], Array8[];

    ArraySetAsSeries(Array1, true);
    ArraySetAsSeries(Array2, true);
    ArraySetAsSeries(Array3, true);
    ArraySetAsSeries(Array4, true);
    ArraySetAsSeries(Array5, true);
    ArraySetAsSeries(Array6, true);
    ArraySetAsSeries(Array7, true);
    ArraySetAsSeries(Array8, true);

    CopyBuffer(SHVEDHandle, 0, 1, 2, Array1);
    CopyBuffer(SHVEDHandle, 1, 1, 2, Array2);
    CopyBuffer(SHVEDHandle, 2, 1, 2, Array3);
    CopyBuffer(SHVEDHandle, 3, 1, 2, Array4);

    CopyBuffer(SHVEDHandle, 4, 1, 2, Array5);
    CopyBuffer(SHVEDHandle, 5, 1, 2, Array6);

    CopyBuffer(SHVEDHandle, 6, 1, 2, Array7);
    CopyBuffer(SHVEDHandle, 7, 1, 2, Array8);

    ResistantZoneHigh = Array5[0];
    ResistantZoneLow = Array6[0];
    SupportZoneHigh = Array7[0];
    SupportZoneLow = Array8[0];
    
    double Close[];

    ArraySetAsSeries(Close, true);

    CopyClose(Symbol(), 0, 0, 1, Close);

    // check for entries
    
    // if(Close[0] >= ResistantZoneLow && Close[0] < ResistantZoneHigh)
    // {
    //     return 4;
    // }
    
    // if(Close[0] <= SupportZoneHigh && Close[0] > SupportZoneLow)
    // {
    //     return 5;
    // }

    Print("Array1: ", (int) Array1[0]);
    Print("Array2: ", (int) Array2[0]);
    Print("Array3: ", (int) Array3[0]);
    Print("Array4: ", (int) Array4[0]);
    Print("Array5: ", (int) Array5[0]);
    Print("Array6: ", (int) Array6[0]);
    Print("Array7: ", (int) Array7[0]);
    Print("Array8: ", (int) Array8[0]);

    return level;

}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{
    if(EXPERT_BEHAVIOUR == EXPERT_BEHAVIOUR_OPPOSITE) {
        if(Entry == MARKET_ENTRY_LONG) 
        {
            Entry = MARKET_ENTRY_SHORT;
        } 
        else if(Entry == MARKET_ENTRY_SHORT)
        {
            Entry = MARKET_ENTRY_LONG;
        }
    }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl			= NormalizeDouble(ask - StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(ask + TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(LotSize, Symbol(), ask, sl, tp);
        if(ExpertIsTakingCover) { TakeCoverTrade(MARKET_ENTRY_LONG); }
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
        if(ExpertIsTakingCover) { TakeCoverTrade(MARKET_ENTRY_SHORT); }
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
    }

}

/* ##################################################### Spike LATENCY ##################################################### */
input group                                         "===================== Latency Settings =====================";
input bool                                          UseSpikeLatency = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrame = PERIOD_CURRENT; // Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool SpikeLatency()
{
    if(!UseSpikeLatency) { return true; }

    tradeCandleTime = iTime(Symbol(), ExpertLatencyTimeFrame, 0);
    
    if(tradeTimestamp != tradeCandleTime) 
    {

        tradeTimestamp = tradeCandleTime;

        return true;
    }

    return false;
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

bool ExpertAllows(ENUM_POSITION_TYPE PositionType) 
{
    bool result = true;

    if(!PositionsTotal()) { return true; }

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == PositionType) { 
            result = false; 
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
                // Comment("TP HIT");

            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            // close_all_orders();

            // TakeTrade(m_deal.Price());
        }
    }
}

/* ##################################################### Cover Trade ##################################################### */
void TakeCoverTrade(ENUM_MARKET_ENTRY Entry) {

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask          = SupportZoneLow;
        double sl			= NormalizeDouble(ask + CoverStopLoss * _Point, _Digits) * (CoverStopLoss > 0);
        double tp			= NormalizeDouble(ask - CoverTakeProfit * _Point, _Digits) * (CoverTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.SellStop(CoverLotSize, ask, Symbol(), sl, tp);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = ResistantZoneHigh;
        double sl			= NormalizeDouble(bid - CoverStopLoss * _Point, _Digits) * (CoverStopLoss > 0);
        double tp			= NormalizeDouble(bid + CoverTakeProfit * _Point, _Digits) * (CoverTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.BuyStop(CoverLotSize, bid, Symbol(), sl, tp);
    }
}

/* ##################################################### Recovery ##################################################### */
void TakeRecoveryTrade(ENUM_MARKET_ENTRY Entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    double RecoveryLotSize = NormalizeDouble(dealLost / RecoveryTakeProfit, _Digits);

    if(RecoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { RecoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
    if(RecoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { RecoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl			= NormalizeDouble(ask - RecoveryStopLoss * _Point, _Digits) * (RecoveryStopLoss > 0);
        double tp			= NormalizeDouble(ask + RecoveryTakeProfit * _Point, _Digits) * (RecoveryTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(RecoveryLotSize, Symbol(), ask, sl, tp, "Recovery");
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {

        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + RecoveryStopLoss * _Point, _Digits) * (RecoveryStopLoss > 0);
        double tp			= NormalizeDouble(bid - RecoveryTakeProfit * _Point, _Digits) * (RecoveryTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(RecoveryLotSize, Symbol(), bid, sl, tp, "Recovery");
    }
}

double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + dealProfit; }

        if(dealProfit > 0) { break; }

    }

    return dealLost;
}

