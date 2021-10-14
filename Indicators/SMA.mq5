
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrLimeGreen
#property indicator_width1 2

input int MAPeriod = 13;
input int MAShift = 0;

double ExtLineBuffer[];

int OnInit()
{
   SetIndexBuffer(0, ExtLineBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_SHIFT, MAShift);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MAPeriod-1);
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
   if (rates_total < MAPeriod - 1)
    return(0);
    
   int first, bar, iii;
   double Sum, SMA;
   
   if (prev_calculated == 0)
    first = MAPeriod - 1 + begin;
   else first = prev_calculated - 1;

   for(bar = first; bar < rates_total; bar++)
    {
     Sum = 0.0;
     for(iii = 0; iii < MAPeriod; iii++)
      Sum += price[bar - iii];
     
     SMA = Sum / MAPeriod;
      
     ExtLineBuffer[bar] = SMA;
    }
   return(rates_total);
}

