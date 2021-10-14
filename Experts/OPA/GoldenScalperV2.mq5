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
input double                                        tradeRange = 50; // Trade Range in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

double upperLine, middleLine, lowerLine;


bool startTrade = false;
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

    // if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && MASELL)
    // {
    //     double price = iHigh(Symbol(), Period(), 1);

    //     setLineValues(price);
    // }

    // MqlRates PriceInformation[];

    // ArraySetAsSeries(PriceInformation, true);

    // int Data = CopyRates(Symbol(), Period(), 0, Bars(Symbol(), Period()), PriceInformation);


    tradeManager();

    queue_signal(BUY);

    takeTrade();
}

void takeTrade() {   
   if(expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        if(iClose(Symbol(), Period(), 0) > middleLine && !MABUY)
        {
            MABUY = true;
            // MASELL = false;
            trade.Buy(lotSize, Symbol(), ask, 0, 0);
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
        }
   }
   if(expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        if(iClose(Symbol(), Period(), 0) < middleLine && !MASELL) {
            // MABUY = false;
            MASELL = true;
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
            trade.Sell(lotSize, Symbol(), bid, 0, 0);
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

void tradeManager() {
    double initialAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(iClose(Symbol(), Period(), 0) >= upperLine) {
        lineHit = true;
        MASELL = false;
        MABUY = false;
        close_all_positions();

        double finalAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

        if(finalAccountBalance > initialAccountBalance)
        {
            Comment("Profit");
        } else {
            Comment("Loss");
        }
    }
    if(iClose(Symbol(), Period(), 0) <= lowerLine) {
        lineHit = true;
        MASELL = false;
        MABUY = false;
        close_all_positions();

        double finalAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

        if(finalAccountBalance > initialAccountBalance)
        {
            Comment("Profit");
        } else {
            Comment("Loss");
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
        startTrade = false;
        return true; 
    }

    // if(currentBalance - accountBalance <= -runAwayProfitTarget) { close_all_positions(); return true; }

    return false;
}

/* ##################################################### Queue Signal ##################################################### */

bool MABUY = false;
bool MASELL = false;
bool lineHit = true;

bool queue_signal(marketSignal signal) {

    if(!lineHit) { return false; }

    double price = iClose(Symbol(), Period(), 0);

    setLineValues(price);

    lineHit = false;

    // if(signal == BUY && parabolicSARArray[1] < iLow(Symbol(), Period(), 1) && !MABUY) {
    //     if(MASELL && closeOppositeTradeOnOppositeSignal) { close_all_positions(); }
    //     MABUY = true;
    //     MASELL = false;
    //     startTrade = true;
    //     return true; 
    // }
    // else if(signal == SELL && parabolicSARArray[1] > iHigh(Symbol(), Period(), 1) && !MASELL) {
    //     if(MABUY && closeOppositeTradeOnOppositeSignal) { close_all_positions(); }
    //     MABUY = false;
    //     MASELL = true;
    //     startTrade = true;
    //     return true;
    // }
    return false;
}


void setLineValues(double price) {

    ObjectDelete(Symbol(), "upperLine");
    ObjectDelete(Symbol(), "middleLine");
    ObjectDelete(Symbol(), "lowerLine");

    upperLine = price + tradeRange;
    middleLine = price;
    lowerLine = price - tradeRange;

    ObjectCreate( 0, "upperLine", OBJ_HLINE, 0, 0, price + tradeRange);
    ObjectCreate( 0, "middleLine", OBJ_HLINE, 0, 0, price);
    ObjectCreate( 0, "lowerLine", OBJ_HLINE, 0, 0, price - tradeRange);
}