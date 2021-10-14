input double                                        InputTrendMax = 6; // Consecutive Trend Candle Period
input double                                        InputOppMax = 6; // Consecutive Reverse Candle Period
input double                                        InputMinWick = 1; // Consecutive Minimum Candle Wick
input double                                        InputProfitTarget = 2; // Profit Target
input ENUM_TIMEFRAMES                               ExpertTimeFrameRange = PERIOD_CURRENT; // Timeframe

int OnInit() 
{
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{

    Print("Total Candle: ", CANDLE_COUNT);

    Print("Consecutive Opposing Candle: ", CONS_OPP);
    Print("Consecutive Follow Up Candle: ", CONS_TREND);

    Print("Consecutive Opposing Candle MAX: ", CONS_OPP_MAX);
    Print("Consecutive Follow Up Candle MAX: ", CONS_TREND_MAX);

    Print("Smallest Candle: ", SMALLEST_CANDLE);
    Print("Biggest Candle: ", BIGGEST_CANDLE);

    Print("Smallest Candle Wick: ", SMALLEST_WICK);
    Print("Biggest Candle Wick: ", BIGGEST_WICK);

    Print("Total Smallest X Candle Wick: ", TOTAL_SMALLEST_WICK);
    Print("Total Candle x Wick : ", TOTAL_BODY_COUNT);
}

int CANDLE_COUNT = 0;

double SMALLEST_WICK = 10000.0;
double BIGGEST_WICK = 0;

double SMALLEST_CANDLE = 10000.0;
double BIGGEST_CANDLE = 0;

int TOTAL_SMALLEST_WICK = 0;
int TOTAL_BODY_COUNT = 0;

int CONS_OPP_MAX = 0;
int CONS_OPP = 0;

int CONS_TREND_MAX = 0;
int CONS_TREND = 0;

int COUNT_OPP = 0;
int COUNT_TREND = 0;

datetime ExpertTime;

static datetime ExpertTimestamp;

void OnTick() 
{
    
    if(!SpikeLatency()) { return; }

    CANDLE_COUNT = CANDLE_COUNT + 1;

    MqlRates rates[]; 

    ArraySetAsSeries(rates, true); 

    int copied=CopyRates(Symbol(), 0, 0, 100, rates); 

    // Opposite
    if(rates[2].close > rates[2].open && rates[1].close < rates[1].open)
    {
        COUNT_OPP = COUNT_OPP +  1;
    }
    else if(rates[2].close < rates[2].open && rates[1].close > rates[1].open)
    {
        COUNT_OPP = COUNT_OPP +  1;
    } 
    else {
        COUNT_OPP = 0;
    }

    if(COUNT_OPP >= InputOppMax)
    {
        CONS_OPP_MAX = CONS_OPP_MAX + 1;
    }

    CONS_OPP = MathMax(CONS_OPP, COUNT_OPP);

    // Trend
    if(rates[2].close > rates[2].open && rates[1].close > rates[1].open)
    {
        COUNT_TREND = COUNT_TREND +  1;
    }
    else if(rates[2].close < rates[2].open && rates[1].close < rates[1].open)
    {
        COUNT_TREND = COUNT_TREND +  1;
    } 
    else {
        COUNT_TREND = 0;
    }

    if(COUNT_TREND >= InputTrendMax)
    {
        CONS_TREND_MAX = CONS_TREND_MAX + 1;
    }

    CONS_TREND = MathMax(CONS_TREND, COUNT_TREND);

    
    ExpertTime = iTime(Symbol(), ExpertTimeFrameRange, 0);
    
    if(ExpertTimestamp != ExpertTime) 
    {

        ExpertTimestamp = ExpertTime;

        COUNT_TREND = 0;
        COUNT_OPP = 0;

    }

    SMALLEST_CANDLE = MathMin(SMALLEST_CANDLE, rates[1].high - rates[1].low);
    BIGGEST_CANDLE = MathMax(BIGGEST_CANDLE, rates[1].high - rates[1].low);

    if(rates[1].close > rates[1].open)
    {
        SMALLEST_WICK = MathMin(SMALLEST_WICK, rates[1].open - rates[1].low);
        BIGGEST_WICK = MathMax(BIGGEST_WICK, rates[1].open - rates[1].low);

        if(rates[1].open - rates[1].low <= InputMinWick)
        {
            TOTAL_SMALLEST_WICK = TOTAL_SMALLEST_WICK + 1;

            if(rates[1].high - rates[1].open >= (InputMinWick * InputProfitTarget)) 
            {
                TOTAL_BODY_COUNT = TOTAL_BODY_COUNT + 1;
            }
        }
    }
    
    if(rates[1].close < rates[1].open)
    {
        SMALLEST_WICK = MathMin(SMALLEST_WICK, rates[1].high - rates[1].open);
        BIGGEST_WICK = MathMax(BIGGEST_WICK, rates[1].high - rates[1].open);

        if(rates[1].high - rates[1].open <= InputMinWick)
        {
            TOTAL_SMALLEST_WICK = TOTAL_SMALLEST_WICK + 1;

            if(rates[1].open - rates[1].low >= (InputMinWick * InputProfitTarget)) 
            {
                TOTAL_BODY_COUNT = TOTAL_BODY_COUNT + 1;
            }
        }
    }


}

//+------------------------------------------------------------------+
//| Spike Latency function                                           |
//+------------------------------------------------------------------+
input group                                         "===================== Latency Settings =====================";
input bool                                          UseSpikeLatency = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrame = PERIOD_CURRENT; // Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool SpikeLatency()
{
    if(!UseSpikeLatency) { return true; }

    tradeCandleTime = iTime(Symbol(), ExpertLatencyTimeFrame, 0);
    
    if(tradeTimestamp != tradeCandleTime) 
    {

        tradeTimestamp = tradeCandleTime;

        return true;
    }

    return false;
}

