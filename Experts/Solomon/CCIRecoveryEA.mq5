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
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

int startTime = (int)TimeCurrent();
int currentTime = (int)TimeCurrent();

void OnDeinit(const int reason)
{ 

}

void OnTick() 
{
    if(cci_signal(BUY))
    { 
        close_all_positions(); 
        takeTrade(LONG);
    }
    if(cci_signal(SELL))
    {
        close_all_positions(); 
        takeTrade(SHORT);
    }
    // if(tradingHistory() < 0){
    //     Print("Total Lost Deal Money: $", tradingHistory());
    // }

    // Print("History Deals Total: ", recentLost());
    // tradingHistory();
}

void takeTrade(marketEntry entry) 
{
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    double th = tradingHistory();

    if(entry == LONG && expertIsTakingBuyTrade)
    {
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
        if(th < 0) {
            Print("Lost");
            // trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), bid+th);
            trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));

        }
    }
    if(entry == SHORT && expertIsTakingSellTrade)
    {
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
        if(th < 0){
            Print("Lost");
            // trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), bid-th);
            trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

double tradingHistory(){
    ulong dealTicket;
    double dealProfit, totalDealLost = 0;
    string dealSymbol;
    long dealType;
    int dealLost = 0;
    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()+1; i > 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) {
            continue;
        }

        if(dealProfit < 0){
            dealLost++;
            totalDealLost = totalDealLost + dealProfit;
        }

        if(dealProfit > 0){
            break;
        }

        // if(dealType == ORDER_TYPE_BUY){
        //     dealTypeString = "BUY";
        // }
        // if(dealType == ORDER_TYPE_SELL){
        //     dealTypeString = "SELL";
        // }

        // Print("Trade ", i, " ", dealTypeString, " Profit: ", dealProfit);
    }
    // Print("Total Lost Deal ", dealLost, " Money: $", totalDealLost);


    return totalDealLost;
}
// double recentSwing(marketEntry entry) {
//     double price = iHigh(Symbol(), Period(), 1);
//     if(entry == BUY) {
//         double price = iLow(Symbol(), Period(), 1);
//         for(int i=1; i<100; i++) {
//             if(price < iLow(Symbol(), Period(), i)) {
//                 return price;
//             }
//             if(price > iLow(Symbol(), Period(), i)) {
//                 price = iLow(Symbol(), Period(), i);
//             }
//         }
//     }
//     if(entry == SELL) {
//         for(int i=1; i<100; i++) {
//             if(price > iHigh(Symbol(), Period(), i)) {
//                 return price;
//             }
//             if(price < iHigh(Symbol(), Period(), i)) {
//                 price = iHigh(Symbol(), Period(), i);
//             }
//         }
//     }

// }

input group                                       "============  Commondity Channel Index Settings  ===============";
input bool                                         cciFactor = true; // Use CCI 
input int                                          cciPeriod = 100; // CCI Period
input ENUM_APPLIED_PRICE                           cciAppliedPrice = PRICE_CLOSE; // CCI Applied Price
input int                                          cciOverBoughtLevel = 100; // CCI Overbought Level
input int                                          cciOverSoldLevel = -100; // CCI OverSold Level

bool cciSignalBuy = false;
bool cciSignalSell = false;

bool cciOverSoldSignalCrossUp = false;
bool cciOverSoldSignalCrossDown = false;

bool cciOverBoughtSignalCrossUp = false;
bool cciOverBoughtSignalCrossDown = false;

bool cciComingFromOverbought = false;
bool cciComingFromOversold = false;

bool cci_signal(marketSignal signal){
   if(!cciFactor) return true;
   int cciHandle = iCCI(Symbol(), Period(), cciPeriod, cciAppliedPrice);
   double cciArray[];
   ArraySetAsSeries(cciArray, true);
   CopyBuffer(cciHandle, 0, 0, 3, cciArray);
   double cciValue = cciArray[0];
//    Print("CCI: ", cciValue);
   if(signal == BUY && cciValue > cciOverBoughtLevel && !cciOverBoughtSignalCrossUp)
    {
        // Print("buy signal enter into overbought");
        cciOverBoughtSignalCrossUp = true;
        cciOverBoughtSignalCrossDown = false;

        return true;
    }
    if(signal == BUY && cciComingFromOversold && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverSoldSignalCrossUp)
    {
        // Print("buy signal coming from oversold");
        cciOverSoldSignalCrossUp = true;
        cciOverSoldSignalCrossDown = false;
        
        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(signal == SELL && cciValue < cciOverSoldLevel && !cciOverSoldSignalCrossDown)
    {
        // Print("sell signal enter into oversold");
        cciOverSoldSignalCrossUp = false;
        cciOverSoldSignalCrossDown = true;

        return true;
    }
    if(signal == SELL && cciComingFromOverbought && cciValue > cciOverSoldLevel && cciValue < cciOverBoughtLevel && !cciOverBoughtSignalCrossDown)
    {
        // Print("sell signal coming from overbought");
        cciOverBoughtSignalCrossUp = false;
        cciOverBoughtSignalCrossDown = true;

        cciComingFromOversold = false;
        cciComingFromOverbought = false;

        return true;
    }
    if(cciValue < cciOverSoldLevel)
    {
        // Print("Oversold");
        cciComingFromOversold = true;
        cciComingFromOverbought = false;
    }
    if(cciValue > cciOverBoughtLevel)
    {
        // Print("Overbought");
        cciComingFromOversold = false;
        cciComingFromOverbought = true;
    }
    return false;
}