enum ENUM_BIAS      { BULLISH, BEARISH };
// input int           CandlesBeforeBias = 9; // Candles of the day before bias
double              ReverseCandle = 0.0;
bool                ExpertStart = false;
ENUM_BIAS           ExpertBias = BULLISH;
input double        ExpectedWick = 45;

double spread_point = 0.0;


int OnInit() {
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
    Print("Total days: ", TotalDays);
    Print("Reverse candles: ", ReverseCandle);
    Print("Percentage: ", ((ReverseCandle/TotalDays) * 100.0), " %");
    Print("Max Spread: ", spread_point);
}

void OnTick() 
{

    if(!TradingPeriod()) { return ; }

    if(!Latency()) { return ; }

    // Print("Max Spread: ", iSpread(Symbol(), Period(), 0));
    // Print("Spread Point: ", spread_point);

    spread_point = MathMax(spread_point, iSpread(Symbol(), Period(), 0));

    daysCounter();

    if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && !ExpertStart) {
        ExpertBias = BEARISH;
        ExpertStart = true;
        datetime dtime = TimeCurrent(); 
        ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
        ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrRed);

        return;
    }

    if(iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) && !ExpertStart) {
        ExpertBias = BULLISH;
        ExpertStart = true;
        datetime dtime = TimeCurrent(); 
        ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
        ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrGreen);

        return;
    }

    // ---- 

    if(!ExpertStart) { return ; }

    if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && ExpertBias == BULLISH) {
        
        ReverseCandle = ReverseCandle + 1.0;
        datetime dtime = TimeCurrent(); 
        ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
        ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrYellow);

    }

    if(iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) && ExpertBias == BEARISH) {

        ReverseCandle = ReverseCandle + 1.0;
        datetime dtime = TimeCurrent(); 
        ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
        ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrYellow);

    }

    // ---

    if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && ExpertBias == BEARISH) {
        
        double wickU = iHigh(Symbol(), Period(), 1) - iClose(Symbol(), Period(), 1);
        double wickD = iOpen(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1);

        if(wickU >= NormalizeDouble(ExpectedWick * _Point, _Digits) || wickD >= NormalizeDouble(ExpectedWick * _Point, _Digits)) {
            // Print("WICKU: ", wickU, " WICKD: ", wickD);
            ReverseCandle = ReverseCandle + 1.0;
            datetime dtime = TimeCurrent(); 
            ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
            ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrGold);
        }

    }

    if(iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) && ExpertBias == BULLISH) {
        
        double wickU = iHigh(Symbol(), Period(), 1) - iOpen(Symbol(), Period(), 1);
        double wickD = iClose(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1);

        if(wickU >= NormalizeDouble(ExpectedWick * _Point, _Digits) || wickD >= NormalizeDouble(ExpectedWick * _Point, _Digits)) {
            // Print("WICKU: ", wickU, " WICKD: ", wickD);
            ReverseCandle = ReverseCandle + 1.0;
            datetime dtime = TimeCurrent(); 
            ObjectCreate(0, dtime, OBJ_VLINE, 0, TimeCurrent(), iClose(Symbol(), Period(), 1));
            ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrGold);

        }

    }

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

double TotalDays = 0.0;
ENUM_TIMEFRAMES Daily = PERIOD_D1;
datetime DailyTime = iTime(Symbol(), Daily, 0);

void daysCounter()
{
    datetime CurrentTime = iTime(Symbol(), Daily, 0);

    if(CurrentTime != DailyTime) {
        ExpertStart     = false;
        DailyTime       = CurrentTime;
        TotalDays       = TotalDays + 1.0;
    }
}
