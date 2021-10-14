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

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          closeTradeOnNewSignal = true; // Close Trade on New Signal
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        recoveryLotSize = 0.1; // Recovery Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input double                                        recoveryCount = 1; // Recovery Count
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery

static datetime timestamp;

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
   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
        timestamp = time;
        tradeManager();
        if(q_signal(BUY) && ma_signal(BUY)) { 
            if(closeTradeOnNewSignal) { close_trade(BUY); }
            if(expertIsTakingBuyTrade) { takeTrade(LONG); }
        }
        if(q_signal(SELL) && ma_signal(SELL)) {
            if(closeTradeOnNewSignal) { close_trade(SELL); }
            if(expertIsTakingSellTrade) { takeTrade(SHORT); }
        }  
    }
}

void takeTrade(marketEntry entry) {
   if(entry == LONG) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLostCount() >= recoveryCount && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(LONG);
        }
   }
   if(entry == SHORT) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLostCount() >= recoveryCount && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(SHORT);
        }
   }
}

void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {       
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "recovery");
    }
}

double getPreviousDealLostCount() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0.0;
    double count=0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + dealProfit; count = count+1; }

        if(dealProfit > 0) { break; }

    }
    return count;
}

void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetDouble(POSITION_PROFIT) >= takeProfit) {
            trade.PositionClose(PositionGetSymbol(i));
        }
        if(PositionGetDouble(POSITION_PROFIT) <= -(stopLoss)) {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void close_trade(marketSignal signal) {
    if(PositionsTotal() && signal == BUY) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                qProfit = true;
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
    if(PositionsTotal() && signal == SELL) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

bool qBuy = false;
bool qSell = false;
bool qProfit = false;
bool q_signal(marketSignal signal)
{
   if(signal == BUY && iHigh(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && !qProfit) {
        qBuy = true;
        qSell = false;
        qProfit = false;
        return true;
    }
    if(signal == SELL && iLow(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) && !PositionsTotal()) {
        qBuy = false;
        qSell = true;
        return true;
    }
    return false;
}


input group                                       "============  Moving Average Settings  ===============";
input bool                                         maFactor = true; // Use Moving Average 
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price
input ENUM_TIMEFRAMES                              maPeriod = PERIOD_M1; // Moving Average Period;

bool maBUY = false;
bool maSELL = false;

int FastMovingAverageHandle = iMA(Symbol(), maPeriod, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(Symbol(), maPeriod, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(marketSignal signal ){
    if(!maFactor) return true;
    double FastMovingAverageArray[];
    double SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) {
        return true; 
    } 
    if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        return true; 
    }
    return false;
}


