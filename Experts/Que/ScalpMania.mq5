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

enum signalFREQ {
    candle,          // Check signal on every candle 
    tick           // Check signal on every tick 
};
input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input signalFREQ                                    expertSignalFREQ = tick; // Signal Frequency
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
        
bool ptl_signal_buy, macd_signal_buy, kt_signal_buy, sar_signal_buy, stoch_signal_buy;
bool ptl_signal_sell, macd_signal_sell, kt_signal_sell, sar_signal_sell, stoch_signal_sell;

void OnTick() 
{
    datetime time = iTime(Symbol(), Period(), 0);

    close_all_sell_trade_on_spike();

    perfect_trendline_signal();
    macd_signal();
    kt_trend_filter_signal();
    parabolic_sar_signal();
    stochastic_volatility_signal();

    if(ptl_signal_buy && macd_signal_buy && kt_signal_buy && sar_signal_buy && stoch_signal_buy )
    { 
        close_opposite_trade(LONG);  
        enterFor(LONG);
        Sleep(1200000);

    }
    if(ptl_signal_sell && macd_signal_sell && kt_signal_sell && sar_signal_sell && stoch_signal_sell )
    {
        close_opposite_trade(SHORT);  
        enterFor(SHORT);
        Sleep(1200000);

    }

}


void takeTrade(marketEntry entry) 
{
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
      
   if(expertBehaviour == OPPOSITE)
   {
        if(entry == LONG){ entry = SHORT; }
        if(entry == SHORT){ entry = LONG; }   
   }
   
   if(entry == LONG)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
   }
   if(entry == SHORT)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double bid, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(bid, entry);
}

double calculateStopLoss(double bid, marketEntry entry)
{
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(bid, entry);
}

double calculateTakeProfit(double bid, marketEntry entry)
{
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}

void close_all_positions()
{
    if(PositionsTotal())
    {
        for(int i=0; i < PositionsTotal(); i++)
        {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void close_opposite_trade(marketEntry entry)
{

    if(PositionsTotal() && entry == LONG && closeOnOppositeSignal)
    {
        PositionGetSymbol(0);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            close_all_positions();
        }
    }
    if(PositionsTotal() && entry == SHORT && closeOnOppositeSignal)
    {
        PositionGetSymbol(0);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            close_all_positions();
        }
    }
}

void enterFor(marketEntry entry)
{
    if(entry == LONG && expertIsTakingBuyTrade && PositionsTotal() < 1)
    {
        takeTrade(LONG);
    }
    if(entry == SHORT && expertIsTakingSellTrade && PositionsTotal() < 1)
    {
        takeTrade(SHORT);
    }
}


void close_all_sell_trade_on_spike()
{
    
    if(PositionsTotal() && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1))
    {
        for(int i = 0; i < PositionsTotal(); i++)
        {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}


input group                                         "============ Perfect Trend Line Settings ===============";
input bool                                          ptlFactor = true; // Use PTL Signal
input int                                           ptlInpFastLength = 3; // Fast length
input int                                           ptlInpSlowLength = 7; // Slow length
int PTLHandle = iCustom(NULL, 0, "SPTL2", ptlInpFastLength, ptlInpSlowLength);

bool perfect_trendline_signal()
{
    if(!ptlFactor)
    {
        ptl_signal_buy = true;
        ptl_signal_sell = true;
        return true;
    } 
    double PTLArray[];
    ArraySetAsSeries(PTLArray, true);
    CopyBuffer(PTLHandle,7,1,3,PTLArray);
    if(PTLArray[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) )
    {
        ptl_signal_buy = true;
        ptl_signal_sell = false;
        return true;
    }
    if(PTLArray[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) )
    {
        ptl_signal_buy = false;
        ptl_signal_sell = true;
        return true;
    }
    return false;
}

input group                                       "============  MACD Settings  ===============";
input bool                                         macdFactor = true; // Use signal MACD
input ENUM_TIMEFRAMES                              macdTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          macdFastEMA = 12; // Trend Fast EMA
input int                                          macdSlowEMA = 26; // Trend Slow EMA
input int                                          MACDSMA = 9; // Trend MACD SMA
input ENUM_APPLIED_PRICE                           MACDAppliedPrice = PRICE_CLOSE; // MACD Applied Price

bool macd_signal()
{
    if(!macdFactor) 
    {
        macd_signal_buy = true;
        macd_signal_sell = true;
        return true;
    }
    int MACDHandle = iMACD(Symbol(), macdTimeframe, macdFastEMA, macdSlowEMA, MACDSMA, MACDAppliedPrice);
    double MACDArray[];
    ArraySetAsSeries(MACDArray, true);
    CopyBuffer(MACDHandle, 0, 0, 3, MACDArray);
    if(MACDArray[0] > 0) 
    { 
        macd_signal_buy = true;
        macd_signal_sell = false;
        return true; 
    }
    if(MACDArray[0] < 0) 
    { 
        macd_signal_buy = false;
        macd_signal_sell = true;
        return true; 
    }
    return true;
}

input group                                         "============ KT Trend Filter Settings ===============";
input bool                                          ktFactor = true; // Use KT Trend Filter Signal
input int                                           trendBars = 10000; // Max History Bars
input int                                           trendPeriod = 200; // Trend Period
input bool                                          mtfScanner = false; // Show MTF Scanner

int trendFilterHandle = iCustom(Symbol(), Period(), "TrendFilter", trendBars, trendPeriod, mtfScanner);

bool kt_trend_filter_signal()
{
    if(!ktFactor) 
    {
        kt_signal_buy = true;
        kt_signal_sell = true;
        return true;
    }
    double uptrend[], downtrend[], sideways[];
    ArraySetAsSeries(uptrend, true);
    ArraySetAsSeries(downtrend, true);
    ArraySetAsSeries(sideways, true);
    CopyBuffer(trendFilterHandle, 0, 0, 3, uptrend);
    CopyBuffer(trendFilterHandle, 1, 0, 3, downtrend);
    CopyBuffer(trendFilterHandle, 2, 0, 3, sideways);

    if(uptrend[0] != 0)
    {
        kt_signal_buy = true;
        kt_signal_sell = false;
        return true;
    }
    if(downtrend[0] != 0)
    {
        kt_signal_buy = false;
        kt_signal_sell = true;
        return true;
    }
    if(sideways[0] != 0)
    {
        return true;
    }
    return false;
}


input group                                         "============  Parabolic SAR Settings  ===============";
input bool                                          sarFactor = true; // Use Parabolic SAR Signal
input double                                        step = 0.02; // Parabolic SAR Step | price increment step - acceleration factor 
input double                                        maximum = 0.2; // Parabolic SAR Maximum value of step 

int paraBolicSARHandle = iSAR(Symbol(), Period(), step, maximum);

bool parabolic_sar_signal()
{
    if(!sarFactor) 
    {
        sar_signal_buy = true;
        sar_signal_sell = true;
        return true;
    }
    double parabolicSARArray[];
    ArraySetAsSeries(parabolicSARArray, true);
    CopyBuffer(paraBolicSARHandle, 0, 0, 3, parabolicSARArray);
    if(parabolicSARArray[1] < iLow(Symbol(), Period(), 1)) 
    {
        sar_signal_buy = true;
        sar_signal_sell = false;
        return true; 
    }
    if(parabolicSARArray[1] > iHigh(Symbol(), Period(), 1)) 
    {
        sar_signal_buy = false;
        sar_signal_sell = true;
        return true; 
    }
    return false;
}


input group                                         "============ Stochastic Volatility Settings ===============";
input bool                                          stochFactor = true; // Use PTL Signal
int stochasticVolatilityHandle = iCustom(Symbol(), Period(), "StochasticVolatility");

bool stochastic_volatility_signal()
{
    
    if(!stochFactor) 
    {
        stoch_signal_buy = true;
        stoch_signal_sell = true;
        return true;
    }
    double up[], down[], stochSignal[];
    ArraySetAsSeries(up, true);
    ArraySetAsSeries(down, true);
    ArraySetAsSeries(stochSignal, true);
    CopyBuffer(stochasticVolatilityHandle, 0, 0, 3, up);
    CopyBuffer(stochasticVolatilityHandle, 1, 0, 3, down);
    CopyBuffer(stochasticVolatilityHandle, 2, 0, 3, stochSignal);
    if(stochSignal[1] < stochSignal[0] && stochSignal[0] >= up[0]) 
    {
        stoch_signal_buy = true;
        stoch_signal_sell = false;
        return true;  
    }
    if(stochSignal[1] > stochSignal[0] && stochSignal[0] < up[0] && stochSignal[0] > down[0]) 
    {
        stoch_signal_buy = false;
        stoch_signal_sell = true;
        return true;  
    }
    return false;
}