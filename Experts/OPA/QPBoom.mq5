#include <Trade\Trade.mqh>
CTrade trade;

input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input int                                           candPeriod = 14; // Period
input int                                           spikeMin = 1; // Spike Min in Period
// input int                                           spikeMax = 5; // Spike Max in Period
static datetime timestamp;

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

    datetime time = iTime(Symbol(), Period(), 1);


    if(timestamp != time) {
        close_all_positions();
        timestamp = time;
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        if(runAwayProfitManager()) { return ; }
        if(spikeDetector()) { return ; }
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

bool spikeDetector()
{
    int spike = 0;
    for(int i = 1; i <= candPeriod; i++)
    {
        if( iLow(Symbol(), Period(), i) != iClose(Symbol(), Period(), i))
        {
            spike = spike + 1;
        }
    }

    // if(spike >= spikeMax) { return true; }

    if(spike <= spikeMin) { return true; }

    return false;
}