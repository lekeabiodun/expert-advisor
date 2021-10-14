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
input double                                        recoveryStopLoss = 0.0; // Recovery Stop Loss in Pips
input int                                           expertTradeTime = 50; // Time to trade
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade

static datetime timestamp;

int startTime = (int)TimeCurrent();
int currentTime = (int)TimeCurrent();

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
    datetime time = iTime(Symbol(), Period(), 0);
      
    if(timestamp != time) {
   
        timestamp = time;

        if(etv_signal(BUY))
        { 
            close_all_positions(); 
            takeTrade(LONG);
        }
        if(etv_signal(SELL))
        {
            close_all_positions(); 
            takeTrade(SHORT);
        }
    }
}

void takeTrade(marketEntry entry) {      
  
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double swingPrice = recentSwing(LONG);
        double dynamicPip = ( MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ) / 2;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, setStopLoss(ask, LONG), ask+dynamicPip);
        if(getPreviousDealLost() < 0 && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(LONG);
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double swingPrice = recentSwing(SHORT);
        double dynamicPip = ( MathMax(swingPrice, bid) - MathMin(swingPrice, bid) ) / 2;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), bid - dynamicPip);
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
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
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

void tradeMgt() {
    if(PositionsTotal() && expertTradeTime) {
        if((currentTime - startTime) >= expertTradeTime) {
            close_all_positions();
        }
    }
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
   CopyBuffer(etvHandle, 4, 0, 3, etvSell);
   CopyBuffer(etvHandle, 3, 0, 3, etvBuy);
   if(signal == BUY && etvBuy[0] != EMPTY_VALUE) { return true; }
   if(signal == SELL && etvSell[0] != EMPTY_VALUE) { return true; }
   return false;
}

