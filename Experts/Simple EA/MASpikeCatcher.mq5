#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                        "============  EA Settings  ===============";
input ulong                                        EXPERT_MAGIC = 787878; // Magic Number
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        SellStopLoss = 0; // Sell Stop Loss 
input double                                        SellTakeProfit = 0; // Sell Take Profit
input double                                        BuyStopLoss = 0; // Buy Stop Loss 
input double                                        BuyTakeProfit = 0; // Buy Take Profit 
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

void OnTick() 
{
    if(!spikeLatency()) { return ; }

    tradePositionManager();

    if(ma_signal(BUY) && macd_signal(BUY) && cci_signal(BUY) && candle_signal(BUY)) {
        takeTrade(LONG);
    } 
    if(ma_signal(SELL) && macd_signal(SELL) && cci_signal(SELL) && candle_signal(SELL)) {
        takeTrade(SHORT);
    }
}

void takeTrade(marketEntry entry) {      
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
   }
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}


/* ##################################################### Trade Position Manager ##################################################### */
void tradePositionManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * BuyTakeProfit)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * BuyStopLoss)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * SellTakeProfit)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * SellStopLoss)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
    }
}


/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
enum tradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============ Latency Settings ===============";
input tradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool spikeLatency()
{
    tradeCurrentTime = (int)TimeCurrent();
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);
    if(expertLatency == ZEROLATENCY) {
        return true;
    }
    if(expertLatency == TIMELATENCY) {
        if(tradeCurrentTime - tradeStartTime >= expertLatencyTime) { 
            tradeStartTime = tradeCurrentTime;
            return true;
        }
    }
    if(expertLatency == TIMEFRAMELATENCY)
    {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return true;
        }
    }
    return false;
}

/* ##################################################### Moving Average Signal ##################################################### */
input group                                       "============  Moving Average Settings  ===============";
input bool                                         useMASignal = true; // Use Moving Average Signal
input ENUM_TIMEFRAMES                              MATimeFrame = PERIOD_M1; // Moving Average Timeframe
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

int FastMovingAverageHandle = iMA(_Symbol, MATimeFrame, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, MATimeFrame, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(marketSignal signal) {
    if(!useMASignal) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) { Print("MA Signal true"); return true; }
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) { return true; }
    return false;
}

input group                                       "============  MACD Settings  ===============";
input bool                                         macdFactor = true; // Use signal MACD
input ENUM_TIMEFRAMES                              macdTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          macdFastEMA = 12; // Trend Fast EMA
input int                                          macdSlowEMA = 26; // Trend Slow EMA
input int                                          MACDSMA = 9; // Trend MACD SMA
input ENUM_APPLIED_PRICE                           MACDAppliedPrice = PRICE_CLOSE; // MACD Applied Price

bool macd_signal(marketSignal signal)
{
    if(!macdFactor) return true;
    int MACDHandle = iMACD(Symbol(), macdTimeframe, macdFastEMA, macdSlowEMA, MACDSMA, MACDAppliedPrice);
    double MACDArray[];
    ArraySetAsSeries(MACDArray, true);
    CopyBuffer(MACDHandle, 0, 0, 3, MACDArray);
    if(signal == BUY && MACDArray[0] > 0)  { Print("MACD Signal true"); return true; }
    if(signal == SELL && MACDArray[0] < 0) { return true; }
    return false;
}

input group                                       "============  Commondity Channel Index Settings  ===============";
input bool                                         cciFactor = true; // Use CCI 
input int                                          cciPeriod = 100; // CCI Period
input ENUM_APPLIED_PRICE                           cciAppliedPrice = PRICE_CLOSE; // CCI Applied Price
input int                                          cciOverBoughtZone = 100; // CCI Overbought Zone Level
input int                                          cciOversoldZone = -100; // CCI Oversold Zone Level

int cciHandle = iCCI(Symbol(), Period(), cciPeriod, cciAppliedPrice);

bool cci_signal(marketSignal signal)
{
   if(!cciFactor) { return true; }
   double cciArray[];
   ArraySetAsSeries(cciArray, true);
   CopyBuffer(cciHandle, 0, 0, 3, cciArray);
   double cciValue = cciArray[0];
   Comment("CCI value: ", cciValue);
   if(signal == BUY && cciValue < cciOversoldZone) { Print("CCI Signal true"); return true; }
    if(signal == SELL && cciValue > cciOverBoughtZone) { return true; }
    return false;
}

// input group                                       "============  Candle Settings  ===============";
// input int                                          CandleMA = 1; // Candle Moving Average
// input int                                          CandleMAShift = 0; // Candle Moving Average Shift
// input ENUM_MA_METHOD                               CandleMAMethod = MODE_LWMA; // Candle Moving Average Method
// input ENUM_APPLIED_PRICE                           CandleMAAppliedPrice = PRICE_CLOSE; // Candle Moving Average Applied Price

// int CandleMovingAverageHandle = iMA(Symbol(), Period(), CandleMA, CandleMAShift, CandleMAMethod, CandleMAAppliedPrice);

bool candle_signal(marketSignal signal)
{
    double CandleMovingAverageArray[];
    ArraySetAsSeries(CandleMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, CandleMovingAverageArray);

    if(signal == BUY && iOpen(Symbol(), Period(), 1) > CandleMovingAverageArray[1] && iOpen(Symbol(), Period(), 0) < CandleMovingAverageArray[0] && !PositionsTotal())
    {
        Print("Candle Signal true");
        return true;
    }
    if(signal == SELL && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && iOpen(Symbol(), Period(), 0) < CandleMovingAverageArray[0] && !PositionsTotal())
    {
        return true;
    }
    return false;
}
