#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{ BUY, SELL};
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH,  BEARISH,  SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 1; // Stop Loss %Constant-K%
input double                                        takeProfit = 0.5; // Take Profit %Constant-K%
input group                                         "============  Swing Settings ===============";
input int                                           swingPeriod = 5; // Swing Period 
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade
input group                                         "============ Recovery Settings ===============";
input bool                                          expertIsTakingRecoveryTrade = false; // Take Recovery Trade
input double                                        recoveryLotSize = 10; // Lot Sizeinput double                                        recoveryCount = 1; // Recovery Count
input double                                        recoveryCount = 3; // Recovery Count

static datetime timestamp;
double tradeTakeProfit = 0.0;
double tradeStopLoss = 0.0;

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
        double swingPrice = recentSwing(LONG);
        tradeTakeProfit = MathMax(swingPrice, ask) - MathMin(swingPrice, ask) * takeProfit;
        tradeStopLoss = MathMax(swingPrice, ask) - MathMin(swingPrice, ask) * stopLoss;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
        }
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double swingPrice = recentSwing(SHORT);
        tradeTakeProfit = MathMax(swingPrice, bid) - MathMin(swingPrice, bid) * takeProfit;
        tradeStopLoss = MathMax(swingPrice, bid) - MathMin(swingPrice, bid) * stopLoss;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(getPreviousDealLost() >= recoveryCount && expertIsTakingRecoveryTrade){
            trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
        }
   }
}

double recentSwing(marketEntry entry) {
    double swingPrice = 0.0;
    if(entry == LONG) {
        swingPrice = iLow(Symbol(), Period(), 1);
        for(int i=1; i<=swingPeriod; i++) {
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
        for(int i=1; i<=swingPeriod; i++) {
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
void tradeManager() {
    if(PositionsTotal()) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= tradeTakeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -tradeStopLoss) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= tradeTakeProfit ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -tradeStopLoss ) {
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

