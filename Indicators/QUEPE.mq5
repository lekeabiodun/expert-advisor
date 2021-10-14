
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1

enum enumSpikeDir{
    BOOM, // Boom Market
    CRASH, // Crash Market
};

input enumSpikeDir spikeDir = BOOM; // Market

//input int inpPeriod = 1440; // Period (1440 = a day)

int OnInit()
{
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 100)
   {
        return(0);
   }
   int start, bar, i, spike;
    
   if(prev_calculated == 0)
   {
       start = 1;
   }
   else 
   {
       start = prev_calculated - 1;
   }
   
   for(bar = start; bar < rates_total; bar++)
    {
        if(spikeDir == BOOM)
        {
            if(close[bar] > open[bar])
            {
                ObjectCreate(0, close[bar], OBJ_TEXT, 0, time[bar], close[bar]+3);
                ObjectSetString(0,close[bar],OBJPROP_TEXT,IntegerToString(i-1));
                ObjectSetInteger(0,close[bar],OBJPROP_FONTSIZE,14);
                ObjectSetInteger(0,close[bar],OBJPROP_COLOR,clrWhite);
                spike++;
                i = 0;
            }
        }
        if(spikeDir == CRASH)
        {
            
            if(close[bar] < open[bar])
            {
                ObjectCreate(0, close[bar], OBJ_TEXT, 0, time[bar], close[bar]-1);
                ObjectSetString(0,close[bar],OBJPROP_TEXT,IntegerToString(i-1));
                ObjectSetInteger(0,close[bar],OBJPROP_FONTSIZE,14);
                ObjectSetInteger(0,close[bar],OBJPROP_COLOR,clrWhite);
                spike++;
                i = 0;
            }
        
        
        }
        i++;
        
    }
   
   return(rates_total);
}

