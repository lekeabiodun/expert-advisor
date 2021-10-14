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
input int                                           MaxSpread = 1; // Max Spread to trade
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

double SupportZoneHigh;
double SupportZoneLow;
double ResistantZoneHigh;
double ResistantZoneLow;

double PrevTradeZoneHigh;
double PrevTradeZoneLow;

void OnTick() 
{
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    if(spread > MaxSpread) { return; }
    
    int new_zone = NewZone();

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
input int                                           Text_size=8;                       // Text Size
input string                                        Text_font = "Courier New";      // Text Font
input color                                         Text_color = clrWhite;           // Text Color
input string                                        Sup_name = "Sup";               // Support Name
input string                                        Res_name = "Res";               // Resistance Name
input string                                        Test_name= "Retests";           // Test Name
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

int NewZone()
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
    
    if(Close[0] >= ResistantZoneLow && Close[0] < ResistantZoneHigh)
    {
        return 4;
    }
    
    if(Close[0] <= SupportZoneHigh && Close[0] > SupportZoneLow)
    {
        return 5;
    }

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
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
    }

}

