input group                                         "============ KT Trend Filter Settings ===============";
input int                                           trendBars = 10000; // Max History Bars
input int                                           trendPeriod = 200; // Trend Period
input bool                                          mtfScanner = false; // Show MTF Scanner

int trendFilterHandle = iCustom(Symbol(), Period(), "TrendFilter", trendBars, trendPeriod, mtfScanner);

bool trend_filter_signal(marketTrend trend)
{
    double uptrend[], downtrend[], sideways[];
    ArraySetAsSeries(uptrend, true);
    ArraySetAsSeries(downtrend, true);
    ArraySetAsSeries(sideways, true);
    CopyBuffer(trendFilterHandle, 0, 0, 3, uptrend);
    CopyBuffer(trendFilterHandle, 1, 0, 3, downtrend);
    CopyBuffer(trendFilterHandle, 2, 0, 3, sideways);

    if(trend == BULLISH && uptrend[0] != 0)
    {
        return true;
    }
    if(trend == BEARISH && downtrend[0] != 0)
    {
        return true;
    }
    if(trend == SIDEWAYS && sideways[0] != 0)
    {
        return true;
    }
    return false;
}