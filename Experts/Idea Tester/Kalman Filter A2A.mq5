#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          closeTradeOnNewSignal = true; // Close Trade on New Signal
input bool                                          expertIsTakingRecovery = false; // Take Recovery
input group                                         "============  Money Management Settings ===============";
input double                                        riskAmount = 100; // Amount to risk
input int                                           swingCandle = 1; // Swing candle
input double                                        defaultStopLoss = 100; // Default stop loss
input double                                        NTakeProfit = 0.0; // N Take profit
input double                                        RNTakeProfit = 0.0; // Recovery N Take profit
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

    if(runAwayProfitManager()) { return ; }

    tradePositionManager();

    if(kalman_filter_signal(BUY) && kalman_filter(BUY)) { 
        if(closeTradeOnNewSignal) { close_all_positions(); }
        takeTrade(LONG);
        if(expertIsTakingRecovery) { takeRecoveryTrade(LONG); }
    }

    if(kalman_filter_signal(SELL) && kalman_filter(SELL)) { 
        if(closeTradeOnNewSignal) { close_all_positions(); }
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

        lotSize = NormalizeDouble(riskAmount / stopLoss, 0);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
       
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;
        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        lotSize = NormalizeDouble(riskAmount / stopLoss, 0);
        
        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit);
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
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }

        if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * stopLoss)) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
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
input double                                        runAwayProfitTarget = 15; // Profit Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);
double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

bool runAwayProfitManager()
{
    if(!expertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        return false;
    }

    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(currentEquity - accountBalance >= runAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }
    return false;
}


/* ##################################################### Recovery ##################################################### */

void takeRecoveryTrade(marketEntry entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        stopLoss = ask - iLow(Symbol(), Period(), swingCandle);

        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        lotSize = NormalizeDouble(dealLost / stopLoss, 0);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = RNTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit, "Recovery");
    }

    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;

        if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        lotSize = NormalizeDouble(dealLost / stopLoss, 0);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = RNTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit, "Recovery");
    }
}

double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + dealProfit; }

        if(dealProfit > 0) { break; }

    }

    return dealLost;
}

/* ##################################################### Kalman Filter Settings ########################################################## */

int kfHandle = iCustom(NULL, 0, "Kalman_filter");

bool MABUY = false;
bool MASELL = false;

// 1 = BUY; 2 = SELL;
bool kalman_filter_signal(marketSignal signal){
    double kfArray[];
    ArraySetAsSeries(kfArray, true);
    CopyBuffer(kfHandle, 1, 0, 2, kfArray);
    // Print(kfArray[0]);
    // if(signal == BUY && kfArray[0] == 1 && kfArray[1] == 2 && !MABUY) {
    if(signal == BUY && kfArray[0] == 1 && !MABUY) {
        Comment("BUY now");
        MABUY = true;
        MASELL = false;
        return true; 
    }
    if(signal == SELL && kfArray[0] == 2 && !MASELL)  {
        Comment("Sell now");
        MABUY = false;
        MASELL = true;
        return true; 
    }
    return false;
}


/* ##################################################### Kalman Filter Settings ##################################################### */
input group                                         "============  Kalman Filter Settings ===============";
input bool                                          useKalmanFilter = false; // Use Kalman Filter
input ENUM_TIMEFRAMES                               filterPeriod = PERIOD_H1; // Filter Period

int filterHandle = iCustom(NULL, filterPeriod, "Kalman_filter");

bool kalman_filter(marketSignal signal){
    if(!useKalmanFilter) { return true; }
    double kfArray[];
    ArraySetAsSeries(kfArray, true);
    CopyBuffer(filterHandle, 1, 1, 2, kfArray);
    // Print(kfArray[0]);
    if(signal == BUY && kfArray[0] == 1 && kfArray[1] == 2) {
        return true; 
    }
    if(signal == SELL && kfArray[0] == 2 && kfArray[1] == 1)  {
        return true; 
    }
    return false;
}
