//+------------------------------------------------------------------+
//|                                                 Fibo retrace.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6
//--- plot baseline
#property indicator_label1  "baseline1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot maxline
#property indicator_label2  "baseline2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot level236
#property indicator_label3  "23.6%"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_DOT
#property indicator_width3  1
//--- plot level382
#property indicator_label4  "38.2%"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_DOT
#property indicator_width4  1
//--- plot level50
#property indicator_label5  "50.0%"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrRed
#property indicator_style5  STYLE_DOT
#property indicator_width5  1
//--- plot level618
#property indicator_label6  "61.8%"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_style6  STYLE_DOT
#property indicator_width6  1
//--- input parameters
input int      pastbars=30;
//--- indicator buffers
double         baseline1Buffer[];
double         baseline2Buffer[];
double         level236Buffer[];
double         level382Buffer[];
double         level500Buffer[];
double         level618Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,baseline1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,baseline2Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,level236Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,level382Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,level500Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,level618Buffer,INDICATOR_DATA);

   IndicatorSetInteger(INDICATOR_DIGITS,Digits());

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,pastbars+1);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,pastbars+1);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,pastbars+1);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,pastbars+1);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,pastbars+1);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,pastbars+1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   if(rates_total<pastbars+1)
      return(0);
   int i,j,locationmax=0,locationmin=0;
   double max=0,min=0,h,l,h2,l2;
   for(i=rates_total-1-pastbars;i<rates_total;i++)
     {
      for(int k=0;k<rates_total-pastbars;k++) //empty previous fibo values
        {
         baseline1Buffer[k] = 0;
         baseline2Buffer[k] = 0;
         level236Buffer[k] = 0;
         level382Buffer[k] = 0;
         level500Buffer[k] = 0;
         level618Buffer[k] = 0;
        }
      for(j=0;j<pastbars;j++)
        {
         if(i-j<=rates_total-1-pastbars) break;
         h=high[i]; h2=high[i-j];
         l=low[i]; l2=low[i-j];
         if(max==0)
           {
            max=MathMax(h,h2);
            if(max==h) locationmax=i;
            else locationmax=i-j;
           }
         else
           {
            if(MathMax(h,h2)>max)
              {
               max=MathMax(h,h2);
               if(max==h) locationmax=i;
               else locationmax=i-j;
              }
           }
         if(min==0)
           {
            min=MathMin(l,l2);
            if(min==l) locationmin=i;
            else locationmin=i-j;
           }
         else
           {
            if(MathMin(l,l2)<min)
              {
               min=MathMin(l,l2);
               if(min==l) locationmin=i;
               else locationmin=i-j;
              }
           }
        }
      baseline1Buffer[i] = max;
      baseline2Buffer[i] = min;
      if(locationmax>locationmin)
        {
         level236Buffer[i] = NormalizeDouble(max-(max-min)*0.236,Digits());
         level382Buffer[i] = NormalizeDouble(max-(max-min)*0.382,Digits());
         level500Buffer[i] = NormalizeDouble(max-(max-min)*0.5,Digits());
         level618Buffer[i] = NormalizeDouble(max-(max-min)*0.618,Digits());
        }
      else
        {
         level236Buffer[i] = NormalizeDouble(min+(max-min)*0.236,Digits());
         level382Buffer[i] = NormalizeDouble(min+(max-min)*0.382,Digits());
         level500Buffer[i] = NormalizeDouble(min+(max-min)*0.5,Digits());
         level618Buffer[i] = NormalizeDouble(min+(max-min)*0.618,Digits());
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
