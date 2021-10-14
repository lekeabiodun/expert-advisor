/*
 * The SmoothAlgorithms.mqh file must be placed 
 * to terminal_data_folder\MQL5\Include
 */
//+------------------------------------------------------------------+
//|                                            Center of Gravity.mq4 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- three buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing indicator 1 as a three-colored line
#property indicator_type1 DRAW_COLOR_LINE
//---- used as a three-colored line colors
#property indicator_color1 Gray,Lime,Red
//---- line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying of the indicator label 1
#property indicator_label1  "Center of Gravity"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used as the color of the indicator line
#property indicator_color2  Blue
//---- line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- thickness of line of the indicator 2 is equal to 1
#property indicator_width2  1
//---- displaying of the indicator line label 2
#property indicator_label2  "Signal Line"
//---- line style is a dot-dash curve
#property indicator_style2 STYLE_DASHDOTDOT
//+-----------------------------------+
//|  Indicators input parameters      |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPLE_,//PRICE_SIMPLE_
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_   //PRICE_TRENDFOLLOW1_
  };
input int Period_=10;                          // Indicator averaging period
input int SmoothPeriod=3;                      // Signal line smoothing period
input ENUM_MA_METHOD MA_Method_=MODE_SMA;      // Signal line averaging method
input Applied_price_ AppliedPrice=PRICE_CLOSE_;// Price constant
/* , used for calculation of the indicator ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPLE, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
//+-----------------------------------+
//---- declaration of dynamic arrays that further
//---- will be used as indicator buffers
double Ext1Buffer[];
double Ext2Buffer[];
double ColorExt2Buffer[];
//---- Declaration of the integer variables for the start of data calculation
int StartBar;
//+------------------------------------------------------------------+
//| iPriceSeries function description                                |
//| Moving_Average class description                                 | 
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of constants
   StartBar=Period_;
//---- set MAMABuffer dynamic array as indicator buffer
   SetIndexBuffer(0,Ext1Buffer,INDICATOR_DATA);
//---- creating label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Center of Gravity");
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBar);
//---- turning a dynamic array into a color index buffer   
   SetIndexBuffer(1,ColorExt2Buffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBar+1);

//---- set FAMABuffer dynamic array as indicator array
   SetIndexBuffer(2,Ext2Buffer,INDICATOR_DATA);
//---- creating label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Signal Line");
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,StartBar+1);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Center of Gravity(",Period_,")");
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- set accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBar) return(0);

//---- Declaration of variables with a floating point  
   double price_,sma,lwma;
//---- Declaration of integer variables
   int first1,first2,first3,bar;

//---- Initialization of the indicator in the OnCalculate() block
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      first1=0; // starting number for calculation of all first loop bars
      first2=Period_+1; // starting number for calculation of all signal line bars
      first3=Period_+SmoothPeriod+3; // starting number for calculation of all coloring loop bars
     }
   else // starting number for calculation of new bars
     {
      first1=prev_calculated-1;
      first2=first1;
      first3=first1;
     }

//---- declaration of variables of the Moving_Average class
   static CMoving_Average MA,LWMA,SIGN;

//---- Main cycle of calculation of the channel center line
   for(bar=first1; bar<rates_total; bar++)
     {
      //---- Call of the PriceSeries function to get the input price 'Series'
      price_=PriceSeries(AppliedPrice,bar,open,low,high,close);

      sma=MA.MASeries(0,prev_calculated,rates_total,Period_,MODE_SMA,price_,bar,false);
      lwma=LWMA.MASeries(0,prev_calculated,rates_total,Period_,MODE_LWMA,price_,bar,false);

      Ext1Buffer[bar]=sma*lwma/_Point;
      Ext2Buffer[bar]=SIGN.MASeries(first2,prev_calculated,rates_total,SmoothPeriod,MA_Method_,Ext1Buffer[bar],bar,false);
     }

//---- Main loop of the signal line coloring
   for(bar=first3; bar<rates_total; bar++)
     {
      ColorExt2Buffer[bar]=0;
      if(Ext1Buffer[bar]<Ext2Buffer[bar])
         ColorExt2Buffer[bar]=2;
      else ColorExt2Buffer[bar]=1;
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
