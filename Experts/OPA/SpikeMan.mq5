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
input double                                        stopLoss = 50; // Stop Loss in Pips
input double                                        takeProfit = 1; // Take Profit in Pips
// input group                                         "============  Scalp Settings ===============";
// input bool                                          closeOppositeTradeOnOppositeSignal = true; // Close Opposite Trade on Opposite Signal
// input bool                                          closeTradeOnOSpike = true; // Close Trade on Spike Signal
bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
bool                                          expertIsTakingSellTrade = true; // Take Sell Trade

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

    // if(candle_signal()) { 
    //     takeTrade(LONG);
    // }
    if(candle_signal()) {
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

void tradeManager() {
    // if(closeTradeOnOSpike)
    // {
    //     if( iOpen(Symbol(), Period(), 1) < iClose(Symbol(), Period(), 1)) { close_all_positions(); }
    // }
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(takeProfit && (PositionGetDouble(POSITION_PROFIT) / lotSize) >= takeProfit) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
        if(stopLoss && ( PositionGetDouble(POSITION_PROFIT) / lotSize ) <= -stopLoss) {
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

/* ##################################################### Candle Signal ##################################################### */
input group                                       "============  Candle Filter  ===============";
input bool                                         useCandleSignal = false; // Use Candle Signal
input int                                          spikePeriod = 14; // Spike Period
input double                                       kDiff = 0.5; // Open / Close Diff

bool candle_signal() {
    if(!useCandleSignal) { return true; }
    if( 
        iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) 
        && (iClose(Symbol(), Period(), 1) - iOpen(Symbol(), Period(), 1)) < kDiff 
        && noSpike()
    ) 
    {
        return true;
    }

    return false;

}

bool noSpike() {
    int spike = 0;
    for(int i = 2; i <= spikePeriod; i++)
    {
        if( iLow(Symbol(), Period(), i) != iClose(Symbol(), Period(), i))
        {
            spike = spike + 1;
        }
    }

    if(spike == 0) { return true; }

    return false;
}
