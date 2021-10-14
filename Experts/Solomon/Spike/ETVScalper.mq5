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
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        smallestLotSize = 0.1; // Smallest Lot Size
input double                                        biggestLotSize = 0.1; // Biggest Lot Size
input double                                        stopLoss = 0; // Stop Loss %Constant-K%
input double                                        takeProfit = 0; // Take Profit %Constant-K%
input double                                        recoveryStopLoss = 0; // Recovery Stop Loss %Constant-K%
input double                                        recoveryTakeProfit = 0; // Recovery Take Profit %Constant-K%
input double                                        recoveryLotSize = 0; // Recovery Lot Size %Constant-K%
input int                                           expertTradeTime = 50; // Time to trade
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
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

    if(tradeCurrentTime - tradeStartTime >= expertTradeTime) 
    { 
        tradeStartTime = tradeCurrentTime;

        if(etv_signal(BUY))
        { 
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(LONG);
        }
        if(etv_signal(SELL))
        {
            if(closeOnOppositeSignal) { close_all_positions(); }
            takeTrade(SHORT);
        }
    }
}

void takeTrade(marketEntry entry) {  
    if(expertTradeBehaviour == OPPOSITE ) {
        if( entry == LONG ) { entry = SHORT; }
        else{ entry = LONG; }
    }   
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double swingPrice = recentSwing(LONG);
        double dynamicPip = MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, setStopLoss(ask, dynamicPip, LONG), setTakeProfit(ask, dynamicPip, LONG));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(LONG);
        }
    }
    if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double swingPrice = recentSwing(SHORT);
        double dynamicPip = MathMax(swingPrice, bid) - MathMin(swingPrice, bid);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, dynamicPip, SHORT), setTakeProfit(bid, dynamicPip, SHORT));
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(SHORT);
        }
    }
}

double setStopLoss(double price, double pips, marketEntry entry) {
   if(!stopLoss){ return 0.0; }
   if(entry == LONG) { return price - (pips * stopLoss); }
   if(entry == SHORT){ return price + (pips * stopLoss); }
   return 0.0;
}

double setTakeProfit(double price, double pips, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  price + (pips * takeProfit); }
   if(entry == SHORT){ return price - (pips * takeProfit); } 
   return 0.0;
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            // ulong ticket = PositionGetTicket(i);
            // trade.PositionClose(ticket);
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(LONG);
        double recoveryPips = MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(setRecoveryLotSize(dealLost, recoveryPips), Symbol(), ask, setRecoveryStopLoss(ask, recoveryPips, LONG), setRecoveryTakeProfit(ask, recoveryPips, LONG), "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(SHORT);
        double recoveryPips = MathMax(swingPrice, bid) - MathMin(swingPrice, bid) ;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(setRecoveryLotSize(dealLost, recoveryPips), Symbol(), bid, setRecoveryStopLoss(bid, recoveryPips, SHORT), setRecoveryTakeProfit(bid, recoveryPips, SHORT),  "Recovery");
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

double setRecoveryLotSize(double dealLost, double pips) {
   if(!recoveryLotSize){ return smallestLotSize; }
    double newRecoveryLotSize = 0.0;
    double recoveryPips = pips * recoveryLotSize;
    if( (dealLost/recoveryPips) < smallestLotSize ) { newRecoveryLotSize = smallestLotSize; }
    else if( (dealLost/recoveryPips) > biggestLotSize ) { newRecoveryLotSize = biggestLotSize; }
    else { newRecoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 2); }
    return newRecoveryLotSize;
}

double setRecoveryStopLoss(double price, double pips, marketEntry entry) {
   if(!stopLoss){ return 0.0; }
   if(entry == LONG) { return price - (pips * recoveryStopLoss); }
   if(entry == SHORT){ return price + (pips * recoveryStopLoss); }
   return 0.0;
}

double setRecoveryTakeProfit(double price, double pips, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  price + (pips * recoveryTakeProfit); }
   if(entry == SHORT){ return price - (pips * recoveryTakeProfit); } 
   return 0.0;
}

input group                                       "============  ETV Settings  ===============";

bool maBUY = false;
bool maSELL = false;

int etvHandle = iCustom(NULL, 0, "ETV");

bool etv_signal(marketSignal signal)
{
   double etvSell[], etvBuy[];
   ArraySetAsSeries(etvSell, true);
   ArraySetAsSeries(etvBuy, true);
   CopyBuffer(etvHandle, 3, 0, 3, etvBuy);
   CopyBuffer(etvHandle, 4, 0, 3, etvSell);
   if(signal == BUY && etvBuy[1] != EMPTY_VALUE) { return true; }
   if(signal == SELL && etvSell[1] != EMPTY_VALUE) { return true; }
   return false;
}

