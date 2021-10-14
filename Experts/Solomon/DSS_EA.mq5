#include <Trade\Trade.mqh>
#include <Trade\DealInfo.mqh>

CTrade trade;
CDealInfo m_deal;
enum marketSignal{ BUY, SELL };
enum marketEntry { LONG, SHORT };
enum tradeBehaviour { REGULAR, OPPOSITE };
enum marketTrend{ BULLISH, BEARISH, SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input bool                                          expertIsTakingRecovery = false; // Take Recovery
input bool                                          expertIsUsingBreakeven = false; // Use break even
input bool                                          closePreviousTradeOnNewSignal = false; // Close previous trade on new signal
// input bool                                          useDefaultStopLoss = false; // Use default stop loss
input bool                                          skipSamePositionOnNewSignal = false; // Skip same position on new signal
input int                                           lotSizeDecimalPlace = 2; // Lot Size Decimal Place
input int                                           maxParallelTrade = 2; // Maximum trade
input group                                         "============  Money Management Settings ===============";
input double                                        riskAmount = 100; // Amount to risk
// input int                                           swingCandle = 1; // Swing candle
input int                                           defaultStopLoss = 100; // Default stop loss
input double                                        NTakeProfit = 0.0; // N Take profit
input double                                        RNTakeProfit = 0.0; // Recovery N Take profit
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;
double stopLoss;
double takeProfit;
double lotSize;

void OnTick() 
{

    if(!spikeLatency()) { return ; }

    if(runAwayProfitManager()) { return ; }

    breakevenManager();

    if(!tradingPeriod()) { return ; }

    if(dds_signal(BUY) && qqe_filter_signal(BUY)) { 

        if(skipSamePositionOnNewSignal && PositionsTotal()) {
            for(int i = PositionsTotal()-1; i >= 0; i--) {
                PositionGetSymbol(i);
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                    return ;
                }
            }
        }

        if(closePreviousTradeOnNewSignal) { close_all_positions(); }
        takeTrade(LONG);
        if(expertIsTakingRecovery) { takeRecoveryTrade(LONG); }
    }

    if(dds_signal(SELL) && qqe_filter_signal(SELL)) { 
        
        if(skipSamePositionOnNewSignal && PositionsTotal()) {
            for(int i = PositionsTotal()-1; i >= 0; i--) {
                PositionGetSymbol(i);
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    return ;
                }
            }
        }

        if(closePreviousTradeOnNewSignal) { close_all_positions(); }
        takeTrade(SHORT);
        if(expertIsTakingRecovery) { takeRecoveryTrade(SHORT); }
    }
}

void takeTrade(marketEntry entry) {  
    if(PositionsTotal() >= maxParallelTrade){ return; }    
    if(expertBehaviour == OPPOSITE) {
        if(entry == LONG){ entry = SHORT; }
        else if(entry == SHORT){ entry = LONG; }   
    }
   if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        stopLoss = defaultStopLoss;
        // stopLoss = ask - iLow(Symbol(), Period(), swingCandle);

        // if(useDefaultStopLoss) { if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; } }

        lotSize = NormalizeDouble(riskAmount / stopLoss, lotSizeDecimalPlace);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit);
        tradePeriod = tradePeriod + 1;
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
       
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = defaultStopLoss;
        // stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;

        // if(useDefaultStopLoss) {

        //     if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        // }

        lotSize = NormalizeDouble(riskAmount / stopLoss, lotSizeDecimalPlace);
        
        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = NTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit);
        tradePeriod = tradePeriod + 1;
   }
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}


/* ##################################################### Trade Period Manager ##################################################### */
input group                                         "============ Trade Period Settings ===============";
input bool                                          useTradingTimePeriod = true; // Use Trading Time Period
input int                                           tradeStartHour = 1; // Trade Period Start Hour
input int                                           tradeEndHour = 23; // Trade Period End Hour
input int                                           tradeStartDayOfWeek = 0; // Trade Period Start Day of Week
input int                                           tradeEndDayOfWeek = 6; // Trade Period End Day of Week
input int                                           tradeStartDay = 1; // Trade Period Start Day
input int                                           tradeEndDay = 30; // Trade Period End Day

bool tradingPeriod()
{
    if(!useTradingTimePeriod) { return true; }

    MqlDateTime tradePeriodCurrentTime;

    TimeToStruct(TimeCurrent(), tradePeriodCurrentTime);

    // Print("Hour: ", tradePeriodCurrentTime.hour);
    // Print("Day of week: ", tradePeriodCurrentTime.day_of_week);
    // Print("Day: ", tradePeriodCurrentTime.day);
    
    if(tradePeriodCurrentTime.hour < tradeStartHour) { return false; }

    if(tradePeriodCurrentTime.hour > tradeEndHour) { return false; }
    
    if(tradePeriodCurrentTime.day_of_week < tradeStartDayOfWeek) { return false; }

    if(tradePeriodCurrentTime.day_of_week > tradeEndDayOfWeek) { return false; }
    
    if(tradePeriodCurrentTime.day < tradeStartDay) { return false; }

    if(tradePeriodCurrentTime.day > tradeEndDay) { return false; }

    return true;
}
/* ##################################################### Break Even Manager ##################################################### */

void breakevenManager() {
    if(!expertIsUsingBreakeven) { return ; }
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if( PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= stopLoss) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP));
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if( PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= stopLoss) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP));
            }
        }
    }
}

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
input int                                           runAwayProfitTarget = 15; // Profit Target
input int                                           maxTradeTarget = 4; // Max Trade Target
datetime runAwayCandleTime = iTime(Symbol(), runAwayProfitFrequency, 0);

int profitPeriod = 0;
int lossPeriod = 0;
int tradePeriod = 0;
bool runAwayProfitManager()
{
    if(!expertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), runAwayProfitFrequency, 0);

    if(freq != runAwayCandleTime) {
        runAwayCandleTime = freq;
        profitPeriod = 0;
        lossPeriod = 0;
        tradePeriod = 0;
        return false;
    }

    if(profitPeriod >= runAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(tradePeriod >= maxTradeTarget) { 
        return true; 
    }
    
    
    return false;
}


//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+


void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {

    ENUM_TRADE_TRANSACTION_TYPE type=trans.type;

    if(type==TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal)) {
            m_deal.Ticket(trans.deal);
        }
        else {
            Print(__FILE__," ",__FUNCTION__,", ERROR: HistoryDealSelect(",trans.deal,")");
            return;
        }
        //---
        long reason=-1;
        if(!m_deal.InfoInteger(DEAL_REASON,reason))
        {
            Print(__FILE__," ",__FUNCTION__,", ERROR: InfoInteger(DEAL_REASON,reason)");
            return;
        }
        if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL) {
            lossPeriod = lossPeriod + 1;
        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {
                profitPeriod = profitPeriod + 1;
            }
        }
    }
}

/* ##################################################### Recovery ##################################################### */

void takeRecoveryTrade(marketEntry entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        stopLoss = defaultStopLoss;

        // stopLoss = ask - iLow(Symbol(), Period(), swingCandle);

        // if(useDefaultStopLoss) {

        //     if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        // }

        lotSize = NormalizeDouble(dealLost / stopLoss, lotSizeDecimalPlace);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = RNTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit, "Recovery");
    }

    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        stopLoss = defaultStopLoss;
        
        // stopLoss = iHigh(Symbol(), Period(), swingCandle) - bid;

        // if(useDefaultStopLoss) {

        //     if(stopLoss < defaultStopLoss) { stopLoss = defaultStopLoss; }

        // }

        lotSize = NormalizeDouble(dealLost / stopLoss, lotSizeDecimalPlace);

        if(lotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(lotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { lotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        takeProfit = RNTakeProfit * stopLoss;

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit, "Recovery");
    }
}

double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0;

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

/* ##################################################### DSS Settings ##################################################### */

input group                                         "============  DSS Settings ===============";
input int                                           stochasticPeriod = 55; // Stochastic Period
input int                                           smoothingPeriod = 5; // Smoothing Period
input int                                           signalPeriod = 5; // Signal Period
input ENUM_APPLIED_PRICE                            DSSPrice = PRICE_CLOSE; // DSS Price
input int                                           DSSOverBoughtLevel = 80; // DSS Overbought Level
input int                                           DSSOverSoldLevel = 20; // DSS OverSold Level

int DSSHandle = iCustom(NULL, 0, "DSS", stochasticPeriod, smoothingPeriod, signalPeriod, DSSPrice);

bool MABUY = false;
bool MASELL = false;

bool dds_signal(marketSignal signal) {
   double DSSArray[];
   ArraySetAsSeries(DSSArray, true);
   CopyBuffer(DSSHandle, 0, 0, 2, DSSArray);
   if(signal == BUY && DSSArray[0] >= DSSOverSoldLevel && DSSArray[0] < DSSOverBoughtLevel && MABUY) 
    { 
        return true; 
    }
    if(signal == SELL && DSSArray[0] <= DSSOverBoughtLevel && DSSArray[0] > DSSOverSoldLevel && MASELL) 
    { 
        return true; 
    }

    if(DSSArray[0] < DSSOverSoldLevel)
    {
        MABUY = true;
        MASELL = false;
    }
    if(DSSArray[0] > DSSOverBoughtLevel)
    {
        MASELL = true;
        MABUY = false;
    }
   return false;
}

/* ##################################################### QQE Filter Settings ##################################################### */
input group                                         "============  QQE Filter Settings ===============";
input bool                                          useQQEFilter = false; // Use QQE Filter
input int                                           qqeFilterPeriod = 14; // QQE Period
input int                                           qqeFilterSmothing = 5; // QQE Smothing Factor
input double                                        qqeFilterFastPeriod = 2.618; // QQE Fast Period
input double                                        qqeFilterSlowPeriod = 4.236; // QQE Period
input ENUM_APPLIED_PRICE                            qqeFilterPrice = PRICE_CLOSE; // QQE Price
input ENUM_TIMEFRAMES                               qqeFilterTimeFrame = PERIOD_D1; // QQE Timeframes

int qqeFilterHandle = iCustom(NULL, qqeFilterTimeFrame, "QQE", qqeFilterPeriod, qqeFilterSmothing, qqeFilterFastPeriod, qqeFilterSlowPeriod, qqeFilterPrice);

bool qqe_filter_signal(marketSignal signal){
    if(!useQQEFilter) { return true; }
    double colorArray[];
    ArraySetAsSeries(colorArray, true);
    CopyBuffer(qqeFilterHandle, 3, 1, 2, colorArray);
    // Print("FIlter Price: ", colorArray[0]);
    if(signal == BUY && colorArray[0] == 1) 
    { 
        return true; 
    }
    if(signal == SELL && colorArray[0] == 2) 
    {
        return true; 
    }
    return false;
}

