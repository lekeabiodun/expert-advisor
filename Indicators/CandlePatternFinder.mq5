
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

input int consecutiveSpike = 2; // Consecutive SPike



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
                spike++;
                
                if( spike == consecutiveSpike){ 
                    ObjectCreate(0, close[bar], OBJ_ARROW_DOWN, 0, time[bar], close[bar]+3);
                    ObjectSetInteger(0,close[bar],OBJPROP_COLOR,clrWhite);
                    spike = 0;
               }
            } else { spike = 0; }
        }
        if(spikeDir == CRASH)
        {
            
            if(close[bar] < open[bar])
            {
                spike++;
                if(spike == consecutiveSpike){
                    
                    ObjectCreate(0, close[bar], OBJ_ARROW_UP, 0, time[bar], close[bar]-1);
                    ObjectSetInteger(0,close[bar],OBJPROP_COLOR,clrWhite);
                    spike = 0;  
                }
            } else { spike = 0; }
        
        
        }
        
    }
   
   return(rates_total);
}

