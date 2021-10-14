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

input group                                         "============  TrendLine Filter Settings  ===============";
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

    if(!ShvedZoneFilter()) { return level; }
    
    // double Array1[], Array2[], Array3[], Array4[], Array5[], Array6[], Array7[], Array8[];

    string UpTrendLine = UniqueID+" Up "+IntegerToString(1);
    string DownTrendLine = UniqueID+" Down "+IntegerToString(1);

    double UpTrendValue = GetTrend(UpTrendLine);
    double DownTrendValue = GetTrend(DownTrendLine);

    // Print("Up Trend Value: ", UpTrendValue);
    // Print("Down Trend Value: ", DownTrendValue);

    // Comment("Trend Line("+TrendLineName+") value = "+DoubleToString(TrendValue,_Digits));
    
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

    // ArraySetAsSeries(Array1, true);
    // ArraySetAsSeries(Array2, true);
    // ArraySetAsSeries(Array3, true);
    // ArraySetAsSeries(Array4, true);
    // ArraySetAsSeries(Array5, true);
    // ArraySetAsSeries(Array6, true);
    // ArraySetAsSeries(Array7, true);
    // ArraySetAsSeries(Array8, true);

    // CopyBuffer(TrendLineHandle, 0, 1, 2, Array1);
    // CopyBuffer(TrendLineHandle, 1, 1, 2, Array2);
    // CopyBuffer(TrendLineHandle, 2, 1, 2, Array3);
    // CopyBuffer(TrendLineHandle, 3, 1, 2, Array4);

    // CopyBuffer(TrendLineHandle, 4, 1, 2, Array5);
    // CopyBuffer(TrendLineHandle, 5, 1, 2, Array6);

    // CopyBuffer(TrendLineHandle, 6, 1, 2, Array7);
    // CopyBuffer(TrendLineHandle, 7, 1, 2, Array8);

    // Print("Array1: ", Array1[0]);
    // Print("Array2: ", Array2[0]);
    // Print("Array3: ", Array3[0]);
    // Print("Array4: ", Array4[0]);
    // Print("Array5: ", Array5[0]);
    // Print("Array6: ", Array6[0]);
    // Print("Array7: ", Array7[0]);
    // Print("Array8: ", Array8[0]);

    // ResistantZoneHigh = Array5[0];
    // ResistantZoneLow = Array6[0];
    // SupportZoneHigh = Array7[0];
    // SupportZoneLow = Array8[0];
    
    // double Close[];

    // ArraySetAsSeries(Close, true);

    // CopyClose(Symbol(), 0, 0, 1, Close);

    // check for entries
    
    // if(Close[0] >= ResistantZoneLow && Close[0] < ResistantZoneHigh)
    // {
    //     return 4;
    // }
    
    // if(Close[0] <= SupportZoneHigh && Close[0] > SupportZoneLow)
    // {
    //     return 5;
    // }

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

input group                                         "============  Shved Filter Settings  ===============";
input bool                                          UseShvedFilter = false; // Use Shved Filter
input ENUM_TIMEFRAMES                               ShvedFilterPeriod = PERIOD_CURRENT; // Shved Filter Period
input int                                           Filter_CandlePeriod = 1000; // Back Limit
input bool                                          Filter_HistoryMode = false; // History Mode
input string                                        Filter_Pus1 = "/////////////////////////////////////////////////"; // Pus1
input bool                                          Filter_ShowWeakZone = true; // Show Weak Zone
input bool                                          Filter_ShowUntestedZone = true; // Show Untested Zone
input bool                                          Filter_ShowBrokenZone = true; // Show Broken Zone
input double                                        Filter_ZoneATRFactor = 0.75; // Zone ATR Factor
input string                                        Filter_Pus2 = "/////////////////////////////////////////////////"; // Pus2
input int                                           Filter_FractalFastFactor = 3; // Fractal Fast Factor
input int                                           Filter_FractalSlowFactor = 6; // Fractal Slow Factor
input bool                                          Filter_SetTerminalGlobalVariable = false; // Set Terminal Global Variable
input string                                        Filter_Pus3 = "/////////////////////////////////////////////////"; // Pus3
input bool                                          Filter_FillZone = true; // Fill Zone With Colors
input int                                           Filter_ZoneBorderWidth = 1; // Zone Border Width
input ENUM_LINE_STYLE                               Filter_ZoneBorderStyle = STYLE_SOLID; // Zone Border Style
input bool                                          Filter_ShowLabels = true; // Show Info Labels
input int                                           Filter_LabelShift = 10; // Infor Label Shift
input bool                                          Filter_ZoneMerge = true; // Zone Merge
input bool                                          Filter_ZoneExtend = true; // Zone Extend
input string                                        Filter_Pus4 = "/////////////////////////////////////////////////"; // 
input bool                                          Filter_TriggerAlert = true; // Trigger Alert When Entering a Zone
input bool                                          Filter_ShowAlert = true; // Show Alert Window
input bool                                          Filter_PlaySound = true; // Play Alert Sound
input bool                                          Filter_SendNotification = true; // Send Notification When Entering a Zone
input int                                           Filter_DelayBetweenAlert = 300; // Delay Between Alerts(seconds)
input string                                        Filter_Pus5="/////////////////////////////////////////////////";
input int                                           Filter_Text_size=8;                       // Text Size
input string                                        Filter_Text_font = "Courier New";      // Text Font
input color                                         Filter_Text_color = clrBlack;           // Text Color
input string                                        Filter_Sup_name = "Sup";               // Support Name
input string                                        Filter_Res_name = "Res";               // Resistance Name
input string                                        Filter_Test_name= "Retests";           // Test Name
input color                                         Filter_Color_support_weak     = clrDarkSlateGray;         // Color for weak support zone
input color                                         Filter_Color_support_untested = clrSeaGreen;              // Color for untested support zone
input color                                         Filter_Color_support_verified = clrGreen;                 // Color for verified support zone
input color                                         Filter_Color_support_proven   = clrLimeGreen;             // Color for proven support zone
input color                                         Filter_Color_support_turncoat = clrOliveDrab;             // Color for turncoat(broken) support zone
input color                                         Filter_Color_resist_weak      = clrIndigo;                // Color for weak resistance zone
input color                                         Filter_Color_resist_untested  = clrOrchid;                // Color for untested resistance zone
input color                                         Filter_Color_resist_verified  = clrCrimson;               // Color for verified resistance zone
input color                                         Filter_Color_resist_proven    = clrRed;                   // Color for proven resistance zone
input color                                         Filter_Color_resist_turncoat  = clrDarkOrange;            // Color for broken resistance zone

int SHVEDFilterHandle = iCustom(NULL, ShvedFilterPeriod, "Shved", Filter_CandlePeriod, Filter_HistoryMode, Filter_Pus1, Filter_ShowWeakZone, Filter_ShowUntestedZone, Filter_ShowBrokenZone, Filter_ZoneATRFactor, Filter_Pus2, Filter_FractalFastFactor, Filter_FractalSlowFactor, Filter_SetTerminalGlobalVariable, Filter_Pus3, Filter_FillZone, Filter_ZoneBorderWidth, Filter_ZoneBorderStyle, Filter_ShowLabels, Filter_LabelShift, Filter_ZoneMerge, Filter_ZoneExtend, Filter_Pus4, Filter_TriggerAlert, Filter_ShowAlert, Filter_PlaySound, Filter_SendNotification, Filter_DelayBetweenAlert, Filter_Pus5, Filter_Text_size, Filter_Text_font, Filter_Text_color, Filter_Sup_name, Filter_Res_name, Filter_Test_name, Filter_Color_support_weak, Filter_Color_support_untested, Filter_Color_support_verified, Filter_Color_support_proven, Filter_Color_support_turncoat, Filter_Color_resist_weak, Filter_Color_resist_untested, Filter_Color_resist_verified, Filter_Color_resist_proven, Filter_Color_resist_turncoat);

bool ShvedZoneFilter()
{
    if(!UseShvedFilter) { return true; }
    
    double Array5[], Array6[], Array7[], Array8[];

    ArraySetAsSeries(Array5, true);
    ArraySetAsSeries(Array6, true);
    ArraySetAsSeries(Array7, true);
    ArraySetAsSeries(Array8, true);

    CopyBuffer(SHVEDFilterHandle, 4, 1, 2, Array5);
    CopyBuffer(SHVEDFilterHandle, 5, 1, 2, Array6);

    CopyBuffer(SHVEDFilterHandle, 6, 1, 2, Array7);
    CopyBuffer(SHVEDFilterHandle, 7, 1, 2, Array8);
    
    double Close[];

    ArraySetAsSeries(Close, true);

    CopyClose(Symbol(), 0, 0, 1, Close);
    
    if(Close[0] >= Array6[0] && Close[0] < Array5[0])
    {
        return true;
    }
    
    if(Close[0] <= Array7[0] && Close[0] > Array8[0])
    {
        return true;
    }

    return false;

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
        // if(ExpertIsTakingCover) { TakeCoverTrade(MARKET_ENTRY_LONG); }
        // if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
        // if(ExpertIsTakingCover) { TakeCoverTrade(MARKET_ENTRY_SHORT); }
        // if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
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
