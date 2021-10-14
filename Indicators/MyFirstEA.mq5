
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRed

input int fastMA = 13;
input int fastMAShift = 0;
input ENUM_MA_METHOD fastMAMethod = MODE_LWMA;
input ENUM_APPLIED_PRICE fastMAAppliedPrice = PRICE_CLOSE;
input int slowMA = 55;
input int slowMAShift = 0;
input ENUM_MA_METHOD slowMAMethod = MODE_LWMA;
input ENUM_APPLIED_PRICE slowMAAppliedPrice = PRICE_CLOSE;

double ExtLineBuffer[]; 



int OnInit()
{  
    SetIndexBuffer(0, ExtLineBuffer, INDICATOR_DATA);
    //PlotIndexSetInteger(0,PLOT_ARROW,241);
    //PlotIndexSetInteger(0, PLOT_SHIFT, slowMA);
    //PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, slowMA-1);
    return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{   
    if(rates_total < slowMA-1)
    {
        return (0);
    }
    
    int first, bar, i;
    double Sum, SMA;
    
    if(prev_calculated == 0)
    {
        first = slowMA -1 + begin;
    }
    else 
    {
        first = prev_calculated - 1;
    }
    
    for(bar = first; bar < rates_total; bar++)
    {
    
        Sum = 0.0;
        for(i=0;  i< slowMA; i++)
        {
            Sum += price[bar-i];
        }
        SMA = Sum / slowMA;
        ExtLineBuffer[bar] = SMA;
    }
    return(rates_total);

}
