static datetime timestamp;
int status = 1;
double tradingRange = 0;

int count = 1;

int SlowMovingAverageHandle = iMA(_Symbol, _Period, 50, 0, MODE_LWMA, PRICE_CLOSE);
int FastMovingAverageHandle = iMA(_Symbol, _Period, 14, 0, MODE_LWMA, PRICE_CLOSE);

int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick()  {

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
        
      timestamp = time;
   
      int HighestCandle = iHighest(Symbol(), Period(), MODE_HIGH,100,1);
      int LowestCandle = iLowest(Symbol(), Period(), MODE_LOW, 100, 1);

      MqlRates PriceInformation[];
      
      ArraySetAsSeries(PriceInformation, true);
      
      int Data = CopyRates(Symbol(), Period(), 0, Bars(Symbol(), Period()), PriceInformation);
   
      ObjectCreate(0, "Line1", OBJ_HLINE, 0, 0, PriceInformation[HighestCandle].high);
      ObjectSetInteger(0, "Line1", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "Line1", OBJPROP_WIDTH, 3);
      ObjectMove(0, "Line1", 0, 0, PriceInformation[HighestCandle].high);
      
      
      ObjectCreate(0, "Line2", OBJ_HLINE, 0, 0, PriceInformation[LowestCandle].low);
      ObjectSetInteger(0, "Line2", OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(0, "Line2", OBJPROP_WIDTH, 3);
      ObjectMove(0, "Line2", 0, 0, PriceInformation[LowestCandle].low);

      
      tradingRange = PriceInformation[HighestCandle].high - PriceInformation[LowestCandle].low;
      
      Print("Price Information High: ", PriceInformation[HighestCandle].high);
      Print("Price Information Low: ", PriceInformation[LowestCandle].low);
      
      Print("TradingRange: ", tradingRange);
      
      //Comment("The current trading range: ", tradingRange);
      double FastMovingAverageArray[];
      double SlowMovingAverageArray[];
      ArraySetAsSeries(FastMovingAverageArray, true);
      ArraySetAsSeries(SlowMovingAverageArray, true);
      CopyBuffer(FastMovingAverageHandle, 0, 1, 2, FastMovingAverageArray);
      CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);
   
      if(FastMovingAverageArray[0] > SlowMovingAverageArray[0] && FastMovingAverageArray[1] < SlowMovingAverageArray[1]){
      
         ObjectCreate(0, IntegerToString(time), OBJ_ARROW_UP, 0, TimeCurrent(), (SlowMovingAverageArray[1]));
         ObjectSetInteger(0, IntegerToString(time), OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, IntegerToString(time), OBJPROP_WIDTH, 3);
         
      }
      
      if(FastMovingAverageArray[0] < SlowMovingAverageArray[0] && FastMovingAverageArray[1] > SlowMovingAverageArray[1]){
      
         ObjectCreate(0, IntegerToString(time), OBJ_ARROW_DOWN, 0, TimeCurrent(), (FastMovingAverageArray[1]));
         ObjectSetInteger(0, IntegerToString(time), OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, IntegerToString(time), OBJPROP_WIDTH, 3);
         
      }
           
//      if(tradingRange <= 45 && status == 2){
//      
//         ObjectCreate(0, IntegerToString(time), OBJ_ARROW_UP, 0, TimeCurrent(), (PriceInformation[LowestCandle].low));
//         ObjectSetInteger(0, IntegerToString(time), OBJPROP_COLOR, clrGreen);
//         ObjectSetInteger(0, IntegerToString(time), OBJPROP_WIDTH, 3);
//         status = 1;
//      }
//   
//   
//      if(tradingRange >= 80 && status == 1){
//      
//         ObjectCreate(0, IntegerToString(time), OBJ_ARROW_DOWN, 0, TimeCurrent(), (PriceInformation[HighestCandle].high));
//         ObjectSetInteger(0, IntegerToString(time), OBJPROP_COLOR, clrRed);
//         ObjectSetInteger(0, IntegerToString(time), OBJPROP_WIDTH, 3);
//         status = 2;
//      }
   }
}