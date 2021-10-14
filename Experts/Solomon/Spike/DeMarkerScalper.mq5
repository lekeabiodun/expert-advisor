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
input double                                        valuePerPips = 1.0; // Value Per Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoverySmallestLotSize = 0.1; // Recovery Smallest Lot Size
input double                                        recoveryBiggestLotSize = 0.1; // Recovery Biggest Lot Size
input double                                        recoveryTP = 0.0; // Recovery TP in Pips
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



void close_trade(marketSignal signal) {
    if(PositionsTotal() && signal == BUY) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
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
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double recoveryLotSize = NormalizeDouble( dealLost / (recoveryTP * valuePerPips), 2);

        if( recoveryLotSize < recoverySmallestLotSize ) { recoveryLotSize = recoverySmallestLotSize; }
        if( recoveryLotSize > recoveryBiggestLotSize ) { recoveryLotSize = recoveryBiggestLotSize; }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, setRecoveryStopLoss(ask, LONG), ask+recoveryTP, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double recoveryLotSize = NormalizeDouble( dealLost / (recoveryTP * valuePerPips), 2);

        if( recoveryLotSize < recoverySmallestLotSize ) { recoveryLotSize = recoverySmallestLotSize; }
        if( recoveryLotSize > recoveryBiggestLotSize ) { recoveryLotSize = recoveryBiggestLotSize; }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, setRecoveryStopLoss(bid, SHORT), bid-recoveryTP, "Recovery");
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

double setRecoveryStopLoss(double price, marketEntry entry)
{
   if(!recoveryStopLoss){ return 0.0; }
   if(entry == LONG){ return price-recoveryStopLoss; }
   if(entry == SHORT){ return price+recoveryStopLoss; }
   return 0.0;
}

input group                                       "============  DeMarker Settings  ===============";
input bool                                         deMarkerFactor = true; // Use DeMarker 
input int                                          deMarkerPeriod = 14; // DeMarker Period
input double                                       deMarkerTradeZone = 0; // DeMarker Trade Zone Level

bool deMarkerBuy = false;
bool deMarkerSell = false;
int deMarkerHandle = iDeMarker(Symbol(), Period(), deMarkerPeriod);

bool deMarker_signal(marketSignal signal)
{
   if(!deMarkerFactor) return true;
   double deMarkerArray[];
   ArraySetAsSeries(deMarkerArray, true);
   CopyBuffer(deMarkerHandle, 0, 0, 3, deMarkerArray);
   double deMarkerValue = deMarkerArray[0];
   if(signal == BUY && deMarkerValue > deMarkerTradeZone && !deMarkerBuy)
    {
        deMarkerBuy = true;
        deMarkerSell = false;
        return true;
    }
    if(signal == SELL && deMarkerValue < deMarkerTradeZone && !deMarkerSell)
    {
        deMarkerBuy = false;
        deMarkerSell = true;
        return true;
    }
    return false;
}


