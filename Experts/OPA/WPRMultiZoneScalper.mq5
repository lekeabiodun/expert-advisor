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
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertTradeBehaviour = REGULAR; // Trading Behaviour
input int                                           expertTradeTime = 60; // Trade Time
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1.0; // Lot Size
input double                                        smallestLotSize = 0.1; // Smallest Lot Size
input double                                        biggestLotSize = 0.1; // Biggest Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = true; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = true; // Take Sell Trade
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade

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

    if(tradeCurrentTime - tradeStartTime >= expertTradeTime) 
    { 
        tradeStartTime = tradeCurrentTime;

        if(wpr_signal(BUY)) {
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(LONG);
        }
        if(wpr_signal(SELL)) {
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(SHORT);
        }
    }
}

void takeTrade(marketEntry entry) {   
    if(expertTradeBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else{ entry = LONG; }   
   }   
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, setStopLoss(ask, LONG), setTakeProfit(ask, LONG));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade) {
            takeRecoveryTrade(LONG);
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade) {
            takeRecoveryTrade(SHORT);
        }
   }
}

double setStopLoss(double bid, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}

void close_all_positions()
{
    if(PositionsTotal())
    {
        for(int i=0; i < PositionsTotal(); i++)
        {
            trade.PositionClose(PositionGetSymbol(i));
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
        trade.Buy(recoveryLotSize, Symbol(), ask, 0, ask+recoveryPips, "Recovery");
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
        trade.Sell(recoveryLotSize, Symbol(), bid, 0, bid-recoveryPips, "Recovery");
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

input group                                       "============  Williams Percentage Settings  ===============";
input bool                                         wprFactor = true; // Use WPR 
input int                                          wprPeriod = 100; // WPR Period
input int                                          wprOverBoughtZone = -10; // WPR Overbought Zone
input int                                          wprBuyZone = -30; // WPR Buy Zone
input int                                          wprMiddleZone = -50; // WPR Middle Zone
input int                                          wprSellZone = -70; // WPR Sell Zone
input int                                          wprOverSoldZone = -90; // WPR OverSold Zone

bool wprBuyZoneCrossUp = false;
bool wprBuyZoneCrossDown = false;

bool wprOverBoughtZoneCrossUp = false;
bool wprOverBoughtZoneCrossDown = false;

bool wprMiddleZoneCrossUp = false;
bool wprMiddleZoneCrossDown = false;

bool wprSellZoneCrossUp = false;
bool wprSellZoneCrossDown = false;

bool wprOverSoldZoneCrossUp = false;
bool wprOverSoldZoneCrossDown = false;

bool wprComingFromOverbought = false;
bool wprComingFromOversold = false;


int wprHandle = iWPR(_Symbol, Period(), wprPeriod);

bool wpr_signal(marketSignal signal){
    if(!wprFactor) { return true; }
    double wprArray[];
    ArraySetAsSeries(wprArray, true);
    CopyBuffer(wprHandle, 0, 0, 2, wprArray);
    double wprValue = wprArray[0];
    if(signal == BUY && wprValue > wprOverBoughtZone && !wprOverBoughtZoneCrossUp) {
        wprOverBoughtZoneCrossUp = true;
        wprOverBoughtZoneCrossDown = false;
        return true;
    }
    if(signal == BUY && wprValue > wprBuyZone && wprValue < wprOverBoughtZone && !wprBuyZoneCrossUp) {
        wprBuyZoneCrossUp = true;
        wprBuyZoneCrossDown = false;
        return true;
    }
    if(signal == BUY && wprValue > wprMiddleZone && wprValue < wprBuyZone && !wprMiddleZoneCrossUp) {
        wprMiddleZoneCrossUp = true;
        wprMiddleZoneCrossDown = false;
        return true;
    }
    if(signal == BUY && wprValue > wprSellZone && wprValue < wprMiddleZone && !wprSellZoneCrossUp) {
        wprSellZoneCrossUp = true;
        wprSellZoneCrossDown = false;
        return true;
    }
    if(signal == BUY && wprComingFromOversold && wprValue > wprOverSoldZone && wprValue < wprSellZone && !wprOverSoldZoneCrossUp) {
        wprOverSoldZoneCrossUp = true;
        wprOverSoldZoneCrossDown = false;

        wprComingFromOversold = false;
        wprComingFromOverbought = false;
        return true;
    }
    if(signal == SELL && wprComingFromOverbought && wprValue < wprOverBoughtZone && wprValue > wprBuyZone && !wprOverBoughtZoneCrossDown) {
        wprOverBoughtZoneCrossUp = false;
        wprOverBoughtZoneCrossDown = true;

        wprComingFromOversold = false;
        wprComingFromOverbought = false;
        return true;
    }
    if(signal == SELL && wprValue < wprBuyZone && wprValue > wprMiddleZone && !wprBuyZoneCrossDown) {
        wprBuyZoneCrossUp = false;
        wprBuyZoneCrossDown = true;
        return true;
    }
    if(signal == SELL && wprValue < wprMiddleZone && wprValue > wprSellZone && !wprMiddleZoneCrossDown) {
        wprMiddleZoneCrossUp = false;
        wprMiddleZoneCrossDown = true;
        return true;
    }
    if(signal == SELL && wprValue < wprSellZone && wprValue > wprOverSoldZone && !wprSellZoneCrossDown) {
        wprSellZoneCrossUp = false;
        wprSellZoneCrossDown = true;
        return true;
    }
    if(signal == SELL && wprValue < wprOverSoldZone && !wprOverSoldZoneCrossDown) {
        wprOverSoldZoneCrossUp = false;
        wprOverSoldZoneCrossDown = true;
        return true;
    }
    if(wprValue < wprOverSoldZone) {
        wprComingFromOversold = true;
        wprComingFromOverbought = false;
    }
    if(wprValue > wprOverBoughtZone) {
        wprComingFromOversold = false;
        wprComingFromOverbought = true;
    }
    return false;
}