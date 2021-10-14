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
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        smallestLotSize = 0.1; // Smallest Lot Size
input double                                        biggestLotSize = 0.1; // Biggest Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade

static datetime timestamp;

void OnDeinit(const int reason) { }

void OnTick() 
{
    // double minVolume =  SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    // Print("min VOlume: ", minVolume);
    // Print("min VOlume Normalize: ", NormalizeDouble(minVolume));
    // Print("min VOlume floor: ", floor(minVolume));
    // string mvToString = DoubleToString(minVolume);
    // Print("mvToString: ", mvToString);
    // string  result[];
    // ushort sep= '.';
    // int spliTstring = StringSplit(mvToString, sep, result);
    
    // Print("String: ", (result[ArraySize(result)-1]) );
    // Print("DOuble: ", StringToDouble(result[ArraySize(result)-1]) );
    // Print("Integer: ", StringToInteger(result[ArraySize(result)-1]) );

    // // Print("Lenght after the dot: ", ttt);
    

    // // Print("Volume: ", SymbolInfoInteger(Symbol(), SYMBOL_VOLUME));
    // // Print("Max Volume: ", SymbolInfoInteger(Symbol(), SYMBOL_VOLUMEHIGH));
    // // Print("Min Volume: ", SymbolInfoInteger(Symbol(), SYMBOL_VOLUMELOW));
    // // Print("Digits: ", SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
    // // Print("Spread: ", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD));
    // Print("Spread Float: ", SymbolInfoInteger(Symbol(), SYMBOL_SPREAD_FLOAT));
    // // Print("Point Value: ", SymbolInfoDouble(Symbol(), SYMBOL_POINT));
    // // Print("Contract Size: ", SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE));
    // // Print("Volume Min: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN));
    // // Print("Volume Max: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX));
    // // Print("Volume Step: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP));
    // // Print("Volume limit: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT));

    // // Print("Normalize Double: ", NormalizeDouble(0.23787663312, SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) );
    // // Print("Normalize Double: ", NormalizeDouble(20.23787663312, SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) );
    // // Print("Normalize Double: ", NormalizeDouble(20, SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) );
    // // Print("Normalize Double: ", NormalizeDouble(20, SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) );
    // // Print("Normalize Double: ", NormalizeDouble(0.23787663312, SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) );
    // // Print("Normalize Double: ", NormalizeDouble(0.005695959, SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)) );
    // // Print("Normalize Double: ", Digits());
    // // Print("Contract SIze: ", SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE));
    

    

    
    if(wpr_signal(BUY))
    { 
        close_all_positions(); 
        takeTrade(LONG);
    }
    if(wpr_signal(SELL))
    {
        close_all_positions(); 
        takeTrade(SHORT);
    }

    // 1 Samuel 30:8 King James Version
    // And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them? 
    // And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.    
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost();
        double swingPrice = recentSwing(LONG);
        double recoveryPips = ( MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ) / 2;
        double recoveryLotSize = 0.0;

        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 3); }

        Print("swingPrice Recent Swing: ", swingPrice);
        Print("ask Recent Swing: ", ask);
        Print("recoveryLotsize Recent Swing: ", recoveryLotSize);
        Print("recoveryPips Recent Swing: ", recoveryPips);

        // trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, ask-recoveryPips, ask+recoveryPips);
    }
    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost();
        double swingPrice = recentSwing(SHORT);
        double recoveryPips = ( MathMax(swingPrice, bid) - MathMin(swingPrice, bid) ) / 2;
        double recoveryLotSize = 0.0;

        Print("swingPrice Recent Swing: ", swingPrice);
        Print("Bid Recent Swing: ", bid);
        Print("recoveryLotsize Recent Swing: ", recoveryLotSize);
        Print("recoveryPips Recent Swing: ", recoveryPips);

        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 3); }

        // trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, bid+recoveryPips, bid-recoveryPips);
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
input int                                          wprOverBoughtLevel = -20; // WPR Overbought Level
input int                                          wprOverSoldLevel = -80; // WPR OverSold Level

bool wprSignalBuy = false;
bool wprSignalSell = false;

bool wprOverSoldSignalCrossUp = false;
bool wprOverSoldSignalCrossDown = false;

bool wprOverBoughtSignalCrossUp = false;
bool wprOverBoughtSignalCrossDown = false;

bool wprComingFromOverbought = false;
bool wprComingFromOversold = false;

bool wpr_signal(marketSignal signal){
   if(!wprFactor) return true;
   int wprHandle = iWPR(Symbol(), Period(), wprPeriod);
   double wprArray[];
   ArraySetAsSeries(wprArray, true);
   CopyBuffer(wprHandle, 0, 0, 3, wprArray);
   double wprValue = wprArray[0];

   if(signal == BUY && wprValue > wprOverBoughtLevel && !wprOverBoughtSignalCrossUp)
    {
        wprOverBoughtSignalCrossUp = true;
        wprOverBoughtSignalCrossDown = false;
        return true;
    }
    if(signal == BUY && wprComingFromOversold && wprValue > wprOverSoldLevel && wprValue < wprOverBoughtLevel && !wprOverSoldSignalCrossUp)
    {
        wprOverSoldSignalCrossDown = false;
        wprOverSoldSignalCrossUp = true;
        
        wprComingFromOversold = false;
        wprComingFromOverbought = false;
        return true;
    }
    if(signal == SELL && wprComingFromOverbought && wprValue > wprOverSoldLevel && wprValue < wprOverBoughtLevel && !wprOverBoughtSignalCrossDown)
    {
        wprOverBoughtSignalCrossUp = false;
        wprOverBoughtSignalCrossDown = true;

        wprComingFromOversold = false;
        wprComingFromOverbought = false;
        return true;
    }
    if(signal == SELL && wprValue < wprOverSoldLevel && !wprOverSoldSignalCrossDown) {
        wprOverSoldSignalCrossDown = true;
        wprOverSoldSignalCrossUp = false;
        return true;
    }
    if(wprValue < wprOverSoldLevel) {
        wprComingFromOversold = true;
        wprComingFromOverbought = false;
    }
    if(wprValue > wprOverBoughtLevel) {
        wprComingFromOversold = false;
        wprComingFromOverbought = true;
    }
    return false;
}