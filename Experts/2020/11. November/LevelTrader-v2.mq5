#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input int                                           maxTrade = 1; // Max Trade
input bool                                          expertIsTakingRecovery = false; // Take Recovery
input group                                         "============  Level Settings  ===============";
input int                                           lookBackCandleRange = 1; // Look back candle range
input int                                           levelModulo = 100; // Level
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

/*

This EXPERT ADVISOR will trade levels but look back to confirm the candle form before the getting to that level.
If level is 100, then the EA will wait for price to cross round level divisible N%100 == 0 and make decision on trade.

Check level (Must be round level)
Deternmine direction
Take trade.

I want try an Idea different from the requirement above, EA will take trade in direction of the market once a candle open above level.
We focuson M15 H1
*/

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

int prevLevel = 0;
int currLevel = 0;

double maxPrice = 0;
double minPrice = 0; 

void OnTick() 
{

    if(!spikeLatency()) { return ; }
    

    maxPrice = MathMax(iHigh(Symbol(), Period(), 1), iHigh(Symbol(), Period(), 0));
    minPrice = MathMin(iLow(Symbol(), Period(), 1), iLow(Symbol(), Period(), 0));

    for(int i = (int) minPrice; i <= (int) maxPrice; i++) 
    {
        if(i % levelModulo == 0)
        {   
            
            tradePositionManager();

            if(marketDirection(BULLISH)) 
            {
                takeTrade(LONG);
            } 
            if(marketDirection(BEARISH)) 
            {
                takeTrade(SHORT);
            }
        }
        
    }
    
}

void takeTrade(marketEntry entry) {

    if(entry == LONG && expertIsTakingBuyTrade && expertAllows(POSITION_TYPE_BUY)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(expertIsTakingRecovery) { takeRecoveryTrade(LONG); }
    }

    if(entry == SHORT && expertIsTakingSellTrade && expertAllows(POSITION_TYPE_SELL)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(expertIsTakingRecovery) { takeRecoveryTrade(SHORT); }
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}


bool expertAllows(ENUM_POSITION_TYPE positionType) 
{
    bool result = true;

    if(!PositionsTotal()) { return true; }

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == positionType) { 
            result = false; 
        }
    }

    return result;
}
/* ##################################################### Recovery ##################################################### */
void takeRecoveryTrade(marketEntry entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        double recoveryLotSize = NormalizeDouble(dealLost / stopLoss, 2);

        if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }

    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        double recoveryLotSize = NormalizeDouble(dealLost / stopLoss, 2);

        if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
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

/* ##################################################### Market Direction ##################################################### */
bool marketDirection(marketTrend trend) 
{
    double sum = 0;
    double average = 0;

    for(int i = 1; i <= lookBackCandleRange; i++) {
        sum = sum + iOpen(Symbol(), Period(), i);
    }

    average = sum / lookBackCandleRange;

    if(trend == BULLISH && iOpen(Symbol(), Period(), 0) > average) {
        return true;
    }
    
    if(trend == BEARISH && iOpen(Symbol(), Period(), 0) < average) {
        return true;
    }

    return false;

}