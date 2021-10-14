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
/*


*/
input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          closeTradeOnNewSignal = true; // Close Trade on New Signal
// input int                                           expertTimer = 60; // Trade timer
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        recoveryLotSize = 10; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input double                                        recoveryCount = 1; // Recovery Count
input double                                        valuePerPips = 1.0; // Value Per Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
static datetime timestamp;

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
    datetime time = iTime(Symbol(), PERIOD_M1, 0);

    if(timestamp != time) {

        tradeManager();

        timestamp = time;

        if(deMarker_signal(BUY))
        { 
            if(closeTradeOnNewSignal) { close_all_positions(); }
            if(expertIsTakingBuyTrade) { takeTrade(LONG); }
        }
        if(deMarker_signal(SELL))
        {
            if(closeTradeOnNewSignal) { close_all_positions(); }
            if(expertIsTakingSellTrade) { takeTrade(SHORT); }
        }  
    }
}

void takeTrade(marketEntry entry) {
    if(expertBehaviour == OPPOSITE ) {
        if( entry == LONG ) { entry = SHORT; }
        else{ entry = LONG; }
    } 
   if(entry == LONG) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(LONG);
        }
   }
   if(entry == SHORT) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            takeRecoveryTrade(SHORT);
        }
   }
}

void tradeManager() {
    if(PositionsTotal()) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -stopLoss) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= takeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -stopLoss ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
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

void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        
        trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
       
        trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
    }
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


