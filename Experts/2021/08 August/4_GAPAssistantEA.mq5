
input double GapPercentage = 100.0; // Gap Percentage
input ENUM_TIMEFRAMES ExpertTimeFrame = PERIOD_H1; // Timeframe

int OnInit() 
{
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{

}

double GapPrice;
bool GapLastDecision = false;
int clrname = clrRed;

void OnTick() 
{

    if(!Latency()) { return ; }

    if(!FindNewGAP()) { return; }

    // Print("GAP Found");

    if(iClose(Symbol(), ExpertTimeFrame, 1) > iOpen(Symbol(), ExpertTimeFrame, 1)) { clrname = clrRed; }

    if(iClose(Symbol(), ExpertTimeFrame, 1) < iOpen(Symbol(), ExpertTimeFrame, 1)) { clrname = clrGreen; }

    ObjectDelete(0, "VLine");
    ObjectDelete(0, "HLine");
    ObjectDelete(0, "PLine");

    ObjectCreate(0, "VLine", OBJ_VLINE, 0, TimeCurrent(), GapPrice);
    ObjectSetInteger(0, "VLine", OBJPROP_COLOR, clrname);
    ObjectSetInteger(0, "VLine", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "VLine", OBJPROP_BACK, true);
    // ObjectSetString(0, "VLine", OBJPROP_NAME, "Vertical Line");
    // ObjectSetString(0, "VLine", OBJPROP_TEXT, "Vertical Line");
    // ObjectSetString(0, "VLine", OBJPROP_TOOLTIP, "Vertical Line");
    // ObjectSetString(0, "VLine", OBJPROP_LEVELTEXT, "Vertical Line");

    ObjectCreate(0, "HLine", OBJ_HLINE, 0, TimeCurrent(), GapPrice);
    ObjectSetInteger(0, "HLine", OBJPROP_COLOR, clrname);
    ObjectSetInteger(0, "HLine", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, "HLine", OBJPROP_BACK, true);
    // ObjectSetString(0, "HLine", OBJPROP_NAME, "Horizontal Line");
    // ObjectSetString(0, "HLine", OBJPROP_TEXT, "Horizontal Line");
    // ObjectSetString(0, "HLine", OBJPROP_TOOLTIP, "Horizontal Line");
    // ObjectSetString(0, "HLine", OBJPROP_LEVELTEXT, "Horizontal Line");

    if(iClose(Symbol(), ExpertTimeFrame, 1) > iOpen(Symbol(), ExpertTimeFrame, 1)) {

        double open = iOpen(Symbol(), ExpertTimeFrame, 0);

        double percent = (open - GapPrice) * (GapPercentage/100.0);

        double price = open - percent;

        // Print("ZELL: ", price);
        
        ObjectCreate(0, "PLine", OBJ_HLINE, 0, TimeCurrent(), price);
        ObjectSetInteger(0, "PLine", OBJPROP_COLOR, clrGold);
        ObjectSetInteger(0, "PLine", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, "PLine", OBJPROP_BACK, true);
        // ObjectSetString(0, "PLine", OBJPROP_NAME, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_TEXT, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_TOOLTIP, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_LEVELTEXT, "Percentage Line");
    
    }

    if(iClose(Symbol(), ExpertTimeFrame, 1) < iOpen(Symbol(), ExpertTimeFrame, 1)) {

        double open = iOpen(Symbol(), ExpertTimeFrame, 0);

        double percent = (GapPrice - open) * (GapPercentage/100.0);

        double price = open + percent;

        // Print("BUY: ", price);
        
        ObjectCreate(0, "PLine", OBJ_HLINE, 0, TimeCurrent(), price);
        ObjectSetInteger(0, "PLine", OBJPROP_COLOR, clrGold);
        ObjectSetInteger(0, "PLine", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, "PLine", OBJPROP_BACK, true);
        // ObjectSetString(0, "PLine", OBJPROP_NAME, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_TEXT, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_TOOLTIP, "Percentage Line");
        // ObjectSetString(0, "PLine", OBJPROP_LEVELTEXT, "Percentage Line");
    
    }
    
    // ObjectMove(0, "Line1", 0, TimeCurrent(), GapPrice);


}

input group                                         "============  WRB Hidden Gap Settings  ===============";
input bool                                          UseWholeBars = 3;                // UseWholeBars
input int                                           WRB_LookBackBarCount = 3;        // WRB_LookBackBarCount
input int                                           WRB_WingDingsSymbol = 115;       // WRB_WingDingsSymbol
input color                                         HGColor1 = clrDodgerBlue;        // HGColor1
input color                                         HGColor2 = clrBlue;              // HGColor2
input ENUM_LINE_STYLE                               HGStyle = STYLE_SOLID;           //HGStyle
input int                                           StartCalculationFromBar = 100;   // StartCalculationFromBar
input bool                                          HollowBoxes = false;             // HollowBoxes
input bool                                          DoAlerts = false;                //DoAlerts

int GapHandle = iCustom(NULL, ExpertTimeFrame, "HiddenGap", UseWholeBars, WRB_LookBackBarCount, WRB_WingDingsSymbol, HGColor1, HGColor2, HGStyle, StartCalculationFromBar, HollowBoxes, DoAlerts);

bool FindNewGAP()
{
    double Array1[];

    ArraySetAsSeries(Array1, true);

    CopyBuffer(GapHandle, 0, 1, 2, Array1);

    GapPrice = Array1[0];
    
    if(Array1[0] == EMPTY_VALUE)
    {
        GapLastDecision = false;

        return false;
    }

    GapLastDecision = true;

    return true;

}

datetime LatencyCandleTime;
static datetime LatencyTimestamp;

bool Latency()
{
    LatencyCandleTime = iTime(Symbol(), ExpertTimeFrame, 0);
    
    if(LatencyTimestamp != LatencyCandleTime) {

        LatencyTimestamp = LatencyCandleTime;

        return true;
    }

    return false;
}
