//+------------------------------------------------------------------+
//|                      https://www.mql5.com/en/articles/37 SSI.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2020, Freeman Software INC."
#property link        "mailto:thelekeabiodun@gmail.com"
#property description "Spike Strength Index"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 3
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGold
#property indicator_label1 "Total Spike Candle"

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrLime
#property indicator_label2 "Average Spike Candle Movement"

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrOrangeRed
#property indicator_label3 "Average Sell Candle Movement"


input int SSIPeriod = 120; // SSI Period

double TSBuffer[];
double ASBuffer[];
double ANOSBuffer[];

int OnInit()
{
    SetIndexBuffer(0, TSBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ASBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, ANOSBuffer, INDICATOR_DATA);
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, SSIPeriod);
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, SSIPeriod);
    PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, SSIPeriod);
    IndicatorSetString(INDICATOR_SHORTNAME,"SSI("+string(SSIPeriod)+")");
    PlotIndexSetString(0, PLOT_LABEL,"SSI("+string(SSIPeriod)+")");
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

    if(rates_total < SSIPeriod - 1) { return(0); }

    int first, bar;

    if(prev_calculated==0) { 
        first = SSIPeriod - 1;
    } else {
        first = prev_calculated - 1;
    }

    for(bar = first; bar < rates_total; bar++)
    {
        double spike = 0;
        double spike_movement = 0;
        double no_spike_movement = 0;
        for(int i = 0; i < SSIPeriod; i++) {
            if(close[bar - i] > open[bar - i]) {
                spike++;
                spike_movement += high[bar - i] - low[bar - i];
            } else {
                no_spike_movement += open[bar - i] - close[bar - i];
            }
        }
        double spike_average = spike/SSIPeriod;
        Comment("Spike average: ", spike_average);
        TSBuffer[bar] = spike;
        ASBuffer[bar] = spike_movement / spike;
        ANOSBuffer[bar] = no_spike_movement / spike;
    }
    return(rates_total);
}
