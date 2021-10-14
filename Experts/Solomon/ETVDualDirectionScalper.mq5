#include <Trade\Trade.mqh>
CTrade trade;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot size
input double                                        buyTakeProfit = 20; // Buy Take Profit in Pips
input double                                        sellTakeProfit = 20; // Sell Take Profit in Pips
input double                                        pendingOrderNFactor = 2; // Pending Order N Factor
input group                                         "============  Scalp Settings ===============";
input bool                                          closePreviousTradeOnNewSignal = true; // Close Previous Trade on New Signal
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

double sellStopLoss;
double buyStopLoss;

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
    if(!spikeLatency()) { return ; }

    if(runAwayProfitManager()) { return ; }

    // tradePositionManager();

    if(etv_signal(BUY)) {
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(LONG);
    }

    if(etv_signal(SELL)) {
        if(closePreviousTradeOnNewSignal){ close_all_positions(); }
        takeTrade(SHORT);
    }
}

void takeTrade(marketEntry entry) {      
    if(expertBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else if(entry == SHORT){ entry = LONG; }   
    }
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, buyTakeProfit, etvLineValue);
        trade.SellStop(lotSize, etvLineValue, Symbol(), ask,  etvLineValue - buyStopLoss * pendingOrderNFactor, ORDER_TIME_GTC,0);
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        sellStopLoss = etvLineValue - bid;
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, sellTakeProfit, etvLineValue);
        trade.BuyStop(lotSize, etvLineValue, Symbol(), bid, etvLineValue + sellStopLoss * pendingOrderNFactor, ORDER_TIME_GTC,0);

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
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}


/* ##################################################### Trade Position Manager ##################################################### */
// void tradePositionManager() {
//     for(int i = PositionsTotal()-1; i >= 0; i--) {
//         PositionGetSymbol(i);
//         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
//             if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * buyTakeProfit)) {
//                 ulong ticket = PositionGetTicket(i);
//                 trade.PositionClose(ticket);
//                 // close_all_positions();
//             }
//             if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * uptrendStopLoss)) {
//                 ulong ticket = PositionGetTicket(i);
//                 trade.PositionClose(ticket);
//                 // close_all_positions();
//             }
//         }
//         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
//             if(PositionGetDouble(POSITION_PROFIT) >= (lotSize * sellTakeProfit)) {
//                 ulong ticket = PositionGetTicket(i);
//                 trade.PositionClose(ticket);
//                 // close_all_positions();
//             }
//             if(PositionGetDouble(POSITION_PROFIT) <= -(lotSize * sellStopLoss)) {
//                 ulong ticket = PositionGetTicket(i);
//                 trade.PositionClose(ticket);
//                 // close_all_positions();
//             }
//         }
//     }
// }

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
enum tradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============ Latency Settings ===============";
input tradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool spikeLatency()
{
    tradeCurrentTime = (int)TimeCurrent();
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);
    if(expertLatency == ZEROLATENCY) {
        return true;
    }
    if(expertLatency == TIMELATENCY) {
        if(tradeCurrentTime - tradeStartTime >= expertLatencyTime) { 
            tradeStartTime = tradeCurrentTime;
            return true;
        }
    }
    if(expertLatency == TIMEFRAMELATENCY)
    {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return true;
        }
    }
    return false;
}

/* ##################################################### Run Away Profit ##################################################### */
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          expertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               runAwayProfitFrequency = PERIOD_D1; // Frequency
input double                                        runAwayProfitTarget = 15; // Profit Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);
double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

bool runAwayProfitManager()
{
    if(!expertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        return false;
    }

    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if(currentEquity - accountBalance >= runAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    // if(currentBalance - accountBalance <= -runAwayProfitTarget) { close_all_positions(); return true; }

    return false;
}

/* ##################################################### ETV Signal ##################################################### */
input group                                       "============  ETV Settings  ===============";
input bool                                         useETVSignal = true; // Use ETV Signal
input int                                          ADXPeriod1 = 10; // ADX Period 1
input int                                          ADXPeriod2 = 14; // ADX Period 2
input int                                          ADXPeriod3 = 20; // ADX Period 3

bool MABUY = true;
bool MASELL = true;
double etvLineValue;

int ETVHandle = iCustom(NULL, 0, "ETV", ADXPeriod1, ADXPeriod2, ADXPeriod3);

bool etv_signal(marketSignal signal)
{
    if(!useETVSignal) { return true; }
    double ETVEnd[];
    ArraySetAsSeries(ETVEnd, true);
    CopyBuffer(ETVHandle, 5, 0, 3, ETVEnd);
    if(signal == BUY && ETVEnd[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && !MABUY) {
        Print("Enter Buy");
        etvLineValue = ETVEnd[0];
        MABUY = true; 
        MASELL = true; 
        return true; 
    }    
    if(signal == SELL && ETVEnd[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) && !MASELL) {
        Print("Enter Sell");
        etvLineValue = ETVEnd[0];
        MABUY = true; 
        MASELL = true; 
        return true; 
    }    
    if(ETVEnd[0] == EMPTY_VALUE && ( MABUY == true || MASELL == true)) {
        Print("Enter Reset");
        MABUY = false; 
        MASELL = false; 
    }
   return false;
}
