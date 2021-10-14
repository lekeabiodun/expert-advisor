#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        uptrendStopLoss = 70; // Uptrend Stop Loss in Pips
input double                                        uptrendTakeProfit = 30; // Uptrend Take Profit in Pips
input double                                        downtrendStopLoss = 50; // Downtrend Stop Loss in Pips
input double                                        downtrendTakeProfit = 1; // Downtrend Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closePreviousTradeOnNewSignal = true; // Close Previous Trade on New Signal
input bool                                          closeOppositeTradeOnOppositeSignal = true; // Close Opposite Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============  Momentum Settings ===============";
input bool                                          useSellTradeMomentum = false; // Use Sell Trade Momentum
input bool                                          useBuyTradeMomentum = false; // Use Buy Trade Momentum
input group                                         "============  Swing Settings ===============";
input bool                                          tradeSwing = false; // Trade Swing
input double                                        swingConstant = 1; // Swing $[K]Constant%
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoveryLotSize = 10; // Lot Sizeinput double
input double                                        recoveryCount = 3; // Recovery Count

int OnInit() {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

void OnTick() 
{  
    if(!spikeLatency()) { return ; }

    if(runAwayProfitManager()) { return ; }

    tradeManager();

    if(ma_signal(BUY) && ma_filter_signal(BUY) && spike_signal(BUY)) { 
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        if(tradeLimitManager()) { return ; }
        takeTrade(LONG);
    }
    if(ma_signal(SELL) && ma_filter_signal(SELL) && spike_signal(SELL)) {
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        if(tradeLimitManager()) { return ; }
        takeTrade(SHORT);
    }
}

void takeTrade(marketEntry entry) {      
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double takeProfitPrice = ask + downtrendTakeProfit;
        if(tradeSwing) {
            takeProfitPrice = ask + ((iHigh(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1) ) * swingConstant );
        }
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, takeProfitPrice);
        if(getPreviousDealLost() > recoveryCount  && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, takeProfitPrice, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid + downtrendStopLoss, 0);
        if(getPreviousDealLost() > recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, bid + downtrendStopLoss, 0, "Recovery");
        }
   }
}

double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0.0;
    double count = 0.0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + dealProfit; count = count + 1; }

        if(dealProfit > 0) { break; }

    }
    return count;
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(uptrendStopLoss && (PositionGetDouble(POSITION_PROFIT) / lotSize) <= -uptrendStopLoss) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(downtrendTakeProfit && ( PositionGetDouble(POSITION_PROFIT) / lotSize ) >= downtrendTakeProfit) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
    }
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

    // if(currentBalance - accountBalance <= -runAwayProfitTarget) { close_all_positions(); return true; }

    return false;
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

/* ##################################################### Trades Limit Manager ##################################################### */
input group                                         "============  Trades Limit Manager ===============";
input bool                                          expertIsUsingTradeLimit = false; // Use Trade Limit
input int                                           tradeLimit = 0; // Trades Limit
int tradeLimitCount = 0; 

bool tradeLimitManager() {
    if(!expertIsUsingTradeLimit) { return false; }
    if(tradeLimitCount >= tradeLimit && tradeLimit) { return true; }
    tradeLimitCount = tradeLimitCount + 1;
    return false;
}

/* ##################################################### Spike Signal ##################################################### */
bool spike_signal(marketSignal signal) {
   if(iLow(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1)) { 
       if(signal == BUY && useBuyTradeMomentum) {
           for(int i=2; i<1440; i++) {
               if(iLow(Symbol(), Period(), i) == iOpen(Symbol(), Period(), i)) {
                   continue;
               }
               if(iLow(Symbol(), Period(), i) < iOpen(Symbol(), Period(), i)) {
                   if(iLow(Symbol(), Period(), 1) > iLow(Symbol(), Period(), i)) {
                       return true;
                   } else {
                       return false;
                   }
               }
           }
       }
       if(signal == SELL && useSellTradeMomentum) {
           for(int i=2; i<1440; i++) {
               if(iLow(Symbol(), Period(), i) == iOpen(Symbol(), Period(), i)) {
                   continue;
               }
               if(iLow(Symbol(), Period(), i) < iOpen(Symbol(), Period(), i)) {
                   if(iLow(Symbol(), Period(), 1) < iLow(Symbol(), Period(), i)) {
                       return true;
                   } else {
                       return false;
                   }
               }
           }
       }
       return true; 
    }
    
    return false;
}

/* ##################################################### Moving Average Signal ##################################################### */
input group                                       "============  Moving Average Settings  ===============";
input bool                                         useMASignal = true; // Use Moving Average Signal
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price
bool MABUY = false;
bool MASELL = false;
int FastMovingAverageHandle = iMA(_Symbol, _Period, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, _Period, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(marketSignal signal) {
    if(!useMASignal) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) {
        if(MASELL && closeOppositeTradeOnOppositeSignal) { 
            tradeLimitCount = 0;
            close_all_positions(); 
        }
        MABUY = true;
        MASELL = false;
        return true; 
    } 
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        if(MABUY && closeOppositeTradeOnOppositeSignal) { 
            tradeLimitCount = 0;
            close_all_positions(); 
        }
        MABUY = false;
        MASELL = true;
        return true; 
    }
    return false;
}

/* ##################################################### Moving Average Filter ##################################################### */
input group                                       "============  Moving Average Filter  ===============";
input bool                                         useMAFilter = false; // Use Moving Average Filter
input ENUM_TIMEFRAMES                              MAFilterTimeFrame = PERIOD_M1; // Moving Average Timeframe
input int                                          fastMAFilter = 1; // Fast Moving Average
input int                                          fastMAFilterShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAFilterMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAFilterAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMAFilter = 50; // Slow Moving Average
input int                                          slowMAFilterShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAFilterMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAFilterAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

int FastMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, fastMAFilter, fastMAFilterShift, fastMAFilterMethod, fastMAFilterAppliedPrice);
int SlowMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, slowMAFilter, slowMAFilterShift, slowMAFilterMethod, slowMAFilterAppliedPrice);

bool ma_filter_signal(marketSignal signal) {
    if(!useMAFilter) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageFilterHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageFilterHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) {
        return true; 
    } 
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        return true; 
    }
    return false;
}