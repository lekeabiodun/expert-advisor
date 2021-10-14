//+---------------------------------------------------------------------+
//|                                                    Ichimoku_Osc.mq5 | 
//|                                               Copyright © 2010, MDM | 
//|                                                                     | 
//+---------------------------------------------------------------------+
//| For the indicator to work, place the file SmoothAlgorithms.mqh      |
//| in the directory: terminal_data_folder\MQL5\Include                 |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2010, MDM"
#property link ""
#property description "Ichimoku_Osc"
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers
#property indicator_buffers 4 
//---- only two plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  Indicator 1 drawing parameters   |
//+-----------------------------------+
//---- drawing indicator as a three-colored line
#property indicator_type1   DRAW_COLOR_LINE
//---- the following colors are used for the indicator line
#property indicator_color1 clrGray,clrDeepSkyBlue,clrDeepPink
//---- indicator line is a solid one
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 4
#property indicator_width1  4
//---- displaying the indicator label
#property indicator_label1  "Signal"
//+-----------------------------------+
//|  Indicator 2 drawing parameters   |
//+-----------------------------------+
//---- drawing the indicator as a line
//#property indicator_type2   DRAW_LINE
//---- the following colors are used in the histogram
#property indicator_color2 clrGray
//---- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- Indicator line width is equal to 2
#property indicator_width2  2
//---- displaying the indicator label
#property indicator_label2  "Ichimoku Oscillator"

//+-----------------------------------+
//|  CXMA class description           |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XSIGN;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum IndStyle //The indicator display style
  {
   LINE = DRAW_LINE,          //line
   ARROW=DRAW_ARROW,          //icons
   HISTOGRAM=DRAW_HISTOGRAM   //histogram
  };
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
/*enum Smooth_Method is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input int Tenkan=9;      // Tenkan-sen
input int Kijun=26;      // Kijun-sen
input int Senkou=52;     // Senkou Span B

input Smooth_Method SSmoothMethod=MODE_JJMA; //signal line smoothing method
input int SPeriod=7;  //signal line period
input int SPhase=100;   //signal line parameter,
                        // for JJMA it varies within the range -100 ... +100 and influences the quality of the transient period;
// For VIDIA, it is a CMO period, for AMA, it is a slow moving average period

input int Shift=0; //horizontal shift of the indicator in bars
input IndStyle Style=DRAW_ARROW; //oscillator display style
//+-----------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double Osc[],XOsc[];
double ColorXOsc[];

//---- Declaration of integer variables for the indicator handles
int Ich_Handle;
//---- Declaration of integer variables of data starting point
int min_rates_total,min_rates_;
//+------------------------------------------------------------------+   
//| Osc indicator initialization function                            | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of the start of data calculation   
   min_rates_=int(MathMax(MathMax(Tenkan,Kijun),Senkou));
   min_rates_total=min_rates_+XSIGN.GetStartBars(SSmoothMethod,SPeriod,SPhase);

//---- getting the Ichimoku_Calc indicator handle
   Ich_Handle=iCustom(NULL,PERIOD_CURRENT,"Ichimoku_Calc",Tenkan,Kijun,Senkou,0);
   if(Ich_Handle==INVALID_HANDLE) Print(" Failed to get handle of Ichimoku_Calc indicator");

//---- setting alerts for invalid values of external parameters
   XSIGN.XMALengthCheck("SPeriod",SPeriod);
//---- setting alerts for invalid values of external parameters
   XSIGN.XMAPhaseCheck("SPhase",SPhase,SSmoothMethod);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,XOsc,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(XOsc,true);

//---- setting dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorXOsc,INDICATOR_COLOR_INDEX);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(ColorXOsc,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,Osc,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- changing of the indicator display style   
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,Style);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(Osc,true);

//---- initializations of variable for indicator short name
   string shortname,Smooth;
   Smooth=XSIGN.GetString_MA_Method(SSmoothMethod);
   StringConcatenate(shortname,"Ichimoku Oscillator(",string(Tenkan),",",Smooth,")");
//---- creating name for displaying if separate sub-window and in tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| Osc iteration function                                           | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- Checking if the number of bars is sufficient for the calculation
   if(BarsCalculated(Ich_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- declaration of variables with a floating point  
   double markt,trend,TS[],KS[],SA[],CS[];
//---- Declaration of integer variables
   int bar,limit,maxbar,to_copy;
   
   maxbar=rates_total-1-min_rates_total;

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_-1; // starting index for the calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars 
   
   to_copy=limit+1;

//---- copy newly appeared data into the arrays
   if(CopyBuffer(Ich_Handle,TENKANSEN_LINE,0,to_copy,TS)<=0) return(RESET);
   if(CopyBuffer(Ich_Handle,KIJUNSEN_LINE,0,to_copy,KS)<=0) return(RESET);
   if(CopyBuffer(Ich_Handle,SENKOUSPANB_LINE,0,to_copy,SA)<=0) return(RESET);
   if(CopyBuffer(Ich_Handle,CHINKOUSPAN_LINE,0,to_copy,CS)<=0) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(TS,true);
   ArraySetAsSeries(KS,true);
   ArraySetAsSeries(SA,true);
   ArraySetAsSeries(CS,true);

//---- Main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      markt=(CS[bar]-SA[bar]);
      trend=(TS[bar]-KS[bar]);

      Osc[bar]=(markt-trend)/_Point;
      
      //---- Loading the obtained value in the indicator buffer
      XOsc[bar]=XSIGN.XMASeries(maxbar,prev_calculated,rates_total,SSmoothMethod,SPhase,SPeriod,Osc[bar],bar,true);
     }

//---- Main loop of the signal line coloring
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ColorXOsc[bar]=0;
      if(XOsc[bar]>XOsc[bar+1]) ColorXOsc[bar]=1;
      if(XOsc[bar]<XOsc[bar+1]) ColorXOsc[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
