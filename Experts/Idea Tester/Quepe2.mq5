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
input double                                        lotSize = 0.1; // Lot Size
input double                                        buyTakeProfit = 0.0; // Uptrend Take Profit in Pips
input double                                        buyStopLoss = 0.0; // Uptrend Stop Loss in Pips
input double                                        sellTakeProfit = 0.0; // Downtrend Take Profit in Pips
input double                                        sellStopLoss = 0.0; // Downtrend Stop Loss in Pips
input double                                        tradeRange = 50; // Trade range in Pips
input double                                        tradeMax = 4; // Trade Max
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

double uptrendTakeProfit = buyTakeProfit;
double uptrendStopLoss = buyStopLoss;
double downtrendTakeProfit = sellTakeProfit;
double downtrendStopLoss = sellStopLoss;
int lostCount = 0;
int winCount = 0;

bool MABUY = false;
bool MASELL = false;

void OnDeinit(const int reason)
{
    Print("Lostcount: ", lostCount);
    Print("winCount: ", winCount);
}

void OnTick() 
{
    if(!spikeLatency()) { return ; }
    
    if(runAwayProfitManager()) { return ; }

    tradePositionManager();

    // ma_filter_signal();

    double price = MathRound(iClose(Symbol(), Period(),1) / tradeRange) * tradeRange;

    ObjectDelete(Symbol(), "upperLine");
    ObjectDelete(Symbol(), "middleLine");
    ObjectDelete(Symbol(), "lowerLine");

    ObjectCreate( 0, "upperLine", OBJ_HLINE, 0, 0, price + tradeRange);
    ObjectCreate( 0, "middleLine", OBJ_HLINE, 0, 0, price);
    ObjectCreate( 0, "lowerLine", OBJ_HLINE, 0, 0, price - tradeRange);

    double uprice = iOpen(Symbol(), Period(),1);
    double dprice = iOpen(Symbol(), Period(),0);

    double sprice = MathMin(uprice, dprice);
    double eprice = MathMax(uprice, dprice);

    for(int i = sprice; i <= eprice; i++) {

        int tdr = (int) tradeRange;

        if((i % tdr) == 0) {

            if(uprice > i && dprice < i && !MABUY) {
                MABUY = true;
                MASELL = false;
                takeTrade(SHORT); 
            }

            if(uprice < i && dprice > i && !MASELL) {
                MABUY = false;
                MASELL = true;
                takeTrade(LONG);
             }

        }

    }

}

void takeTrade(marketEntry entry) {  
    if(PositionsTotal() >= tradeMax){ return; }    
    if(expertBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else if(entry == SHORT){ entry = LONG; }   
    }
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
            if( PositionGetDouble(POSITION_PROFIT) >= (lotSize * uptrendTakeProfit) ) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
                
            }
            if( PositionGetDouble(POSITION_PROFIT) <= -(lotSize * uptrendStopLoss) ) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if( PositionGetDouble(POSITION_PROFIT) >= (lotSize * downtrendTakeProfit) ) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
                
            }
            if( PositionGetDouble(POSITION_PROFIT) <= -(lotSize * downtrendStopLoss) ) {
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
input bool                                          expertIsUsingRunAwayLossTarget = false; // Use Run Away Loss Target
input ENUM_TIMEFRAMES                               runAwayProfitFrequency = PERIOD_D1; // Frequency
input double                                        runAwayProfitTarget = 15; // Profit Target
input double                                        runAwayLossTarget = 15; // Max Loss Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);
double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);

bool _MATARGETPROFIT = false;
bool _MATARGETLOSS = false;

bool runAwayProfitManager()
{
    if(!expertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        _MATARGETPROFIT = false;
        _MATARGETLOSS = false;
        return false;
    }
    
    currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

    // Print("Current Equity: ", currentEquity);
    // Print("Current Balance: ", currentBalance);
    

    if(currentEquity - accountBalance >= runAwayProfitTarget) {
        if(!_MATARGETPROFIT) { winCount = winCount + 1; }
        _MATARGETPROFIT = true;
        close_all_positions(); 
        return true; 
    }

    if(expertIsUsingRunAwayLossTarget) { 
        if(currentEquity - accountBalance <= -(runAwayLossTarget)) { 
            if(!_MATARGETLOSS) { lostCount = lostCount + 1; }
            _MATARGETLOSS = true;
            close_all_positions(); 
            return true; 
        }
    }
    return false;
}

// /* ##################################################### Moving Average Filter ##################################################### */
// input group                                       "============  Moving Average Filter  ===============";
// input bool                                         useMAFilter = false; // Use Moving Average Filter
// input ENUM_TIMEFRAMES                              MAFilterTimeFrame = PERIOD_M1; // Moving Average Timeframe
// input int                                          fastMAFilter = 1; // Fast Moving Average
// input int                                          fastMAFilterShift = 0; // Fast Moving Average Shift
// input ENUM_MA_METHOD                               fastMAFilterMethod = MODE_LWMA; // Fast Moving Average Method
// input ENUM_APPLIED_PRICE                           fastMAFilterAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
// input int                                          slowMAFilter = 50; // Slow Moving Average
// input int                                          slowMAFilterShift = 0; // SLow Moving Average Shift
// input ENUM_MA_METHOD                               slowMAFilterMethod = MODE_LWMA; // Slow Moving Average Method
// input ENUM_APPLIED_PRICE                           slowMAFilterAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

// int FastMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, fastMAFilter, fastMAFilterShift, fastMAFilterMethod, fastMAFilterAppliedPrice);
// int SlowMovingAverageFilterHandle = iMA(Symbol(), MAFilterTimeFrame, slowMAFilter, slowMAFilterShift, slowMAFilterMethod, slowMAFilterAppliedPrice);

// bool ma_filter_signal() {
//     if(!useMAFilter) { return true; }
//     double FastMovingAverageArray[], SlowMovingAverageArray[];
//     ArraySetAsSeries(FastMovingAverageArray, true);
//     ArraySetAsSeries(SlowMovingAverageArray, true);
//     CopyBuffer(FastMovingAverageFilterHandle, 0, 0, 3, FastMovingAverageArray);
//     CopyBuffer(SlowMovingAverageFilterHandle, 0, 0, 3, SlowMovingAverageArray);
//     if(FastMovingAverageArray[0] > SlowMovingAverageArray[0]) {
//         double uptrendTakeProfit = 60;
//         double uptrendStopLoss = 40;
//         double downtrendTakeProfit = 50;
//         double downtrendStopLoss = 20;
//     } 
//     if(FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
//         double uptrendTakeProfit = 50;
//         double uptrendStopLoss = 20;
//         double downtrendTakeProfit = 60;
//         double downtrendStopLoss = 40;
//     }
//     return false;
// }
