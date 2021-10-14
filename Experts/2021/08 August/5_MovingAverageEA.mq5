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
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade



void OnTick() 
{
    // if(!ExpertHasLatency()) { return ; }

    if(!GAP()) { return ; }

    double open = iOpen(Symbol(), gapTimeFrame, 0);
    double close = iClose(Symbol(), gapTimeFrame, 0);
    double Signal = close > open ? MARKET_ENTRY_SHORT : MARKET_ENTRY_LONG ;
    
    if(ma_signal(MARKET_SIGNAL_BUY) && Signal == MARKET_ENTRY_LONG) { 
        TakeTrade(MARKET_ENTRY_LONG);
    }
    if(ma_signal(MARKET_SIGNAL_SELL) && Signal == MARKET_ENTRY_SHORT) {
        TakeTrade(MARKET_ENTRY_SHORT);
    }
}


void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade && NoPositionType(Entry)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl = getsl(Entry);
        double tp = ask + ((ask - sl) * 2.0);
        trade.Buy(LotSize, Symbol(), ask, sl, tp);
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade && NoPositionType(Entry)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl = getsl(Entry);
        double tp = bid - ((sl - bid) * 2.0);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
    }

}

bool NoPositionType(ENUM_MARKET_ENTRY Entry)
{
    bool Result = true;

    if(PositionsTotal() && Entry == MARKET_ENTRY_LONG) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            PositionSelectByTicket(ticket);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                Result = false;
                break;
            }
        }
    }

    if(PositionsTotal() && Entry == MARKET_ENTRY_SHORT) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            PositionSelectByTicket(ticket);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                Result = false;
                break;
            }
        }
    }

    return Result;
}

double getsl(ENUM_MARKET_ENTRY Entry) 
{
    double sl;

    if(Entry == MARKET_ENTRY_LONG) {
        sl = iLow(Symbol(), Period(), 1);
        for(int i = 2; i < 100; i++) {
            double low = iLow(Symbol(), Period(), i);
            if(low < sl) {
                sl = low;
                continue;
            } else {
                break;
            }
        } 
    }

    if(Entry == MARKET_ENTRY_SHORT) {
        sl = iHigh(Symbol(), Period(), 1);
        for(int i = 2; i < 100; i++) {
            double high = iHigh(Symbol(), Period(), i);
            if(high > sl) {
                sl = high;
                continue;
            } else {
                break;
            }
        }
    }

    return sl;
}

input group                                         "============ Latency Settings ===============";
input bool                                          expertLatency = false; // Trade Latency
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool ExpertHasLatency()
{
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);

    if(!expertLatency) {
        return false;
    } else {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return false;
        }
    }
    return true;
}




input group                                       "============  GAP Settings  ===============";
input int                                          gapPeriod = 2; // Gap Period
input ENUM_TIMEFRAMES                              gapTimeFrame = PERIOD_H1; // Gap Period

bool GAP()
{
    double open = iOpen(Symbol(), gapTimeFrame, 0);
    double close = iClose(Symbol(), gapTimeFrame, 0);
    double body = close > open ? close - open : open - close;

    double open1 = iOpen(Symbol(), gapTimeFrame, 1);
    double close1 = iClose(Symbol(), gapTimeFrame, 1);
    double body1 = close1 > open1 ? close1 - open1 : open1 - close1;

    double open2 = iOpen(Symbol(), gapTimeFrame, 2);
    double close2 = iClose(Symbol(), gapTimeFrame, 2);
    double body2 = close2 > open2 ? close2 - open2 : open2 - close2;

    if(body > body1 && body > body2) {
        return true;
    }
    
    return false;

} 

input group                                       "============  Moving Average Settings  ===============";
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

int FastMovingAverageHandle = iMA(_Symbol, _Period, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, _Period, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(ENUM_MARKET_SIGNAL Signal )
{
   double FastMovingAverageArray[];
   double SlowMovingAverageArray[];
   ArraySetAsSeries(FastMovingAverageArray, true);
   ArraySetAsSeries(SlowMovingAverageArray, true);
   CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
   CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(Signal == MARKET_SIGNAL_BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0] && FastMovingAverageArray[1] < SlowMovingAverageArray[1]) {
        return true; 
    } 
    if(Signal == MARKET_SIGNAL_SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0] && FastMovingAverageArray[1] > SlowMovingAverageArray[1]) {
        return true; 
    }
   return false;
}
