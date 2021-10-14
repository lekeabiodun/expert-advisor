#property indicator_chart_window;

#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_LINE
#property indicator_label1 "slowMA"
#property indicator_color1 clrRed
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1


#property indicator_type2 DRAW_LINE
#property indicator_label2 "fastMA"
#property indicator_color2 clrYellow
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1



input int slowMA = 34; // Slow MA Period
input ENUM_MA_METHOD slowMAMethod = MODE_EMA; // Slow MA Method

input int fastMA = 13; // Fast MA Period
input ENUM_MA_METHOD fastMAMethod = MODE_EMA; // Fast MA Method

input int signalMA = 5; // signal MA Period
input ENUM_MA_METHOD signalMAMethod = MODE_EMA; // signal MA Method

double bufferSlow[];
double bufferFast[];
double bufferSignal[];

int MAXPeriod;

int slowHandle;
int fastHandle;
int signalHandle;

int OnInit()
{
    SetIndexBuffer(0, bufferSlow, INDICATOR_DATA);
    SetIndexBuffer(1, bufferFast, INDICATOR_DATA);
    
    MAXPeriod = MathMax(MathMax(slowMA, fastMA), signalMA);
    
    slowHandle = iMA(Symbol(), Period(), slowMA, 0, slowMAMethod, PRICE_CLOSE);
    fastHandle = iMA(Symbol(), Period(), fastMA, 0, fastMAMethod, PRICE_CLOSE);
    signalHandle = iMA(Symbol(), Period(), signalMA, 0, signalMAMethod, PRICE_CLOSE);
    
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MAXPeriod);
    
    return(INIT_SUCCEEDED);
}

int OnCalculate(
    const int rates_total,
    const int prev_calculated,
    const datetime &time[],
    const double &open[],
    const double &high[],
    const double &low[],
    const double &close[],
    const long &tick_volume[],
    const long &volume[],
    const int &spred[]
    )
{
    if(IsStopped()) { return(0); }
    if(rates_total < MAXPeriod) { return(0); }
    if(BarsCalculated(slowHandle) < rates_total) { return(0); }
    if(BarsCalculated(fastHandle) < rates_total) { return(0); }
    if(BarsCalculated(signalHandle) < rates_total) { return(0); }
    
    int copyBars = 0;
    if(prev_calculated > rates_total || prev_calculated<=0) {
        copyBars = rates_total;
    } else {
        copyBars = rates_total - prev_calculated;
        if(prev_calculated>0) {
            copyBars++;
        }
    }
    
    if(IsStopped()) { return(0); }
    
    if(CopyBuffer(slowHandle, 0, 0, copyBars, bufferSlow)<=0) { return(0); }
    if(CopyBuffer(fastHandle, 0, 0, copyBars, bufferFast)<=0) { return(0); }
    
    return(rates_total);
}