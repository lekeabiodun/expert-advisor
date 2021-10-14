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
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoveryLotSize = 10; // Lot Sizeinput double                                        recoveryCount = 1; // Recovery Count
input double                                        recoveryCount = 3; // Recovery Count

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
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}


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

   if(signal == BUY && deMarkerValue > deMarkerOverBoughtLevel && !deMarkerOverBoughtSignalCrossUp)
    {
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
        deMarkerComingFromOversold = true;
        deMarkerComingFromOverbought = false;
    }
    if(deMarkerValue > deMarkerOverBoughtLevel)
    {
        deMarkerComingFromOversold = false;
        deMarkerComingFromOverbought = true;
    }
    return false;
}

