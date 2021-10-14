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
input group                                         "============  Recovery Settings ===============";
input double                                        RecoveryStopLoss = 0.0; // Recovery Stop Loss in Pips
input double                                        RecoveryTakeProfit = 0.0; // Recovery Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          ExpertIsTakingRecovery = false; // Take Recovery

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
    
    int trend_line_break = TrendLineBreak();

    if(trend_line_break < 1) { return; }

    if(trend_line_break == 1)
    {
        TakeTrade(MARKET_ENTRY_LONG);
    }

    if(trend_line_break == 2)
    {
        TakeTrade(MARKET_ENTRY_SHORT);
    }

}

input group                                         "============  Indicator Settings  ===============";
input int    LevDP=2;         // Fractal Period or Levels Demar Pint
input int    qSteps=1;       // Number  Trendlines per UpTrend or DownTrend
input int    BackStep=0;    // Number of Steps Back
input int    showBars=500; // Bars Back To Draw
input int    ArrowCode=159;
input color  UpTrendColor=clrDarkBlue;
input color  DownTrendColor=clrFireBrick;
input int    TrendlineWidth=1;
input ENUM_LINE_STYLE TrendlineStyle=STYLE_SOLID;
input string  UniqueID  = "TrendLINE"; // Indicator unique ID

int TrendLineHandle = iCustom(NULL, Period(), "DemarkTrendLine", LevDP, qSteps, BackStep, showBars, ArrowCode, UpTrendColor, DownTrendColor, TrendlineWidth, TrendlineStyle, UniqueID);

int TrendLineBreak()
{
    int level = -1;

    string UpTrendLine = UniqueID+" Up "+IntegerToString(1);
    string DownTrendLine = UniqueID+" Down "+IntegerToString(1);

    double UpTrendValue = GetTrend(UpTrendLine);
    double DownTrendValue = GetTrend(DownTrendLine);
    
    if(DownTrendValue>0)
    {
        if(iOpen(Symbol(), Period(), 0) >= DownTrendValue && iOpen(Symbol(), Period(), 1) < DownTrendValue)
        {
            level = 1;
        }        
    }

    if(UpTrendValue>0)
    {

        if(iOpen(Symbol(), Period(), 0) <= UpTrendValue && iOpen(Symbol(), Period(), 1) > UpTrendValue)
        {
            level = 2;
        }       
    }

    return level;

}

double GetTrend(string trend_name)
{
   for(int cnt=0; cnt<ObjectsTotal(0); cnt++)
   {
      string objName = ObjectName(0,cnt);
      
      if(StringFind(objName,trend_name)>-1)
      {
         return(ObjectGetValueByTime(0,objName,TimeCurrent()));
      }      
   }
   return(0);
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
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
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
