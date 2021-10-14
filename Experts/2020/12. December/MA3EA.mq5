#include <Trade\Trade.mqh>
CTrade trade;
enum ENUM_MARKET_SIGNAL{ MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_TRADE_BEHAVIOUR { REGULAR, OPPOSITE };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_TRADE_BEHAVIOUR                          ExpertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        LotSize = 1; // Lot Size
input double                                        StopLoss = 50; // Stop Loss in Pips
input double                                        TakeProfit = 20; // Take Profit in Pips
input double                                        TradeZone = 20; // Trade Zone in Pips
input group                                         "============  Scalp Settings ==============="
input bool                                          ExpertIsTakingBuyTrade = true; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = true; // Take Sell Trade

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
    if(!SpikeLatency()) { return ; }

    if(PositionsTotal()) { return ; }

    if(market_signal(MARKET_SIGNAL_BUY)) { 
        TakeTrade(MARKET_ENTRY_LONG);
    }
    if(market_signal(MARKET_SIGNAL_SELL)) { 
        TakeTrade(MARKET_ENTRY_SHORT);
    }
}

bool market_signal(ENUM_MARKET_SIGNAL Signal)
{
    if(pinbardetector(Signal) && ma_signal(Signal))
    {
        return true;
    }
    return false;
}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{

   if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
		double sl			= NormalizeDouble(ask - StopLoss * _Point, _Digits) * (StopLoss > 0);
		double tp			= NormalizeDouble(ask + TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(LotSize, Symbol(), ask, sl, tp);
   }

   if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
		double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
		double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
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

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
enum TradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============ Latency Settings ===============";
input TradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool SpikeLatency()
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

/* ##################################################### Timeframe Settings ##################################################### */
input group                                       "============ Timeframe Settings ===============";
input ENUM_TIMEFRAMES                              TimeFrame1 = PERIOD_M15; // First Timeframe
input ENUM_TIMEFRAMES                              TimeFrame2 = PERIOD_D1; // Second Timeframe

/* ##################################################### First Moving Average  ##################################################### */
input group                                       "============  First Moving Average   ===============";
input int                                          MAPeriod1 = 1; // First Moving Average Period
input int                                          MAShift1 = 0; // First Moving Average Shift
input ENUM_MA_METHOD                               MAMethod1 = MODE_LWMA; // First Moving Average Method
input ENUM_APPLIED_PRICE                           MAAppliedPrice1 = PRICE_CLOSE; // First Moving Average Applied Price

/* ##################################################### Second Moving Average  ##################################################### */
input group                                       "============  Second Moving Average   ===============";
input int                                          MAPeriod2 = 1; // Second Moving Average Period
input int                                          MAShift2 = 0; // Second Moving Average Shift
input ENUM_MA_METHOD                               MAMethod2 = MODE_LWMA; // Second Moving Average Method
input ENUM_APPLIED_PRICE                           MAAppliedPrice2 = PRICE_CLOSE; // Second Moving Average Applied Price

/* ##################################################### Third Moving Average  ##################################################### */
input group                                       "============  Third Moving Average   ===============";
input int                                          MAPeriod3 = 1; // Third Moving Average Period
input int                                          MAShift3 = 0; // Third Moving Average Shift
input ENUM_MA_METHOD                               MAMethod3 = MODE_LWMA; // Third Moving Average Method
input ENUM_APPLIED_PRICE                           MAAppliedPrice3 = PRICE_CLOSE; // Third Moving Average Applied Price

int FirstMovingAverageHandle = iMA(Symbol(), TimeFrame2, MAPeriod1, MAShift1, MAMethod1, MAAppliedPrice1);
int SecondMovingAverageHandle = iMA(Symbol(), TimeFrame2, MAPeriod2, MAShift2, MAMethod2, MAAppliedPrice2);
int ThirdMovingAverageHandle = iMA(Symbol(), TimeFrame2, MAPeriod3, MAShift3, MAMethod3, MAAppliedPrice3);

bool ma_signal(ENUM_MARKET_SIGNAL Signal) 
{
    double Array1[], Array2[], Array3[];

    ArraySetAsSeries(Array1, true);
    ArraySetAsSeries(Array2, true);
    ArraySetAsSeries(Array3, true);
    
    CopyBuffer(FirstMovingAverageHandle, 0, 0, 3, Array1);
    CopyBuffer(SecondMovingAverageHandle, 0, 0, 3, Array2);
    CopyBuffer(ThirdMovingAverageHandle, 0, 0, 3, Array3);

    // Comment("Array One: ", iClose(Symbol(), Period(), 0) - Array1[0], " \nArray Two: ", iClose(Symbol(), Period(), 0) - Array2[0], " \nArray Three: ", iClose(Symbol(), Period(), 0) - Array3[0], " \nArray One: ", Array1[0] - iClose(Symbol(), Period(), 0), " \nArray Two: ", Array2[0] - iClose(Symbol(), Period(), 0), " \nArray Three: ", Array3[0] - iClose(Symbol(), Period(), 0), " \n Target: ", TradeZone * _Point);

    if(Signal == MARKET_SIGNAL_BUY) 
    {
        if(
            iClose(Symbol(), Period(), 0) > Array1[0] &&
            iClose(Symbol(), Period(), 0) - Array1[0] <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_BUY Trade Zone 1");
            return true; 
        }
        if(
            iClose(Symbol(), Period(), 0) > Array2[0] &&
            iClose(Symbol(), Period(), 0) - Array2[0] <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_BUY Trade Zone 2");
            return true; 
        }
        if(
            iClose(Symbol(), Period(), 0) > Array3[0] &&
            iClose(Symbol(), Period(), 0) - Array3[0] <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_BUY Trade Zone 3");
            return true; 
        }
    } 
    if(Signal == MARKET_SIGNAL_SELL) {
        if(
            Array1[0] > iClose(Symbol(), Period(), 0) &&
            Array1[0] - iClose(Symbol(), Period(), 0) <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_SELL Trade Zone 1");
            return true; 
        }
        if(
            Array2[0] > iClose(Symbol(), Period(), 0) &&
            Array2[0] - iClose(Symbol(), Period(), 0) <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_SELL Trade Zone 2");
            return true; 
        }
        if(
            Array3[0] > iClose(Symbol(), Period(), 0) &&
            Array3[0] - iClose(Symbol(), Period(), 0) <= (TradeZone * _Point)
        ) 
        {
            // Print("MARKET_SIGNAL_SELL Trade Zone 3");
            return true; 
        }
    }
    return false;
}

int PinbardetectorHandle = iCustom(NULL, TimeFrame1, "pinbardetector");

bool pinbardetector(ENUM_MARKET_SIGNAL Signal)
{
    double PinbarArray[], ColorArray[];

    ArraySetAsSeries(ColorArray, true);
    ArraySetAsSeries(PinbarArray, true);

    CopyBuffer(PinbardetectorHandle, 1, 1, 2, ColorArray);
    CopyBuffer(PinbardetectorHandle, 0, 1, 2, PinbarArray);

    // Print("Pinbar: ", PinbarArray[0]);

    if(Signal == MARKET_SIGNAL_BUY && PinbarArray[0] != EMPTY_VALUE && ColorArray[0] == 0)
    {
        // Print("Pinbar detected MARKET_SIGNAL_BUY");
        return true;
    }

    if(Signal == MARKET_SIGNAL_SELL && PinbarArray[0] != EMPTY_VALUE && ColorArray[0] == 1)
    {
        // Print("Pinbar detected MARKET_SIGNAL_SELL");
        return true;
    }

    return false;
}
