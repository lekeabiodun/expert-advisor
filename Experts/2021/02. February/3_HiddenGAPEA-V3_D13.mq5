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
input group                                         "============  Money Management Settings ===============";
input double                                        riskAmount = 100; // Risk Amount
input int                                           GapPercentileEntry = 25; // Gap Percentile Entry
input int                                           GapPercentileExit = 25; // Gap Percentile Exit
input int                                           MinimalPip = 4; // Minimal pip to trade
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

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

double GapPrice;
double TradePrice;
ENUM_MARKET_ENTRY TradeEntry;
double TradeTP;
double TradeSL;
double TradeLotsize;

/**
Hidden GAP EA Use Trade Manager
**/

void OnTick() 
{

    TakeTrade();

    if(!SpikeLatency()) { return ; }

    if(!NewGAP()) { return; }

    if(iClose(Symbol(), Period(), 1) > GapPrice && MathPow(10, _Digits) * (iClose(Symbol(), Period(), 1) - GapPrice) > MinimalPip)
    {
        SetTrade(MARKET_ENTRY_SHORT);
    }

    if(iClose(Symbol(), Period(), 1) < GapPrice && MathPow(10, _Digits) * (GapPrice - iClose(Symbol(), Period(), 1)) > MinimalPip)
    {
        SetTrade(MARKET_ENTRY_LONG);
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


int GapHandle = iCustom(NULL, Period(), "HiddenGap", UseWholeBars, WRB_LookBackBarCount, WRB_WingDingsSymbol, HGColor1, HGColor2, HGStyle, StartCalculationFromBar, HollowBoxes, DoAlerts);

int NewGAP()
{
    double Array1[];

    ArraySetAsSeries(Array1, true);

    CopyBuffer(GapHandle, 0, 1, 2, Array1);

    GapPrice = Array1[0];

    if(Array1[0] != EMPTY_VALUE)
    {
        return true;
    }

    return false;

}

void TakeTrade() 
{
    if(PositionsTotal()) { return ; }

    MqlTick ticks[];

    CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, 0, 3);

    if(TradeEntry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        if(TradePrice > 0 && ticks[1].ask <= TradePrice && ticks[0].ask >= TradePrice)
        {
            double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
            trade.Buy(TradeLotsize, Symbol(), ask, TradeSL, TradeTP);
            TradePrice = -1;
        }
    }

    if(TradeEntry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        
        if(TradePrice > 0 && ticks[1].bid >= TradePrice && ticks[0].bid <= TradePrice)
        {
            double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
            trade.Sell(TradeLotsize, Symbol(), bid, TradeSL, TradeTP);
            TradePrice = -1;
        }
    }

}

void SetTrade(ENUM_MARKET_ENTRY Entry) 
{
    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double close                            = iClose(Symbol(), Period(), 1);
        double available_pip                    = GapPrice - close;
        double gap_percentile_entry             = available_pip * (GapPercentileEntry / 100.0);
        double gap_percentile_exit              = available_pip * (GapPercentileExit / 100.0);
        double entry_price                      = close + gap_percentile_entry;
        double exit_price                       = GapPrice - gap_percentile_exit;
        double trade_pip                        = exit_price - entry_price;
        TradeLotsize                            = NormalizeDouble(riskAmount / ((MathPow(10, _Digits) * trade_pip)), 2);
        TradeSL			                        = NormalizeDouble(entry_price - trade_pip, _Digits);
        TradeTP                                 = NormalizeDouble(entry_price + trade_pip, _Digits);
        TradePrice                              = entry_price;
        TradeEntry                              = MARKET_ENTRY_LONG;
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double close                            = iClose(Symbol(), Period(), 1);
        double available_pip                    = close - GapPrice;
        double gap_percentile_entry             = available_pip * (GapPercentileEntry / 100.0);
        double gap_percentile_exit              = available_pip * (GapPercentileExit / 100.0);
        double entry_price                      = close - gap_percentile_entry;
        double exit_price                       = GapPrice + gap_percentile_exit;
        double available_point                  = entry_price - exit_price;
        TradeLotsize                            = NormalizeDouble(riskAmount / ((MathPow(10, _Digits) * available_point)), 2);
        TradeSL	   		                        = NormalizeDouble(entry_price + available_point, _Digits);
        TradeTP                                 = NormalizeDouble(entry_price - available_point, _Digits);
        TradePrice                              = entry_price;
        TradeEntry                              = MARKET_ENTRY_SHORT;
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

            close_all_orders();

            // TakeTrade(m_deal.Price());
        }
    }
}

/* ##################################################### Cover Trade ##################################################### */
// void TakeCoverTrade(ENUM_MARKET_ENTRY Entry) {

//     if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
//         double ask          = SupportZoneLow;
//         double sl			= NormalizeDouble(ask + CoverStopLoss * _Point, _Digits) * (CoverStopLoss > 0);
//         double tp			= NormalizeDouble(ask - CoverTakeProfit * _Point, _Digits) * (CoverTakeProfit > 0);
//         trade.SetExpertMagicNumber(EXPERT_MAGIC);
//         trade.SellStop(CoverLotSize, ask, Symbol(), sl, tp);
//     }

//     if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
//         double bid          = ResistantZoneHigh;
//         double sl			= NormalizeDouble(bid - CoverStopLoss * _Point, _Digits) * (CoverStopLoss > 0);
//         double tp			= NormalizeDouble(bid + CoverTakeProfit * _Point, _Digits) * (CoverTakeProfit > 0);
//         trade.SetExpertMagicNumber(EXPERT_MAGIC);
//         trade.BuyStop(CoverLotSize, bid, Symbol(), sl, tp);
//     }
// }

/* ##################################################### Recovery ##################################################### */
// void TakeRecoveryTrade(ENUM_MARKET_ENTRY Entry) {

//     double dealLost = getPreviousDealLost() / -1;

//     if(dealLost <= 0) { return ; }

//     double RecoveryLotSize = NormalizeDouble(dealLost / RecoveryTakeProfit, _Digits);

//     if(RecoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { RecoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
//     if(RecoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { RecoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

//     if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
//         double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
//         double sl			= NormalizeDouble(ask - RecoveryStopLoss * _Point, _Digits) * (RecoveryStopLoss > 0);
//         double tp			= NormalizeDouble(ask + RecoveryTakeProfit * _Point, _Digits) * (RecoveryTakeProfit > 0);
//         trade.SetExpertMagicNumber(EXPERT_MAGIC);
//         trade.Buy(RecoveryLotSize, Symbol(), ask, sl, tp, "Recovery");
//     }

//     if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {

//         double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
//         double sl			= NormalizeDouble(bid + RecoveryStopLoss * _Point, _Digits) * (RecoveryStopLoss > 0);
//         double tp			= NormalizeDouble(bid - RecoveryTakeProfit * _Point, _Digits) * (RecoveryTakeProfit > 0);
//         trade.SetExpertMagicNumber(EXPERT_MAGIC);
//         trade.Sell(RecoveryLotSize, Symbol(), bid, sl, tp, "Recovery");
//     }
// }

// double getPreviousDealLost() {

//     ulong dealTicket;
//     double dealProfit;
//     string dealSymbol;
//     double dealLost = 0;

//     HistorySelect(0,TimeCurrent());

//     for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

//         dealTicket = HistoryDealGetTicket(i);
//         dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
//         dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

//         if(dealSymbol != Symbol()) { continue; }

//         if(dealProfit < 0) { dealLost = dealLost + dealProfit; }

//         if(dealProfit > 0) { break; }

//     }

//     return dealLost;
// }

