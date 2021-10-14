//+---------------------------------------------------------------------+ 
//|                                           Cronex Super Position.mq5 | 
//|                                           Copyright © 2007, Cronex. |
//|                                          http://www.metaquotes.net/ |
//+---------------------------------------------------------------------+
//| For the indicator to work, place the file SmoothAlgorithms.mqh      |
//| in the directory: terminal_data_folder\\MQL5\Include                |
//+---------------------------------------------------------------------+
#property  copyright "Copyright © 2007, Cronex"
#property  link      "http://www.metaquotes.net/"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 7
#property indicator_buffers 7 
//---- 6 graphical plots are used in total
#property indicator_plots   6
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1 DRAW_LINE
//---- use silver color for the line
#property indicator_color1 Silver
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1 1
//---- displaying the line label
#property indicator_label1  "RSI Super Position"

//---- drawing the indicator as a line
#property indicator_type2 DRAW_LINE
//---- dark orange color is used for the line
#property indicator_color2 DarkOrange
//---- indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width2 1
//---- displaying the line label
#property indicator_label2  "DeMarker Super Position"

//---- drawing the indicator as a line
#property indicator_type3 DRAW_LINE
//---- use black color for the line
#property indicator_color3 Black
//---- indicator line is a solid one
#property indicator_style3 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width3 1
//---- displaying the line label
#property indicator_label3  "Cronex Super Position"

//---- drawing the indicator as a line
#property indicator_type4 DRAW_LINE
//---- use red color for the line
#property indicator_color4 Red
//---- indicator line is a solid one
#property indicator_style4 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width4 1
//---- displaying the signal line label
#property indicator_label4  "Fast Signal Line"

//---- drawing the indicator as a line
#property indicator_type5 DRAW_LINE
//---- use blue color for the line
#property indicator_color5 Blue
//---- indicator line is a solid one
#property indicator_style5 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width5 1
//---- displaying the signal line label
#property indicator_label5  "Slow Signal Line"

//---- drawing the indicator as a color histogram
#property indicator_type6 DRAW_COLOR_HISTOGRAM
//---- the following colors are used in the histogram Gray,Teal,BlueViolet,IndianRed,Magenta 
#property indicator_color6 Gray,Teal,BlueViolet,IndianRed,Magenta
//---- indicator line is a solid one
#property indicator_style6 STYLE_SOLID
//---- the width of the indicator line is 3
#property indicator_width6 3
//---- displaying the indicator label
#property indicator_label6 "Super Position Divergence"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 -0.20
#property indicator_level2  0.20
#property indicator_level3  0.50
#property indicator_level4  0.80
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_SOLID
//+-----------------------------------+
//|  Smoothings classes description   |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- declaration of the CMoving_Average class variables from the SmoothAlgorithms.mqh file
CMoving_Average MA1,MA2,MA3;
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int RSI=10;      // RSI period
input int DeMarker=10; // DeMarker period
input int SPStep=4;    // Interval range
input int FastMA=10;   // Fast smoothing period
input int SlowMA=18;   // Slow smoothing period
//+-----------------------------------+
//---- declaration of integer variables for the indicators handles
int RSI_Handle[4],DEM_Handle[4];
//---- declaration of the integer variables for the start of data calculation
int start,sp_start;
//---- declaration of dynamic arrays that 
//---- will be used as indicator buffers
double RSIBuffer[],DeMarkerBuffer[],SPBuffer[];
double FastMABuffer[],SlowMABuffer[],DiverBuffer[],ColorDiverBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   int rsi_start=RSI+SPStep*3;
   int demark_start=DeMarker+SPStep*3;
   sp_start=MathMax(rsi_start,demark_start);
   start=sp_start+MathMax(FastMA,SlowMA);
//---- obtaining the indicators handles   
   for(int numb=0; numb<4; numb++)
     {
      RSI_Handle[numb]=iRSI(NULL,0,RSI+SPStep*numb,PRICE_WEIGHTED);
      DEM_Handle[numb]=iDeMarker(NULL,0,DeMarker+SPStep*numb);
     }

//---- set RSIBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,RSIBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rsi_start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(RSIBuffer,true);

//---- set DeMarkerBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,DeMarkerBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,demark_start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(DeMarkerBuffer,true);

//---- set SPBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,SPBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,sp_start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(SPBuffer,true);

//---- set FastMABuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(3,FastMABuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,sp_start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(FastMABuffer,true);

//---- set SlowMABuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(4,SlowMABuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,sp_start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(SlowMABuffer,true);

//---- set DiverBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(5,DiverBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,start);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(DiverBuffer,true);

//---- set ColorDiverBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(6,ColorDiverBuffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,start+1);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ColorDiverBuffer,true);

//---- setting up alerts for unacceptable values of external variables
   MA1.MALengthCheck("RSI", RSI);
   MA1.MALengthCheck("DeMarker", DeMarker);
   MA1.MALengthCheck("FastMA", FastMA);
   MA1.MALengthCheck("SlowMA", SlowMA);
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI DeMarker Super Position");
//---- determine the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
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
   if(rates_total<start) return(0);
   for(int numb=0; numb<4; numb++) if(BarsCalculated(RSI_Handle[numb])<rates_total) return(0);
   for(int numb=0; numb<4; numb++) if(BarsCalculated(DEM_Handle[numb])<rates_total) return(0);
//---- declaration of integer variables
   int limit,bar,to_copy,StartBar;
//---- declaration of variables with a floating point  
   double RSI0[],RSI1[],RSI2[],RSI3[],DEM0[],DEM1[],DEM2[],DEM3[],TmpDiver;
//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(RSI0,true);
   ArraySetAsSeries(RSI1,true);
   ArraySetAsSeries(RSI2,true);
   ArraySetAsSeries(RSI3,true);
   ArraySetAsSeries(DEM0,true);
   ArraySetAsSeries(DEM1,true);
   ArraySetAsSeries(DEM2,true);
   ArraySetAsSeries(DEM3,true);
//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-sp_start;                        // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;                 // starting index for calculation of new bars
     }

   to_copy=limit+1;
   StartBar=rates_total-sp_start-1;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(RSI_Handle[0],0,0,to_copy,RSI0)<=0) return(0);
   if(CopyBuffer(RSI_Handle[1],0,0,to_copy,RSI1)<=0) return(0);
   if(CopyBuffer(RSI_Handle[2],0,0,to_copy,RSI2)<=0) return(0);
   if(CopyBuffer(RSI_Handle[3],0,0,to_copy,RSI3)<=0) return(0);
   if(CopyBuffer(DEM_Handle[0],0,0,to_copy,DEM0)<=0) return(0);
   if(CopyBuffer(DEM_Handle[1],0,0,to_copy,DEM1)<=0) return(0);
   if(CopyBuffer(DEM_Handle[2],0,0,to_copy,DEM2)<=0) return(0);
   if(CopyBuffer(DEM_Handle[3],0,0,to_copy,DEM3)<=0) return(0);

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
      RSIBuffer[bar]=(RSI0[bar]+RSI1[bar]+RSI2[bar]+RSI3[bar])/400.0;
      DeMarkerBuffer[bar]=(DEM0[bar]+DEM1[bar]+DEM2[bar]+DEM3[bar])/4.0;
      //----
      SPBuffer[bar]=(RSIBuffer[bar]+DeMarkerBuffer[bar])/2;
      TmpDiver=DeMarkerBuffer[bar]-RSIBuffer[bar];
      //----
      FastMABuffer[bar] = MA1.MASeries(StartBar, prev_calculated, rates_total, FastMA, MODE_LWMA, SPBuffer[bar], bar, true);
      SlowMABuffer[bar] = MA2.MASeries(StartBar, prev_calculated, rates_total, SlowMA, MODE_LWMA, SPBuffer[bar], bar, true);
      DiverBuffer[bar]  = MA3.MASeries(StartBar, prev_calculated, rates_total, FastMA, MODE_LWMA, TmpDiver,      bar, true);
     }
//---- recalculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
      limit--;
//---- main cycle of the histogram coloring
   for(bar=limit; bar>=0; bar--)
     {
      ColorDiverBuffer[bar]=0;

      if(DiverBuffer[bar]>0)
        {
         if(DiverBuffer[bar]>DiverBuffer[bar+1]) ColorDiverBuffer[bar]=1;
         if(DiverBuffer[bar]<DiverBuffer[bar+1]) ColorDiverBuffer[bar]=2;
        }

      if(DiverBuffer[bar]<0)
        {
         if(DiverBuffer[bar]<DiverBuffer[bar+1]) ColorDiverBuffer[bar]=3;
         if(DiverBuffer[bar]>DiverBuffer[bar+1]) ColorDiverBuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+