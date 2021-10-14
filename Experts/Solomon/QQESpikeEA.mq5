#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          expertIsTakingRecovery = REGULAR; // Take Recovery
input bool                                          expertIsUsingBreakeven = false; // Use break even
input group                                         "============  Money Management Settings ===============";
input double                                        riskAmount = 100; // Amount to risk
input int                                           swingCandle = 1; // Swing candle
input int                                           defaultStopLoss = 100; // Default stop loss
input double                                        NTakeProfit = 0.0; // N Take profit
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;
double stopLoss;
double takeProfit;
double lotSize;

void OnTick() 
{

    if(!spikeLatency()) { return ; }

    tradePositionManager();

    if(runAwayProfitManager()) { return ; }

    breakevenManager();

    if(qqe_signal(BUY) && qqe_filter_signal(BUY)) { 
        close_all_positions();
        takeTrade(LONG);
        if(expertIsTakingRecovery) { takeRecoveryTrade(LONG); }
    }

    if(qqe_signal(SELL) && qqe_filter_signal(SELL)) { 
        close_all_positions();
        takeTrade(SHORT);
        if(expertIsTakingRecovery) { takeRecoveryTrade(SHORT); }
    }
}

void takeTrade(marketEntry entry) {  
    if(PositionsTotal() >= 2){ return; }    
    if(expertBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else if(entry == SHORT){ entry = LONG; }   
    }
   if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        stopLoss = ask - iLow(Symbol(), Period(), swingCandle);

        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        lotSize = NormalizeDouble(riskAmount / stopLoss, 3);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        tradePeriod = tradePeriod + 1;
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
       
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;
        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        lotSize = NormalizeDouble(riskAmount / stopLoss, 3);
        
        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        tradePeriod = tradePeriod + 1;
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
        if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * takeProfit)) {
            close_all_positions();
            profitPeriod = profitPeriod + 1;
        }

        if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * stopLoss)) {
            close_all_positions();
        }
    }
}

/* ##################################################### Break Even Manager ##################################################### */
void breakevenManager() {
    if(!expertIsUsingBreakeven) { return ; }
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if( PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= stopLoss) {
                stopLoss = 2;
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if( PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= stopLoss) {
                stopLoss = 2;
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

/* ##################################################### Run Away Profit ##################################################### */
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          expertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               runAwayProfitFrequency = PERIOD_D1; // Frequency
input int                                           runAwayProfitTarget = 15; // Profit Target
input int                                           maxTradeTarget = 4; // Max Trade Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);

int profitPeriod = 0;
int tradePeriod = 0;
bool runAwayProfitManager()
{
    if(!expertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        profitPeriod = 0;
        tradePeriod = 0;
        return false;
    }

    if(profitPeriod >= runAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(tradePeriod >= maxTradeTarget) { 
        return true; 
    }
    
    
    return false;
}


/* ##################################################### Recovery ##################################################### */

void takeRecoveryTrade(marketEntry entry) {

    int countLost = countPreviousDealLost();

    if(countLost <= 0) { return ; }

    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        stopLoss = ask - iLow(Symbol(), Period(), swingCandle);

        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        double recoveryRisk = riskAmount * countLost;

        lotSize = NormalizeDouble(recoveryRisk / stopLoss, 3);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0, "Recovery");

    }

    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;

        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        double recoveryRisk = riskAmount * countLost;

        lotSize = NormalizeDouble(recoveryRisk / stopLoss, 3);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);

    }
}

int countPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    int dealLost = 0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + 1; }

        if(dealProfit > 0) { break; }

    }
    return dealLost;
}

/* ##################################################### QQE Settings ##################################################### */
input group                                         "============  QQE Settings ===============";
input int                                           qqePeriod = 14; // QQE Period
input int                                           qqeSmothing = 5; // QQE Smothing Factor
input double                                        qqeFastPeriod = 2.618; // QQE Fast Period
input double                                        qqeSlowPeriod = 4.236; // QQE Period
input ENUM_APPLIED_PRICE                            qqePrice = PRICE_CLOSE; // QQE Price

int qqeHandle = iCustom(NULL, 0, "QQE", qqePeriod, qqeSmothing, qqeFastPeriod, qqeSlowPeriod, qqePrice);

bool MABUY = false;
bool MASELL = false;

bool qqe_signal(marketSignal signal) {
    double qqeArray[];
    ArraySetAsSeries(qqeArray, true);
    CopyBuffer(qqeHandle, 3, 1, 2, qqeArray);
    // Print("QQE Price: ", qqeArray[0]);
    if(signal == BUY && qqeArray[0] == 1 && !MABUY) 
    { 
        MABUY = true;
        MASELL = false;
        return true; 
    }
    if(signal == SELL && qqeArray[0] == 2 && !MASELL) 
    { 
        MABUY = false;
        MASELL = true;
        return true; 
    }
    return false;
}

/* ##################################################### QQE Filter Settings ##################################################### */
input group                                         "============  QQE Filter Settings ===============";
input bool                                          useQQEFilter = false; // Use QQE Filter
input int                                           qqeFilterPeriod = 14; // QQE Period
input int                                           qqeFilterSmothing = 5; // QQE Smothing Factor
input double                                        qqeFilterFastPeriod = 2.618; // QQE Fast Period
input double                                        qqeFilterSlowPeriod = 4.236; // QQE Period
input ENUM_APPLIED_PRICE                            qqeFilterPrice = PRICE_CLOSE; // QQE Price
input ENUM_TIMEFRAMES                               qqeFilterTimeFrame = PERIOD_D1; // QQE Timeframes

int qqeFilterHandle = iCustom(NULL, qqeFilterTimeFrame, "QQE", qqeFilterPeriod, qqeFilterSmothing, qqeFilterFastPeriod, qqeFilterSlowPeriod, qqeFilterPrice);

bool qqe_filter_signal(marketSignal signal){
    if(!useQQEFilter) { return true; }
    double qqeArray[];
    ArraySetAsSeries(qqeArray, true);
    CopyBuffer(qqeFilterHandle, 3, 1, 2, qqeArray);
    // Print("FIlter Price: ", qqeArray[0]);
    if(signal == BUY && qqeArray[0] == 1) 
    { 
        return true; 
    }
    if(signal == SELL && qqeArray[0] == 2) 
    {
        return true; 
    }
    return false;
}



