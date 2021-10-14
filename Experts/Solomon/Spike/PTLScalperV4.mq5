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
input double                                        stopLoss = 1; // Stop Loss %Constant-K%
input double                                        takeProfit = 0.5; // Take Profit %Constant-K%
input group                                         "============  Swing Settings ===============";
input int                                           swingPeriod = 5; // Swing Period 
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

double tradeTakeProfit = 0.0;
double tradeStopLoss = 0.0;

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

    if(testLatency()) {
        
        if(perfect_trendline_signal(BUY)) {
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(LONG);
        }
        if(perfect_trendline_signal(SELL)) {
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
        double swingPrice = recentSwing(LONG);
        double dynamicPIP =  MathMax(swingPrice, ask) - MathMin(swingPrice, ask);
        tradeTakeProfit = NormalizeDouble(dynamicPIP * takeProfit, _Digits);
        tradeStopLoss = NormalizeDouble(dynamicPIP * stopLoss, _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, ask-tradeStopLoss, ask+tradeTakeProfit);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double swingPrice = recentSwing(SHORT);
        double dynamicPIP = MathMax(swingPrice, bid) - MathMin(swingPrice, bid);
        tradeTakeProfit = NormalizeDouble(dynamicPIP * takeProfit, _Digits);
        tradeStopLoss = NormalizeDouble(dynamicPIP * stopLoss, _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid+tradeStopLoss, bid-tradeTakeProfit);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
        }
   }
}

double recentSwing(marketEntry entry) {
    double swingPrice = 0.0;
    if(entry == LONG) {
        swingPrice = iLow(Symbol(), Period(), 1);
        for(int i=1; i<=swingPeriod; i++) {
            if(swingPrice < iLow(Symbol(), Period(), i)) {
                return swingPrice;
            }
            if(swingPrice > iLow(Symbol(), Period(), i)) {
                swingPrice = iLow(Symbol(), Period(), i);
            }
        }
    }
    if(entry == SHORT) {
        swingPrice = iHigh(Symbol(), Period(), 1);
        for(int i=1; i<=swingPeriod; i++) {
            if(swingPrice > iHigh(Symbol(), Period(), i)) {
                return swingPrice;
            }
            if(swingPrice < iHigh(Symbol(), Period(), i)) {
                swingPrice = iHigh(Symbol(), Period(), i);
            }
        }
    }
    return 0;

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


input group                                       "============ Perfect Trend Line Settings ===============";
input int inpFastLength = 3; // Fast length
input int inpSlowLength = 7; // Slow length

int PTLHandle = iCustom(Symbol(), Period(), "PTL2", inpFastLength, inpSlowLength);
bool PTLSELL = false;
bool PTLBUY = false;

bool perfect_trendline_signal(marketSignal signal)
{
    double PTLArray[];
    ArraySetAsSeries(PTLArray, true);
    CopyBuffer(PTLHandle,7,1,3,PTLArray);
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
