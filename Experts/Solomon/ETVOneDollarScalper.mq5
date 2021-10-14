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
input int                                           lotSize = 1; // Lot size
input double                                        uptrendStopLoss = 50; // Uptrend Stop Loss in Pips
input double                                        uptrendTakeProfit = 1; // Uptrend Take Profit in Pips
input double                                        downtrendStopLoss = 70; // Downtrend Stop Loss in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          tradeOppositePendingOrder = false; // Trade Opposite Pending Order
input int                                           pendingOrderAwayPips = 50; // Opposite Pending Order Pips
input bool                                          closePreviousTradeOnNewSignal = true; // Close Previous Trade on New Signal
input bool                                          closeOppositeTradeOnOppositeSignal = true; // Close Opposite Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoveryLotSize = 10; // Lot Sizeinput double
input double                                        recoveryCount = 3; // Recovery Count

int downtrendTakeProfit; 

double pendingOrderPrice;
marketEntry pendingOrderEntry;

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

    tradePendingOrder();

    if(runAwayProfitManager()) { return ; }

    tradePositionManager();

    if(ma_filter_signal(BUY) && etv_signal(BUY)) { 
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(LONG);
    }
    if(ma_filter_signal(SELL) && etv_signal(SELL)) { 
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(SHORT);
    }
}

void takeTrade(marketEntry entry) {      
    if(expertBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else if(entry == SHORT){ entry = LONG; }   
    }
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        pendingOrderPrice = NormalizeDouble(etvLineValue - pendingOrderAwayPips, _Digits);
        pendingOrderEntry = LONG;
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLost() > recoveryCount  && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        downtrendTakeProfit = (int)(bid - etvLineValue);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLost() > recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
        }
   }
}

void tradePendingOrder()
{
    if(!tradeOppositePendingOrder){ return ;}
    if(OrdersTotal()) { trade.OrderDelete(OrderGetTicket(0)); }
    if(pendingOrderEntry == LONG && pendingOrderPrice) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        if(bid <= pendingOrderPrice) { 
            trade.Sell(lotSize, Symbol(), bid, 0, 0, "Pending LONG");
            pendingOrderPrice = 0;
        }
    }
    if(pendingOrderEntry == SHORT && pendingOrderPrice) { 
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        if(ask >= pendingOrderPrice) { 
            trade.Buy(lotSize, Symbol(), ask, 0, 0, "Pending SHORT");
            pendingOrderPrice = 0;
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


/* ##################################################### Trade Position Manager ##################################################### */
void tradePositionManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * uptrendTakeProfit)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * uptrendStopLoss)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * downtrendTakeProfit)) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * downtrendStopLoss)) {
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

/* ##################################################### ETV Signal ##################################################### */
input group                                       "============  ETV Settings  ===============";
input bool                                         useETVSignal = true; // Use ETV Signal
input int                                          ADXPeriod1 = 10; // ADX Period 1
input int                                          ADXPeriod2 = 14; // ADX Period 2
input int                                          ADXPeriod3 = 20; // ADX Period 3

bool etvLine = false;
double etvLineValue;

int ETVHandle = iCustom(NULL, 0, "ETV", ADXPeriod1, ADXPeriod2, ADXPeriod3);

bool etv_signal(marketSignal signal)
{
    if(!useETVSignal) { return true; }
    double ETVSell[], ETVBuy[], ETVEnd[];
    ArraySetAsSeries(ETVSell, true);
    ArraySetAsSeries(ETVBuy, true);
    ArraySetAsSeries(ETVEnd, true);
    CopyBuffer(ETVHandle, 3, 0, 3, ETVBuy);
    CopyBuffer(ETVHandle, 4, 0, 3, ETVSell);
    CopyBuffer(ETVHandle, 5, 0, 3, ETVEnd);
    if(ETVEnd[0] != EMPTY_VALUE && etvLine == false) {
        etvLineValue = ETVEnd[0];
        etvLine = true; 
        return true; 
    }
    if(ETVEnd[0] == EMPTY_VALUE && etvLine == true) {
        etvLine = false; 
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

bool MABUY = false;
bool MASELL = false;

int FastMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, fastMAFilter, fastMAFilterShift, fastMAFilterMethod, fastMAFilterAppliedPrice);
int SlowMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, slowMAFilter, slowMAFilterShift, slowMAFilterMethod, slowMAFilterAppliedPrice);

bool ma_filter_signal(marketSignal signal) {
    if(!useMAFilter) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageFilterHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageFilterHandle, 0, 0, 3, SlowMovingAverageArray);
    Print("Fast: ", FastMovingAverageArray[0] );
    Print("Slow: ", SlowMovingAverageArray[0] );
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) {
        if(MASELL && closeOppositeTradeOnOppositeSignal) { 
            close_all_positions(); 
        }
        MABUY = true;
        MASELL = false;
        return true; 
    } 
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        if(MABUY && closeOppositeTradeOnOppositeSignal) { 
            close_all_positions(); 
        }
        MABUY = false;
        MASELL = true;
        return true; 
    }
    return false;
}
