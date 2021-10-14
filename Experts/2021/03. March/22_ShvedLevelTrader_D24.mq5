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
input double                                        InputLotSize = 1; // Lot Size
input double                                        InputStopLoss = 0.0; // Stop Loss in Pips
input double                                        InputTakeProfit = 0.0; // Take Profit in Pips
input int                                           InputMaxTargetPip = 100; // Max Target Pip to trade
input int                                           InputMaxSpread = 10; // Max Spread to trade
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

int OnInit() 
{
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

double PrevSellZoneHigh;
double PrevSellZoneLow;

double PrevBuyZoneHigh;
double PrevBuyZoneLow;

double PrevBuyZones[10];

void OnTick() 
{
    

    return;
    if(SpreadIsHigh()) { return; }

    if(RunAwayProfitTargetHit()) { return; }
    
    ScanZone();

    if(PrevBuyZoneHigh != ResistantZoneHigh && PrevBuyZoneLow != ResistantZoneLow)
    {
        PrevBuyZoneHigh = ResistantZoneHigh;
        PrevBuyZoneLow = ResistantZoneLow;

        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        if(ResistantZoneLow - ask > InputMaxTargetPip) { return; }

        TakeTrade(MARKET_ENTRY_LONG);
    }

    if(PrevSellZoneHigh != SupportZoneHigh && PrevSellZoneLow != SupportZoneLow)
    {
        PrevSellZoneHigh  = SupportZoneHigh;
        PrevSellZoneLow   = SupportZoneLow;
        double bid        = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        if(bid - SupportZoneHigh > InputMaxTargetPip) { return; }

        TakeTrade(MARKET_ENTRY_SHORT);
    }

}

input group                                         "============  Shved Settings  ===============";
input int                                           CandlePeriod = 1000; // Back Limit
input bool                                          HistoryMode = false; // History Mode
input string                                        Pus1 = "/////////////////////////////////////////////////"; // Pus1
input bool                                          ShowWeakZone = true; // Show Weak Zone
input bool                                          ShowUntestedZone = true; // Show Untested Zone
input bool                                          ShowBrokenZone = true; // Show Broken Zone
input double                                        ZoneATRFactor = 0.75; // Zone ATR Factor
input string                                        Pus2 = "/////////////////////////////////////////////////"; // Pus2
input int                                           FractalFastFactor = 3; // Fractal Fast Factor
input int                                           FractalSlowFactor = 6; // Fractal Slow Factor
input bool                                          SetTerminalGlobalVariable = false; // Set Terminal Global Variable
input string                                        Pus3 = "/////////////////////////////////////////////////"; // Pus3
input bool                                          FillZone = true; // Fill Zone With Colors
input int                                           ZoneBorderWidth = 1; // Zone Border Width
input ENUM_LINE_STYLE                               ZoneBorderStyle = STYLE_SOLID; // Zone Border Style
input bool                                          ShowLabels = true; // Show Info Labels
input int                                           LabelShift = 10; // Infor Label Shift
input bool                                          ZoneMerge = true; // Zone Merge
input bool                                          ZoneExtend = true; // Zone Extend
input string                                        Pus4 = "/////////////////////////////////////////////////"; // 
input bool                                          TriggerAlert = true; // Trigger Alert When Entering a Zone
input bool                                          ShowAlert = true; // Show Alert Window
input bool                                          PlaySound = true; // Play Alert Sound
input bool                                          SendNotification = true; // Send Notification When Entering a Zone
input int                                           DelayBetweenAlert = 300; // Delay Between Alerts(seconds)
input string                                        Pus5="/////////////////////////////////////////////////";
input int                                           Text_size = 8;                       // Text Size
input string                                        Text_font = "Courier New";      // Text Font
input color                                         Text_color = clrWhite;           // Text Color
input string                                        Sup_name = "Sup";               // Support Name
input string                                        Res_name = "Res";               // Resistance Name
input string                                        Test_name = "Retests";           // Test Name
input color                                         Color_support_weak     = clrDarkSlateGray;         // Color for weak support zone
input color                                         Color_support_untested = clrSeaGreen;              // Color for untested support zone
input color                                         Color_support_verified = clrGreen;                 // Color for verified support zone
input color                                         Color_support_proven   = clrLimeGreen;             // Color for proven support zone
input color                                         Color_support_turncoat = clrOliveDrab;             // Color for turncoat(broken) support zone
input color                                         Color_resist_weak      = clrIndigo;                // Color for weak resistance zone
input color                                         Color_resist_untested  = clrOrchid;                // Color for untested resistance zone
input color                                         Color_resist_verified  = clrCrimson;               // Color for verified resistance zone
input color                                         Color_resist_proven    = clrRed;                   // Color for proven resistance zone
input color                                         Color_resist_turncoat  = clrDarkOrange;            // Color for broken resistance zone

int SHVEDHandle = iCustom(NULL, Period(), "Shved", CandlePeriod, HistoryMode, Pus1, ShowWeakZone, ShowUntestedZone, ShowBrokenZone, ZoneATRFactor, Pus2, FractalFastFactor, FractalSlowFactor, SetTerminalGlobalVariable, Pus3, FillZone, ZoneBorderWidth, ZoneBorderStyle, ShowLabels, LabelShift, ZoneMerge, ZoneExtend, Pus4, TriggerAlert, ShowAlert, PlaySound, SendNotification, DelayBetweenAlert, Pus5, Text_size, Text_font, Text_color, Sup_name, Res_name, Test_name, Color_support_weak, Color_support_untested,Color_support_verified, Color_support_proven, Color_support_turncoat, Color_resist_weak, Color_resist_untested, Color_resist_verified, Color_resist_proven, Color_resist_turncoat);

int ScanZone()
{
    double Array5[], Array6[], Array7[], Array8[];

    ArraySetAsSeries(Array5, true);
    ArraySetAsSeries(Array6, true);
    ArraySetAsSeries(Array7, true);
    ArraySetAsSeries(Array8, true);

    CopyBuffer(SHVEDHandle, 4, 1, 2, Array5);
    CopyBuffer(SHVEDHandle, 5, 1, 2, Array6);

    CopyBuffer(SHVEDHandle, 6, 1, 2, Array7);
    CopyBuffer(SHVEDHandle, 7, 1, 2, Array8);

    ResistantZoneHigh = Array5[0];
    ResistantZoneLow = Array6[0];
    SupportZoneHigh = Array7[0];
    SupportZoneLow = Array8[0];

    return 1;

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
        double sl			= NormalizeDouble(ask - InputStopLoss * _Point, _Digits) * (InputStopLoss > 0);
        double tp			= NormalizeDouble(ask + InputTakeProfit * _Point, _Digits) * (InputTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(InputLotSize, Symbol(), ask, sl, ResistantZoneLow);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + InputStopLoss * _Point, _Digits) * (InputStopLoss > 0);
        double tp			= NormalizeDouble(bid - InputTakeProfit * _Point, _Digits) * (InputTakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(InputLotSize, Symbol(), bid, sl, SupportZoneHigh);
    }

}


//+------------------------------------------------------------------+
//| HigherTimeframeSignal function                                   |
//+------------------------------------------------------------------+
bool SpreadIsHigh()
{
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(spread > InputMaxSpread) 
    {
        return true;
    }

    return false;
}


//+------------------------------------------------------------------+
//| Run Away function                                        |
//+------------------------------------------------------------------+
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          ExpertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               RunAwayProfitFrequency = PERIOD_D1; // Frequency
input int                                           RunAwayProfitTarget = 15; // Profit Target
input int                                           RunAwayLossTarget = 15; // Loss Target

datetime RunAwayCandleTime = iTime(Symbol(), RunAwayProfitFrequency, 0);

double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
double AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

bool RunAwayProfitTargetHit()
{
    if(!ExpertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), RunAwayProfitFrequency, 0);

    if(freq != RunAwayCandleTime) {
        RunAwayCandleTime = freq;
        AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        return false;
    }

    double CurrentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(CurrentEquity - AccountBalance >= RunAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(CurrentEquity - AccountBalance <= -RunAwayLossTarget) { 
        close_all_positions(); 
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


