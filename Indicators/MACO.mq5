//+------------------------------------------------------------------+
//|                                                         MACO.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "© OPA Inc, 2020."
#property link      "lekepeterabiodun@gmail.com"
#property version   "1.00"
//---
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "FastMA"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "SlowMA"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

input int inpFastMA = 14; // Fast Moving Average
input int inpSlowMA = 50; // Slow Moving Average

double fastMABuffer[];
double slowMABuffer[];

double lineBuffer[];



void OnInit() 
  { 
//--- Bind the Array to the indicator buffer with index 0 
   SetIndexBuffer(0,fastMABuffer,INDICATOR_DATA);
   SetIndexBuffer(0,slowMABuffer,INDICATOR_DATA);
   //PlotIndexSetInteger(3,PLOT_DRAW_TYPE,159);
//--- Set the line drawing 
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
//--- Set the style line 
   //PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_DOT); 
//--- Set line color 
   //PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrLime); 
//--- Set line thickness 
   //PlotIndexSetInteger(0,PLOT_LINE_WIDTH,3); 
//--- Set labels for the line 
   //PlotIndexSetString(0,PLOT_LABEL,"Moving Average"); 
//--- 
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
   int fastMAHandle = iMA(0,0, inpFastMA, 0, MODE_LWMA, PRICE_LOW);
   int slowMAHandle = iMA(0,0, inpSlowMA, 0, MODE_LWMA, PRICE_LOW);
   
   double fastMAArray[], slowMAArray[];
   
   ArraySetAsSeries(fastMAArray, true);
   ArraySetAsSeries(slowMAArray, true);
   CopyBuffer(fastMAHandle, 0, 0, 0, fastMAArray);
   CopyBuffer(slowMAHandle, 0, 0, 0, slowMAArray);

   for(int i=prev_calculated;i<rates_total;i++) 
     { 
      fastMABuffer[i]=fastMAArray[i]; 
      slowMABuffer[i]=slowMAArray[i]; 
     } 

   return(rates_total); 
}

