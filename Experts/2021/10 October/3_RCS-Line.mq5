#include <Trade\Trade.mqh>
CTrade trade;

enum ENUM_BIAS      { BULLISH, BEARISH };
// input int           CandlesBeforeBias = 9; // Candles of the day before bias
double              ReverseCandle = 0.0;
bool                ExpertStart = false;
ENUM_BIAS           ExpertBias = BULLISH;

input ENUM_TIMEFRAMES ExpertTimeFrame   = PERIOD_CURRENT; // Trade Time frame
input double TakeProfit                 = 10.0; // Take Profit in Pips
input double StopLoss                   = 10.0; // Stop Loss in Pips
input double LotSize                    = 1.0; // Lot size

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

    spread_point = MathMax(spread_point, iSpread(Symbol(), Period(), 0));

    daysCounter();

    if(!ExpertStart) {
        ExpertStart = true;
        datetime dtime = TimeCurrent(); 
        ObjectCreate(0, dtime, OBJ_VLINE, 0, iTime(Symbol(), Period(), 0), iOpen(Symbol(), Period(), 0));
        ObjectSetInteger(0, dtime, OBJPROP_COLOR, clrLightSkyBlue);
        ObjectSetInteger(0, dtime, OBJPROP_BACK, 1);

        if(iClose(Symbol(), ExpertTimeFrame, 1) > iOpen(Symbol(), ExpertTimeFrame, 1)) {
            double bid                              = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
            double sl			                    = bid + NormalizeDouble(StopLoss * _Point, _Digits);
            double tp                               = bid - NormalizeDouble(TakeProfit * _Point, _Digits);
            trade.Sell(LotSize, Symbol(), bid, sl, tp);
            return;
        }

        if(iClose(Symbol(), ExpertTimeFrame, 1) < iOpen(Symbol(), ExpertTimeFrame, 1)) {
            double ask                              = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
            double sl			                    = ask - NormalizeDouble(StopLoss * _Point, _Digits);
            double tp                               = ask + NormalizeDouble(TakeProfit * _Point, _Digits);
            trade.Buy(LotSize, Symbol(), ask, sl, tp);
            return;
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
input string                                        tradingHourString = "1,2,3,4"; // Trading Hour  
input int                                           tradeStartDayOfWeek = 0; // Trade Period Start Day of Week
input int                                           tradeEndDayOfWeek = 6; // Trade Period End Day of Week
input string                                        tradingDayOfWeekToSkipString = "1,2,3,4,5,6"; // Trade Day of Week to skip
input int                                           tradeStartDay = 1; // Trade Period Start Day
input int                                           tradeEndDay = 30; // Trade Period End Day
input string                                        tradingDayToSkipString = "1,2,3,4,5,6"; // Trade Day to skip


ushort separator=StringGetCharacter(",",0); 
string tradingHourToArray[];  
string tradingDayOfWeekToSkipArray[];  
string tradingDayToSkipArray[];  

bool TradingPeriod()
{
    if(!useTradingTimePeriod) { return true; }
    
    MqlDateTime tradePeriodCurrentTime;

    TimeToStruct(TimeCurrent(), tradePeriodCurrentTime);

    StringSplit(tradingHourString,separator,tradingHourToArray);
    StringSplit(tradingDayOfWeekToSkipString,separator,tradingDayOfWeekToSkipArray);
    StringSplit(tradingDayToSkipString,separator,tradingDayToSkipArray);

    // for(int i = 0; i < ArraySize(tradingHourToArray); i++) { 
    //     if(StringCompare((string) tradePeriodCurrentTime.hour, tradingHourToArray[i]) == 0) {return false; }
    // }

    int tdp = (int) MathFloor((tradePeriodCurrentTime.day-1) / 7.0) ;

    // Print("Day: ", tradePeriodCurrentTime.day, " Week: ", tdp+1);

    if(tradePeriodCurrentTime.hour != tradingHourToArray[tdp]) { return false; }

    for(int i = 0; i < ArraySize(tradingDayOfWeekToSkipArray); i++) { 
        if(StringCompare((string) tradePeriodCurrentTime.day_of_week, tradingDayOfWeekToSkipArray[i]) == 0) {return false; }
    }

    for(int i = 0; i < ArraySize(tradingDayToSkipArray); i++) { 
        if(StringCompare((string) tradePeriodCurrentTime.day, tradingDayToSkipArray[i]) == 0) {return false; }
    }
    
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
