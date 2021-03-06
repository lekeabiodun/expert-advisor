//------------------------------------------------------------------
#property copyright   "© OPA Inc, 2020"
#property link        "lekepeterabiodun@gmail.com"
#property description "Trend Master Line"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

int fastMAHandle = iMA(_Symbol, _Period, 8, 0, MODE_LWMA, PRICE_CLOSE);
int slowMAHandle = iMA(_Symbol, _Period, 48, 0, MODE_LWMA, PRICE_CLOSE);

int OnInit()
{

   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason) { return; }


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   datetime timestamp = iTime(_Symbol, _Period, 0);
   
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   
   for(int i=0; i<=rates_total; i++){
   
      double fastMA[], slowMA[];
   
      ArraySetAsSeries(fastMA, true);
      ArraySetAsSeries(slowMA, true);
      
      CopyBuffer(fastMAHandle, 0, 1, 100, fastMA);
      CopyBuffer(slowMAHandle, 0, 1, 100, slowMA);
   
      
      if(fastMA[0] > slowMA[0] && fastMA[1] < slowMA[1]){
            Print("Sell");
      
            ObjectCreate(0, IntegerToString(timestamp), OBJ_ARROW_DOWN, 0, TimeCurrent(), (fastMA[1]));
            ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_WIDTH, 1);   
      }
      if(fastMA[0] < slowMA[0] && fastMA[1] > slowMA[1]){
            Print("Buy");
      
            ObjectCreate(0, IntegerToString(timestamp), OBJ_ARROW_UP, 0, TimeCurrent(), (fastMA[1]));
            ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_WIDTH, 1);   
      }
   }
      
          
   return(rates_total);
}