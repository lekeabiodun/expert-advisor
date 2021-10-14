input group                                         "===================== Latency Settings =====================";
input bool                                          UseTradeLatency = false; // Use Trade Latency
input ENUM_TIMEFRAMES                               LatencyTimeFrame = PERIOD_CURRENT; // Latency Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool TradeHasLatency()
{
    if(!UseTradeLatency) { return false; }

    tradeCandleTime = iTime(Symbol(), LatencyTimeFrame, 0);
    
    if(tradeTimestamp != tradeCandleTime) {

        tradeTimestamp = tradeCandleTime;

        return false;
    }

    return true;
}