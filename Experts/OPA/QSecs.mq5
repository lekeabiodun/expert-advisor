#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};
enum marketEntry {
   LONG,                // Only Long
   SHORT                // Only Short
};
enum tradeBehaviour {   
   REGULAR,             // Regular
   OPPOSITE             // Opposite
};

enum marketTrend{
    BULLISH, 
    BEARISH, 
    SIDEWAYS
};

input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Time Settings ===============";
input bool                                          expertStartTime = false; // Start time
input bool                                          expertStopTime = false; // Stop time
input int                                           tradeTime = 50; // Time to trade

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
static datetime timestamp;
double currentPrice;
double lastPrice;

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
    tradeCurrentTime = (int)TimeCurrent();

    lastPrice = currentPrice;
    currentPrice = iClose(Symbol(), Period(), 0);

    if(iClose(Symbol(), Period(), 0) != iLow(Symbol(), Period(), 0)) { return; }


    tradeTimer();

   datetime time = iTime(Symbol(), Period(), 1);

   if(timestamp != time) {
        timestamp = time;
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        tradeStartTime = (int)TimeCurrent();
        if(runAwayProfitManager()) { return ; }
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
    }
}

void tradeTimer()
{
    if(PositionsTotal() && tradeTime) {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime) {
            for(int i=0; i < PositionsTotal(); i++) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
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

    // if(currentBalance - accountBalance <= -runAwayProfitTarget) { close_all_positions(); return true; }

    return false;
}