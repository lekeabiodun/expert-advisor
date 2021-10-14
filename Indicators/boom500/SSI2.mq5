//+------------------------------------------------------------------+
//|                      https://www.mql5.com/en/articles/37 SSI.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2020, Freeman Software INC."
#property link        "mailto:thelekeabiodun@gmail.com"
#property description "Spike Strength Index"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_label1 "Sell"


input int SSIPeriod = 1440; // SSI Period
input int SpikeCount = 1440; // SSI Count

double SSIBuffer[];

int OnInit()
{
    SetIndexBuffer(0, SSIBuffer, INDICATOR_DATA);
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, SSIPeriod);
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
        for(int i = 0; i < SSIPeriod; i++) {
            if(close[bar - i] > open[bar - i]) {
                spike++;
            }
        }
        SSIBuffer[bar] = spike;
        // if(spike >= SpikeCount) {
        //     SSIBuffer[bar] = spike;
        // }
    }
    return(rates_total);
}
