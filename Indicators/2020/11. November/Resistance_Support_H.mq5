//+------------------------------------------------------------------+
//|                                         Resistance_Support_H.mq5 |
//|                                                 Kisselyov Andrey |
//|                                            Skype:mzbh9v2tlbq9ak4 |
//|                                        xjfspmbxcnrnlld@gmail.com |
//+------------------------------------------------------------------+
//|                 THIS IS NOT A READY-TO-USE PRODUCT               |
//|                 IT IS ONLY AN EXAMPLE OF DRAWING                 |
//|               TREND LINES UNDER SPECIFIC CONDITIONS              |
//+------------------------------------------------------------------+
#property copyright "Kisselyov Andrey"
#property link      "skype:mzbh9v2tlbq9ak4"
#property link      "xjfspmbxcnrnlld@gmail.com"
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7
//--- plot Support
#property indicator_label1  "S1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Resistance
#property indicator_label2  "R1"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Support
#property indicator_label3  "S2"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Resistance
#property indicator_label4  "R2"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot Support
#property indicator_label5  "S3"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrGreen
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot Resistance
#property indicator_label6  "R3"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1
//--- plot Resistance
#property indicator_label7  "Mediana"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
//--- input parameters
input double               K_Fibo_1=0.8;
input double               K_Fibo_2=1.0;
input double               K_Fibo_3=1.618;
input ENUM_TIMEFRAMES      Period_TF=PERIOD_D1;
//--- indicator buffers
double         buffer1[];
double         buffer2[];
double         buffer3[];
double         buffer4[];
double         buffer5[];
double         buffer6[];
double         buffer7[];
datetime time_tf[];
double high_tf[];
double low_tf[];
int bars_tf=0;
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,buffer1,INDICATOR_DATA);
   SetIndexBuffer(1,buffer2,INDICATOR_DATA);
   SetIndexBuffer(2,buffer3,INDICATOR_DATA);
   SetIndexBuffer(3,buffer4,INDICATOR_DATA);
   SetIndexBuffer(4,buffer5,INDICATOR_DATA);
   SetIndexBuffer(5,buffer6,INDICATOR_DATA);
   SetIndexBuffer(6,buffer7,INDICATOR_DATA);

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
   if(limit>0)limit--;

   int bar=Bars(_Symbol,Period_TF);
   if(bars_tf==0 || bar>bars_tf)array_copy(bar);

   f1(0.5,limit,rates_total,time,buffer7,buffer7);
   f1(K_Fibo_1,limit,rates_total,time,buffer1,buffer2);
   f1(K_Fibo_2,limit,rates_total,time,buffer3,buffer4);
   f1(K_Fibo_3,limit,rates_total,time,buffer5,buffer6);

   return(rates_total);
  }
//+------------------------------------------------------------------+
void f1(double k_fibo,int q,int r,const datetime &time_[],double &b1[],double &b2[])
  {
   for(int w=q;w<r && !_StopFlag;w++)
     {
      int b=f2(time_[w]);//find the time of the current bar in the array of the higher
      double h=high_tf[b];//get the high
      double l=low_tf[b];//get the low
      double hl=h-l;//find the movement range
      b1[w]=h-hl*k_fibo;//add the calculated value to the support buffer
      b2[w]=l+hl*k_fibo;//add the calculated value to the resistance buffer
     }
  }
//+------------------------------------------------------------------+
int f2(datetime t_)
  {
   int b_=ArrayBsearch(time_tf,t_);//find a bar using a standard search in sorted arrays
   if(time_tf[b_]>t_)b_--;//if the time of the nearest bar of a higher timeframe is returned, we will reduce it by 1
   return(MathMax(0,b_-1));//do not forget to return a bars taking into account the minimum limit
  }
//+------------------------------------------------------------------+
void array_copy(int b_)
  {
   ArrayResize(time_tf,b_);//changing the buffer size for our data
   ArrayResize(high_tf,b_);
   ArrayResize(low_tf,b_);

   int total=b_-bars_tf;//calculate the required data copying

   CopyTime(_Symbol,Period_TF,0,total,time_tf);//copy missing data to the array
   CopyHigh(_Symbol,Period_TF,0,total,high_tf);
   CopyLow(_Symbol,Period_TF,0,total,low_tf);

   bars_tf=b_;//remember the array size and the amount of data
  }
//+------------------------------------------------------------------+
