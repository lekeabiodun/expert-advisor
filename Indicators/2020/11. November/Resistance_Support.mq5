//+------------------------------------------------------------------+
//|                                           Resistance_Support.mq5 |
//|                                                 Kisselyov Andrey |
//|                                        xjfspmbxcnrnlld@gmail.com |
//|                                            Skype:mzbh9v2tlbq9ak4 |
//+------------------------------------------------------------------+
//|                 THIS IS NOT A READY-TO-USE PRODUCT               |
//|                 IT IS ONLY AN EXAMPLE OF DRAWING                 |
//|               TREND LINES UNDER SPECIFIC CONDITIONS              |
//+------------------------------------------------------------------+
#property copyright "Kisselyov Andrey"
#property link      "xjfspmbxcnrnlld@gmail.com"
#property link      "Skype:mzbh9v2tlbq9ak4"
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot Support
#property indicator_label1  "Support"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Resistance
#property indicator_label2  "Resistance"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- input parameters
input int      Pips_=50;
input int      MaxBars=100;
//--- indicator buffers
double         SupportBuffer[];
double         ResistanceBuffer[];
//+------------------------------------------------------------------+
bool type=false;
double speedr=0,speeds=0;
int r1=0,r2=0,s1=0,s2=0;
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SupportBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ResistanceBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---
   return(INIT_SUCCEEDED);
  }
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
   int limit=prev_calculated;
   if(limit>3)limit-=3;//we work with fractals
   if(limit<2)limit=2;

   for(int w=limit;w<rates_total;w++)
     {
      if(w>r1+MaxBars){r1=0;r2=0;}//reset the line if it is too long
      if(r2!=0)//if there are required data, draw the line
        {
         ResistanceBuffer[w]=high[r1]+speedr*(w-r1);//for the error to be minimal, we calculate from the very peak
         if(w>r2)//check if there is a breakout
         if(high[w]>ResistanceBuffer[w]+Pips_*_Point){r1=0;r2=0;}
        }
      else//if(r2==0)
        {
         ResistanceBuffer[w]=EMPTY_VALUE;//reset the buffer if there are no data to draw
         if(up(high,w))//check if there is a fractal on this bar
           {
            if(r1==0)r1=w;//if it is a fractal and we do not have peak 1, set peak 1 here
            else
              {
               if(high[w]>=high[r1])r1=w;//compare to the first peak, and if the fractal is higher set this peak as the first one
               else
                 {
                  r2=w;speedr=(high[r2]-high[r1])/(r2-r1);//we got the value of the second line and could calculate the line speed
                  w=r1-1;//return to draw a new line
                 }
              }
           }
        }
     }
   for(int w=limit;w<rates_total;w++)
     {
      if(w>s1+MaxBars){s1=0;s2=0;}
      if(s2!=0)
        {
         SupportBuffer[w]=low[s1]+speeds*(w-s1);
         if(w>s2)
         if(low[w]<SupportBuffer[w]-Pips_*_Point){s1=0;s2=0;}
        }
      else//if(s2==0)
        {
         SupportBuffer[w]=EMPTY_VALUE;
         if(down(low,w))
           {
            if(s1==0)s1=w;
            else
              {
               if(low[w]<=low[s1])s1=w;
               else
                 {
                  s2=w;speeds=(low[s2]-low[s1])/(s2-s1);
                  w=s1-1;
                 }
              }
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
bool up(const double &h[],int q)
  {
   if(q>=ArraySize(h)-2)return(false);
   if(q<2)return(false);
   if(h[q]>=h[q-1])
      if(h[q]>=h[q-2])
         if(h[q]>h[q+1])
            if(h[q]>h[q+2])
               return(true);
   return(false);
  }
//+------------------------------------------------------------------+
bool down(const double &h[],int q)
  {
   if(q>=ArraySize(h)-2)return(false);
   if(q<2)return(false);
   if(h[q]<=h[q-1])
      if(h[q]<=h[q-2])
         if(h[q]<h[q+1])
            if(h[q]<h[q+2])
               return(true);
   return(false);
  }
//+------------------------------------------------------------------+
