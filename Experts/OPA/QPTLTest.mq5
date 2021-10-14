#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{ BUY, SELL};
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH,  BEARISH,  SIDEWAYS };
enum tradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0; // Stop Loss 
input double                                        takeProfit = 0; // Take Profit 
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoveryLotSize = 10; // Lot Sizeinput double                                        recoveryCount = 1; // Recovery Count
input double                                        recoveryCount = 3; // Recovery Count
input group                                         "============ Latency Settings ===============";
input tradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe


static datetime tradeTimestamp;
datetime tradeCandleTime;


int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();


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
    
    tradeCurrentTime = (int)TimeCurrent();

    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);


    if(testLatency()) 
    { 
        tradeManager();

        if(perfect_trendline_signal(BUY))
        { 
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(LONG);
        }
        if(perfect_trendline_signal(SELL))
        {
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(SHORT);
        }  
    }
}

void takeTrade(marketEntry entry) {
    if(expertBehaviour == OPPOSITE ) {
        if( entry == LONG ) { entry = SHORT; }
        else{ entry = LONG; }
    } 
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
        }
   }
}


void tradeManager() {
    if(PositionsTotal()) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= takeProfit && takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -stopLoss && stopLoss) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= takeProfit && takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -stopLoss && stopLoss ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
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
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

bool testLatency()
{
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
    return  false;
}

input group                                       "============ Perfect Trend Line Settings ===============";
input int inpFastLength = 3; // Fast length
input int inpSlowLength = 7; // Slow length
int PTLHandle = iCustom(NULL, 0, "SPTL2", inpFastLength, inpSlowLength);
bool PTLSELL = false;
bool PTLBUY = false;

bool perfect_trendline_signal(marketSignal signal)
{
    double PTLArray[];
    ArraySetAsSeries(PTLArray, true);
    CopyBuffer(PTLHandle,7,0,2,PTLArray);

    double vArray[];
    ArraySetAsSeries(vArray, true);
    CopyBuffer(PTLHandle,6,0,2,vArray);


    Print("Buffer 6: ", vArray[0]);
    Print("Buffer 7: ", PTLArray[0]);
    if(signal == BUY && PTLArray[0] != EMPTY_VALUE && iOpen(Symbol(), Period(), 0) > PTLArray[0] && !PTLBUY)
    {
        PTLBUY = true;
        PTLSELL = false;
        return true; 
    }
    if(signal == SELL && PTLArray[0] != EMPTY_VALUE && iOpen(Symbol(), Period(), 0) < PTLArray[0] && !PTLSELL)
    {
        PTLBUY = false;
        PTLSELL = true;
        return true; 
    }
    return false;
}
