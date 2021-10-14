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
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input int                                           expertTimer = 10; // Trade timer
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input double                                        valuePerPips = 0.0; // Value Per Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoverySmallestLotSize = 0.1; // Recovery Smallest Lot Size
input double                                        recoveryBiggestLotSize = 0.1; // Recovery Biggest Lot Size
input double                                        recoveryPips = 0.0; // Recovery in Pips
input double                                        recoveryStopLoss = 0; // Recovery Stop Loss

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

    if(tradeCurrentTime - tradeStartTime >= expertTimer) 
    { 
        tradeStartTime = tradeCurrentTime;
        if(deMarker_signal(BUY))
        { 
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(LONG);
        }
        if(deMarker_signal(SELL))
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

double setStopLoss(double price, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   if(entry == LONG){ return price-stopLoss; }
   if(entry == SHORT){ return price+stopLoss; }
   return 0.0;
}

double setTakeProfit(double price, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  price+takeProfit; }
   if(entry == SHORT){ return price-takeProfit; } 
   return 0.0;
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}


void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double recoveryLotSize = NormalizeDouble( dealLost / (recoveryPips * valuePerPips), 2);

        if( recoveryLotSize < recoverySmallestLotSize ) { recoveryLotSize = recoverySmallestLotSize; }
        if( recoveryLotSize > recoveryBiggestLotSize ) { recoveryLotSize = recoveryBiggestLotSize; }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, setRecoveryStopLoss(ask, LONG), ask+recoveryPips, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double recoveryLotSize = NormalizeDouble( dealLost / (recoveryPips * valuePerPips), 2);

        if( recoveryLotSize < recoverySmallestLotSize ) { recoveryLotSize = recoverySmallestLotSize; }
        if( recoveryLotSize > recoveryBiggestLotSize ) { recoveryLotSize = recoveryBiggestLotSize; }

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

double setRecoveryStopLoss(double price, marketEntry entry)
{
   if(!recoveryStopLoss){ return 0.0; }
   if(entry == LONG){ return price-recoveryStopLoss; }
   if(entry == SHORT){ return price+recoveryStopLoss; }
   return 0.0;
}

/* 
Version 1: Arrow to Arrow
Levels: 2
Behave exactly like wpr


Version 2: Arrow to Arrow
Levels: 2
Buy Low sell high
Close Sell When open Buying trade and vis visa

Note: Break Even
*/

input group                                       "============  DeMarker Settings  ===============";
input bool                                         deMarkerFactor = true; // Use DeMarker 
input int                                          deMarkerPeriod = 14; // DeMarker Period
input double                                       deMarkerOverBoughtLevel = 0.9; // DeMarker Overbought Level
input double                                       deMarkerOverSoldLevel = 0.1; // DeMarker OverSold Level

bool deMarkerOverSoldSignalCrossUp = false;
bool deMarkerOverSoldSignalCrossDown = false;

bool deMarkerOverBoughtSignalCrossUp = false;
bool deMarkerOverBoughtSignalCrossDown = false;

bool deMarkerComingFromOverbought = false;
bool deMarkerComingFromOversold = false;

int deMarkerHandle = iDeMarker(Symbol(), Period(), deMarkerPeriod);

bool deMarker_signal(marketSignal signal){
   if(!deMarkerFactor) return true;
   double deMarkerArray[];
   ArraySetAsSeries(deMarkerArray, true);
   CopyBuffer(deMarkerHandle, 0, 0, 3, deMarkerArray);
   double deMarkerValue = deMarkerArray[0];
//    Print("Price Value: ", deMarkerValue);
   if(signal == BUY && deMarkerValue > deMarkerOverBoughtLevel && !deMarkerOverBoughtSignalCrossUp)
    {
        // Print("deMarker OverBought Signal CrossUp");
        deMarkerOverBoughtSignalCrossUp = true;
        deMarkerOverBoughtSignalCrossDown = false;

        deMarkerOverSoldSignalCrossUp = false;
        deMarkerOverSoldSignalCrossDown = false;
        
        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = false;

        return true;
    }
    if(signal == BUY && deMarkerComingFromOversold && deMarkerValue > deMarkerOverSoldLevel && deMarkerValue < deMarkerOverBoughtLevel && !deMarkerOverSoldSignalCrossUp)
    {
        // Print("deMarker OverSold Signal CrossUp");
        deMarkerOverSoldSignalCrossUp = true;
        deMarkerOverSoldSignalCrossDown = false;
        
        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = false;
        
        deMarkerOverBoughtSignalCrossUp = false;
        deMarkerOverBoughtSignalCrossDown = false;

        return true;
    }
    if(signal == SELL && deMarkerValue < deMarkerOverSoldLevel && !deMarkerOverSoldSignalCrossDown)
    {
        // Print("deMarker OverSold Signal CrossDown");
        deMarkerOverSoldSignalCrossUp = false;
        deMarkerOverSoldSignalCrossDown = true;
        
        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = false;
        
        deMarkerOverBoughtSignalCrossUp = false;
        deMarkerOverBoughtSignalCrossDown = false;

        return true;
    }
    if(signal == SELL && deMarkerComingFromOverbought && deMarkerValue > deMarkerOverSoldLevel && deMarkerValue < deMarkerOverBoughtLevel && !deMarkerOverBoughtSignalCrossDown)
    {
        // Print("deMarker OverBought Signal CrossDown");
        deMarkerOverBoughtSignalCrossUp = false;
        deMarkerOverBoughtSignalCrossDown = true;

        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = false;
        
        deMarkerOverSoldSignalCrossUp = false;
        deMarkerOverSoldSignalCrossDown = false;

        return true;
    }
    if(deMarkerValue < deMarkerOverSoldLevel)
    {
        // Print("OverSold");
        deMarkerComingFromOversold = true;
        deMarkerComingFromOverbought = false;
    }
    if(deMarkerValue > deMarkerOverBoughtLevel)
    {
        // Print("Overbought");
        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = true;
    }
    return false;
}

