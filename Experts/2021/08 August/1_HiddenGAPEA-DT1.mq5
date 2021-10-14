
input double GapPercentage = 100.0;

int OnInit() 
{
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
    Print("Total days: ", TotalDays);
    Print("Total Candles: ", TotalCandles);
    Print("Total Gap Candles : ", TotalGapCandles);
    Print("Total Candles That Pass Tested Conditions, Candles That Move: ", GapPercentage, "% Towards Gap Dot: ", TotalTestedGapPassCandles);

    Print("Total Number of Days That Has No Pass Tested Condition: ", TotalDaysWithoutGapPassCandles);

    // Print("No Gap Found in Period: ", NoGapFound);
    // Print("Maximum Gap in Period: ", maxCounter);
    // Print("Minimum Daily: ", minCounter);

}


double GapPrice;
bool GapLastDecision = false;

int TotalCandles = 0;
int TotalGapCandles = 0;
int TotalTestedGapPassCandles = 0;

void OnTick() 
{

    if(!TradingPeriod()) { return ; }

    if(!Latency()) { return ; }

    daysCounter();

    TotalCandles = TotalCandles + 1;

    if(!FindNewGAP()) { return; }

    TotalGapCandles = TotalGapCandles + 1;

    if(GapFound == -1) { GapFound = 0; }
    
    GapFound = GapFound + 1;

    if(iClose(Symbol(), Period(), 2) > iOpen(Symbol(), Period(), 2)) {

        double open = iOpen(Symbol(), Period(), 1);

        double percent = (open - GapPrice) * (GapPercentage/100.0);

        if(iLow(Symbol(), Period(), 1) <= (open - percent)) {
            TotalTestedGapPassCandles = TotalTestedGapPassCandles + 1;
            if(PassGapFound == -1) { PassGapFound = 0; }
            PassGapFound = PassGapFound + 1;
        }
    
    }

    if(iClose(Symbol(), Period(), 2) < iOpen(Symbol(), Period(), 2)) {

        double open = iOpen(Symbol(), Period(), 1);

        double percent = (GapPrice - open) * (GapPercentage/100.0);

        if(iHigh(Symbol(), Period(), 1) >= (open + percent)) {

            TotalTestedGapPassCandles = TotalTestedGapPassCandles + 1;
            if(PassGapFound == -1) { PassGapFound = 0; }
            PassGapFound = PassGapFound + 1;
        }
    
    }
    // Print("GAP FOUND: ", GapFound);
    PeriodSignalCounter();

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

int GapHandle = iCustom(NULL, Period(), "HiddenGap", UseWholeBars, WRB_LookBackBarCount, WRB_WingDingsSymbol, HGColor1, HGColor2, HGStyle, StartCalculationFromBar, HollowBoxes, DoAlerts);

bool FindNewGAP()
{
    double Array1[];

    ArraySetAsSeries(Array1, true);

    CopyBuffer(GapHandle, 0, 2, 2, Array1);

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
    LatencyCandleTime = iTime(Symbol(), Period(), 0);
    
    if(LatencyTimestamp != LatencyCandleTime) {

        LatencyTimestamp = LatencyCandleTime;

        return true;
    }

    return false;
}

input group                                         "============ Trade Period Settings ===============";
input bool                                          useTradingTimePeriod = true; // Use Trading Time Period
input int                                           tradeStartHour = 1; // Trade Period Start Hour
input int                                           tradeEndHour = 23; // Trade Period End Hour
input int                                           tradeStartDayOfWeek = 0; // Trade Period Start Day of Week
input int                                           tradeEndDayOfWeek = 6; // Trade Period End Day of Week
input int                                           tradeStartDay = 1; // Trade Period Start Day
input int                                           tradeEndDay = 30; // Trade Period End Day

bool TradingPeriod()
{
    if(!useTradingTimePeriod) { return true; }

    MqlDateTime tradePeriodCurrentTime;

    TimeToStruct(TimeCurrent(), tradePeriodCurrentTime);
    
    if(tradePeriodCurrentTime.hour < tradeStartHour) { return false; }

    if(tradePeriodCurrentTime.hour > tradeEndHour) { return false; }
    
    if(tradePeriodCurrentTime.day_of_week < tradeStartDayOfWeek) { return false; }

    if(tradePeriodCurrentTime.day_of_week > tradeEndDayOfWeek) { return false; }
    
    if(tradePeriodCurrentTime.day < tradeStartDay) { return false; }

    if(tradePeriodCurrentTime.day > tradeEndDay) { return false; }

    return true;
}

input group                                         "============  Max Period Signal Settings ===============";
input ENUM_TIMEFRAMES                               SignalFrequency = PERIOD_D1; // Frequency

datetime PeriodicTime = iTime(Symbol(), SignalFrequency, 0);

int maxCounter = 0;
int minCounter = 8000;
int GapFound = -1;
int PassGapFound = -1;
int TotalDaysWithoutGapPassCandles = 0;

void PeriodSignalCounter()
{
    datetime CurrentTime = iTime(Symbol(), SignalFrequency, 0);

    if(CurrentTime != PeriodicTime) {

        PeriodicTime = CurrentTime;

        maxCounter = MathMax(maxCounter, GapFound);
        minCounter = MathMin(minCounter, GapFound);

        if(PassGapFound == 0) {
            TotalDaysWithoutGapPassCandles = TotalDaysWithoutGapPassCandles + 1;
            Print("FAIL: ", TimeCurrent());
        }

        GapFound = 0;
        PassGapFound = 0;
    }
}

int TotalDays = 0;
ENUM_TIMEFRAMES Daily = PERIOD_D1;
datetime DailyTime = iTime(Symbol(), Daily, 0);

void daysCounter()
{
    datetime CurrentTime = iTime(Symbol(), Daily, 0);

    if(CurrentTime != DailyTime) {
        DailyTime = CurrentTime;
        TotalDays = TotalDays + 1;
    }
}
