

//--- plot Pivot
#property indicator_label1  "Pivot"
#property indicator_type1   DRAW_LINE
#property indicator_color1  DarkOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot R1
#property indicator_label2  "R1"
#property indicator_type2   DRAW_LINE
#property indicator_color2  LimeGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

static datetime timestamp;

int FirstMovingAverageHandle = iMA(_Symbol, _Period, 3, 0, MODE_LWMA, PRICE_LOW);
int SecondMovingAverageHandle = iMA(_Symbol, _Period, 5, 0, MODE_LWMA, PRICE_LOW);
int ThirdMovingAverageHandle = iMA(_Symbol, _Period, 50, 0, MODE_LWMA, PRICE_CLOSE);

void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   iCustom
   
   
   ChartIndicatorAdd(0,0,ThirdMovingAverageHandle);
   ChartIndicatorAdd(0,0,FirstMovingAverageHandle);
   
   if(timestamp != time) {
      double FirstMovingAverageArray[];
      double SecondMovingAverageArray[];
      double ThirdMovingAverageArray[];
      
      ArraySetAsSeries(FirstMovingAverageArray, true);
      ArraySetAsSeries(SecondMovingAverageArray, true);
      ArraySetAsSeries(ThirdMovingAverageArray, true);
      
      CopyBuffer(FirstMovingAverageHandle, 0, 1, 2, FirstMovingAverageArray);
      CopyBuffer(SecondMovingAverageHandle, 0, 1, 2, SecondMovingAverageArray);
      CopyBuffer(ThirdMovingAverageHandle, 0, 1, 2, ThirdMovingAverageArray);
      
      Print("First MA Value: ", FirstMovingAverageArray[0]);
      Print("Second MA Value: ", SecondMovingAverageArray[0]);
      Print("Third MA Value: ", ThirdMovingAverageArray[0]);
   
   }
   

}