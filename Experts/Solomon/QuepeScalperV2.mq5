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
input int                                           EXPERT_MAGIC = 11235813;     // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        smallestLotSize = 0.1; // Smallest Lot Size
input double                                        biggestLotSize = 0.1; // Biggest Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        recoveryStopLoss = 0.0; // Recovery Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input int                                           tradeTime = 50; // Time to trade
input group                                         "============  Candle Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Buy On Uptrend
input bool                                          expertIsTakingSellTrade = false; // Sell On Downtrend
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade


static datetime timestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();


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
   tradeTimer();
   datetime time = iTime(Symbol(), PERIOD_M1, 0);
   if(timestamp != time) {
        timestamp = time;
        if(ma_signal(BUY)) {
            takeTrade(LONG);
        }
        if(ma_signal(SELL)) {
            takeTrade(SHORT);  
        }
   }
}

void takeTrade(marketEntry entry) {      
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, setStopLoss(ask, LONG), setTakeProfit(ask, LONG));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(LONG);
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(SHORT);
        }
   }
}

double setStopLoss(double bid, marketEntry entry) {
   if(!stopLoss){ return 0.0; }
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry) {
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}

void tradeTimer()
{
    if(PositionsTotal() && tradeTime) {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime) {
            for(int i=0; i < PositionsTotal(); i++) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
    if(OrdersTotal() && tradeTime) {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime) {
            trade.OrderDelete(OrderGetTicket(0));
        }
    }
}


void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(LONG);
        double recoveryPips = ( MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ) / 2;
        double recoveryLotSize = 0.0;
        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 2); }
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, setRecoveryStopLoss(ask, LONG), ask+recoveryPips, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(SHORT);
        double recoveryPips = ( MathMax(swingPrice, bid) - MathMin(swingPrice, bid) ) / 2;
        double recoveryLotSize = 0.0;
        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 2); }
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, setRecoveryStopLoss(bid, SHORT), bid-recoveryPips, "Recovery");
    }
}

double getPreviousDealLost() {
    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0.0;
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

double recentSwing(marketEntry entry) {
    double swingPrice = 0.0;
    if(entry == LONG) {
        swingPrice = iLow(Symbol(), Period(), 1);
        for(int i=1; i<100; i++) {
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
        for(int i=1; i<100; i++) {
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

double setRecoveryStopLoss(double bid, marketEntry entry)
{
   if(!recoveryStopLoss){ return 0.0; }
   if(entry == LONG){ return bid-recoveryStopLoss; }
   if(entry == SHORT){ return bid+recoveryStopLoss; }
   return 0.0;
}


input group                                       "============  Trend Moving Average Settings  ===============";
input bool                                         trendFactor = true; // Use Trend Moving Average
input ENUM_TIMEFRAMES                              trendTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          fastMasterMA = 1; // Trend Fast Moving Average
input int                                          fastMasterMAShift = 0; // Trend Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMasterMAMethod = MODE_LWMA; // Trend Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMasterMAAppliedPrice = PRICE_CLOSE; // Trend Fast Moving Average Applied Price
input int                                          slowMasterMA = 50; // Trend Slow Moving Average
input int                                          slowMasterMAShift = 0; // Trend Slow Moving Average Shift
input ENUM_MA_METHOD                               slowMasterMAMethod = MODE_LWMA; // Trend Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMasterMAAppliedPrice = PRICE_LOW; // Trend Slow Moving Average Applied Price

int FastMasterMovingAverageHandle = iMA(_Symbol, trendTimeframe, fastMasterMA, fastMasterMAShift, fastMasterMAMethod, fastMasterMAAppliedPrice);
int SlowMasterMovingAverageHandle = iMA(_Symbol, trendTimeframe, slowMasterMA, slowMasterMAShift, slowMasterMAMethod, slowMasterMAAppliedPrice);

bool ma_signal(marketSignal signal){
   if(!trendFactor) return true;
   double FastMasterMovingAverageArray[];
   double SlowMasterMovingAverageArray[];
   ArraySetAsSeries(FastMasterMovingAverageArray, true);
   ArraySetAsSeries(SlowMasterMovingAverageArray, true);
   CopyBuffer(FastMasterMovingAverageHandle, 0, 1, 2, FastMasterMovingAverageArray);
   CopyBuffer(SlowMasterMovingAverageHandle, 0, 1, 2, SlowMasterMovingAverageArray);
   if(signal == BUY && FastMasterMovingAverageArray[0] > SlowMasterMovingAverageArray[0]) { return true; }
   else if(signal == SELL && FastMasterMovingAverageArray[0] < SlowMasterMovingAverageArray[0]) { return true; }
   return false;
}
