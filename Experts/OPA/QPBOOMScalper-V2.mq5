#include <Trade\Trade.mqh>
CTrade trade;

input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input group                                         "============  Time Settings ===============";
input int                                           expertStartTime = 1; // Trade Start Time
input int                                           expertEndTime = 10; // Trade End Time

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
static datetime timestamp;
bool expertTakeTrade = false;

int OnInit()
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

void OnTick() 
{
    MqlDateTime dt;

    tradeCurrentTime = (int)TimeCurrent();

    TimeToStruct(tradeCurrentTime, dt);

    // Print("Time: ", dt.sec);

    // if(iClose(Symbol(), Period(), 0) != iLow(Symbol(), Period(), 0)) { return; }

    tradeTimer();

   datetime time = iTime(Symbol(), Period(), 1);

   if(expertTakeTrade && dt.sec >= expertStartTime && dt.sec <= expertEndTime && ma_filter_signal()) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        tradeStartTime = (int)TimeCurrent();
        expertTakeTrade = false;
        if(runAwayProfitManager()) { return ; }
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
    }

   if(timestamp != time) {
        timestamp = time;
        expertTakeTrade = true;
    }
}

void tradeTimer()
{
    if(PositionsTotal()) {
        if((tradeCurrentTime - tradeStartTime) >= (expertEndTime - expertStartTime)) {
            for(int i=0; i < PositionsTotal(); i++) {
                close_all_positions();
            }
        }
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

bool ma_filter_signal() {
    if(!useMAFilter) { return true; }
    double FastMovingAverageArray[], SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageFilterHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageFilterHandle, 0, 0, 3, SlowMovingAverageArray);
    if(FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        return true; 
    }
    return false;
}