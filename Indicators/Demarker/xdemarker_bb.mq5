//+------------------------------------------------------------------+
//|                                                   XDemark_BB.mq5 | 
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//| Place the SmoothAlgorithms.mqh file                              |
//| to the directory: terminal_data_folder\MQL5\Include              |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- indicator version
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 10
#property indicator_buffers 10 
//---- 8 graphical plots are used
#property indicator_plots   8
//+-----------------------------------+
//|  Indicator 1 drawing parameters   |
//+-----------------------------------+
//---- drawing indicator as a three-colored line
#property indicator_type1 DRAW_COLOR_LINE
//---- the following colors are used for the indicator line
#property indicator_color1 Gray,Lime,Orange
//---- the indicator line is a stroke
#property indicator_style1 STYLE_DASHDOTDOT
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1 "Signal line"
//+-----------------------------------+
//|  Indicator 2 drawing parameters   |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type2 DRAW_LINE
//---- the following colors are used for the indicator line
#property indicator_color2 Gray
//---- the indicator line is a stroke
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width2 1
//---- displaying the indicator label
#property indicator_label2 "XDemark line"
//+-----------------------------------+
//|  Indicator 2 drawing parameters   |
//+-----------------------------------+
//---- drawing the indicator as colored labels
#property indicator_type3 DRAW_COLOR_ARROW
//---- the following colors are used for labels
#property indicator_color3 Gray,Green,Blue,Red,Magenta
//---- the indicator line is a continuous curve
#property indicator_style3 STYLE_SOLID
//---- the indicator line width is equal to 3
#property indicator_width3 3
//---- displaying the indicator label
#property indicator_label3 "XDemark arrow"
//+--------------------------------------------+
//|  BB levels indicator drawing parameters    |
//+--------------------------------------------+
//---- drawing Bollinger Bands as lines
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_LINE
//---- selection of Bollinger Bands colors
#property indicator_color4  Blue
#property indicator_color5  Red
#property indicator_color6  Gray
#property indicator_color7  Red
#property indicator_color8  Blue
//---- Bollinger Bands are dott-dash curves
#property indicator_style4 STYLE_DASHDOTDOT
#property indicator_style5 STYLE_DASHDOTDOT
#property indicator_style6 STYLE_DASHDOTDOT
#property indicator_style7 STYLE_DASHDOTDOT
#property indicator_style8 STYLE_DASHDOTDOT
//---- Bollinger Bands width is equal to 1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
//---- display the labels of Bollinger Bands levels
#property indicator_label4  "+2Sigma"
#property indicator_label5  "+Sigma"
#property indicator_label6  "Middle"
#property indicator_label7  "-Sigma"
#property indicator_label8  "-2Sigma"
//+-------------------------------------------------+
//| Description of smoothing classes and indicators |
//+-------------------------------------------------+
#include <SmoothAlgorithms.mqh>
//+-----------------------------------+
//---- declaration of the CXMA and CStdDeviation classes variables from the SmoothAlgorithms.mqh file
CXMA UPXDemark,DNXDemark,XSIGN,XMA;
CStdDeviation STD;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
/*enum Smooth_Method is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  }; */
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input Smooth_Method DSmoothMethod=MODE_JurX; // DeMarker smoothing method
input int DPeriod=14;                        // DeMarker period
input int DPhase=100;                        // Demarker smoothing parameter
input Smooth_Method SSmoothMethod=MODE_JJMA; // Signal line smoothing method
input int SPeriod=12;                        // Signal line period
input int SPhase=100;                        // Signal line parameter
input Applied_price_ IPC=PRICE_CLOSE;        // Price constant
input int Shift=0;                           // Horizontal shift of the indicator in bars
input int BBPeriod=100;                      // Bollinger Bands period
input double BBDeviation1 = 1.0;             // Small deviation value
input double BBDeviation2 = 1.6;             // Big deviation value
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double XDemark[],XDemarkLine[],XXDemark[];
double ColorXDemark[],ColorXXDemark[];
double ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[],ExtLineBuffer4[],ExtLineBuffer5[];
//---- declaration of the Bollinger Bands proportion variable
double quotient;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,min_rates_totalD,min_rates_totalS,min_rates_totalB;
//+------------------------------------------------------------------+   
//| XDemark indicator initialization function                        | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_totalD=UPXDemark.GetStartBars(DSmoothMethod,DPeriod,DPhase)+1;
   min_rates_totalS=min_rates_totalD+UPXDemark.GetStartBars(SSmoothMethod,SPeriod,SPhase);
   min_rates_totalB=min_rates_totalD+BBPeriod;
   min_rates_total=MathMax(min_rates_totalS,min_rates_totalB);
//---- setting up alerts for unacceptable values of external variables
   UPXDemark.XMALengthCheck("DPeriod", DPeriod);
   UPXDemark.XMALengthCheck("SPeriod", SPeriod);
//---- setting up alerts for unacceptable values of external variables
   UPXDemark.XMAPhaseCheck("DPhase",DPhase,DSmoothMethod);
   UPXDemark.XMAPhaseCheck("SPhase",SPhase,SSmoothMethod);
//---- initialization of the Bollinger Bands proportion variable
   quotient=BBDeviation2/BBDeviation1;
//---- set XXDemark[] dynamic array as an indicator buffer
   SetIndexBuffer(0,XXDemark,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_totalS+1);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ColorXXDemark[] dynamic array as an indicator buffer   
   SetIndexBuffer(1,ColorXXDemark,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_totalS+1);

//---- set XDemarkLine[] dynamic array as an indicator buffer
   SetIndexBuffer(2,XDemarkLine,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_totalD);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set XDemark[] dynamic array as an indicator buffer
   SetIndexBuffer(3,XDemark,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_totalD+1);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ColorXDemark[] dynamic array as a colored index buffer   
   SetIndexBuffer(4,ColorXDemark,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_totalD+1);

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(5,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(7,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(8,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(9,ExtLineBuffer5,INDICATOR_DATA);
//---- set the position, from which the Bollinger Bands drawing starts
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_totalB);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_totalB);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,min_rates_totalB);
   PlotIndexSetInteger(8,PLOT_DRAW_BEGIN,min_rates_totalB);
   PlotIndexSetInteger(9,PLOT_DRAW_BEGIN,min_rates_totalB);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- initializations of a variable for the indicator short name
   string shortname,Smooth;
   Smooth=UPXDemark.GetString_MA_Method(DSmoothMethod);
   StringConcatenate(shortname,"XDemark(",string(DPeriod),",",Smooth,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- initialization end
  }
//+------------------------------------------------------------------+ 
//| XDemark iteration function                                       | 
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
   if(rates_total<min_rates_total) return(0);

//---- declaration of variables with a floating point  
   double up_demark,dn_demark,up_xdemark,dn_xdemark,xdemark,xxdemark,xma,stdev1,stdev2;
//---- declaration of integer variables and getting calculated bars
   int first1,first2,bar;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first1=1;                  // starting index for calculation of all bars
      first2=min_rates_totalS+1;
     }
   else
     {
      first1=prev_calculated-1; // starting index for calculation of new bars
      first2=first1;
     }

//---- main indicator calculation loop
   for(bar=first1; bar<rates_total; bar++)
     {
      if(high[bar]>high[bar-1]) up_demark=high[bar]-high[bar-1]; else up_demark=0.0;
      if(low [bar]<low [bar-1]) dn_demark=low [bar-1]-low[bar];  else dn_demark=0.0;

      //---- two calls of the XMASeries function 
      up_xdemark=UPXDemark.XMASeries(1,prev_calculated,rates_total,DSmoothMethod,DPhase,DPeriod,up_demark,bar,false);
      dn_xdemark=DNXDemark.XMASeries(1,prev_calculated,rates_total,DSmoothMethod,DPhase,DPeriod,dn_demark,bar,false);

      dn_xdemark+=up_xdemark;
      if(dn_xdemark!=0) xdemark=up_xdemark/dn_xdemark;
      else xdemark=EMPTY_VALUE;

      //---- loading the obtained value in the indicator buffers
      XDemark[bar]=xdemark;
      XDemarkLine[bar]=xdemark;

      //---- signal line calculation
      xxdemark=XSIGN.XMASeries(min_rates_totalD,prev_calculated,rates_total,SSmoothMethod,SPhase,SPeriod,xdemark,bar,false);

      //---- loading the obtained value in the indicator buffer
      XXDemark[bar]=xxdemark;

      //---- Bollinger Bands calculation      
      xma=XMA.XMASeries(min_rates_totalD+1,prev_calculated,rates_total,MODE_SMA_,0,BBPeriod,xdemark,bar,false);
      stdev1=STD.StdDevSeries(min_rates_totalB,prev_calculated,rates_total,BBPeriod,BBDeviation1,xdemark,xma,bar,false);
      stdev2=stdev1*quotient;
      //---- 
      if(bar<=min_rates_totalB+BBPeriod)
        {
         xma=EMPTY_VALUE;
         stdev1=0.0;
         stdev2=0.0;
        }

      ExtLineBuffer1[bar]=xma+stdev2;
      ExtLineBuffer2[bar]=xma+stdev1;
      ExtLineBuffer3[bar]=xma;
      ExtLineBuffer4[bar]=xma-stdev1;
      ExtLineBuffer5[bar]=xma-stdev2;
     }

//---- main loop of the XDemark indicator coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorXDemark[bar]=0;

      if(XDemark[bar]>ExtLineBuffer3[bar])
        {
         if(XDemark[bar]>XDemark[bar-1]) ColorXDemark[bar]=1;
         if(XDemark[bar]<XDemark[bar-1]) ColorXDemark[bar]=2;
        }

      if(XDemark[bar]<ExtLineBuffer3[bar])
        {
         if(XDemark[bar]<XDemark[bar-1]) ColorXDemark[bar]=3;
         if(XDemark[bar]>XDemark[bar-1]) ColorXDemark[bar]=4;
        }
     }

//---- main loop of the XXDemark signal line coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorXXDemark[bar]=0;
      if(XDemark[bar]>XXDemark[bar-1]) ColorXXDemark[bar]=1;
      if(XDemark[bar]<XXDemark[bar-1]) ColorXXDemark[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
