//+------------------------------------------------------------------+
//|                                Awesome Oscillator Divergence.mq5 |
//|                                  Copyright © 2013, Mehrdad Shiri |
//|                                      E-mail: m100shiri@yahoo.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2013, Mehrdad Shiri"
//---- link to the website of the author
#property link "m100shiri@yahoo.com"
//---- indicator version number
#property version   "1.00"
#property description "Awesome Oscillator Divergence"

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   5
//------------------------------------------------------------------------------------------ Awesome_Oscillator
#property indicator_label1  "AO"
#property indicator_type1   DRAW_COLOR_HISTOGRAM  // DRAW_COLOR_LINE   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDarkGreen,clrDarkRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//
double Ext_AO_Buffer[];
double ExtColor_AO_Buffer[];
int   AO_handle;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#property indicator_label2  "AO_BUY_Divergence_Regular"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label3  "AO_SELL_Divergence_Regular"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//
double   AO_BUY_Divergence_Regular_Buffer[],AO_SELL_Divergence_Regular_Buffer[];
uchar    AO_BUY_Divergence_Regular_Code=233;
uchar    AO_SELL_Divergence_Regular_Code=234;
//
int    AO_BUY_Divergence_Regular_Shift=10;
int    AO_SELL_Divergence_Regular_Shift=10;
//+++++++
#property indicator_label4  "AO_BUY_Divergence_Hidden"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrAqua
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label5  "AO_SELL_Divergence_Hidden"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrOrange
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//
double   AO_BUY_Divergence_Hidden_Buffer[],AO_SELL_Divergence_Hidden_Buffer[];
uchar    AO_BUY_Divergence_Hidden_Code=241;
uchar    AO_SELL_Divergence_Hidden_Code=242;
//
int    AO_BUY_Divergence_Hidden_Shift=-10;
int    AO_SELL_Divergence_Hidden_Shift=-10;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//--- bars minimum for calculation
#define DATA_LIMIT 37

double   Zero_Value=0.0;
string short_name;
int TOTAL_BAR;
int count_bar_above=0;
int count_bar_down=0;
int LastTrough_bar=0;
int LastPeak_bar=0;
int ALL_LastPeak_bar[200];
int ALL_LastTrough_bar[200];
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input double Deviation_percent=0.05;
//+-----------------------------------+
enum WHEN_DRAW_LINE
  {
   yes,
   no
  };
input WHEN_DRAW_LINE Indicator_Trend_Line_Allowed_across_through_the_histogram_body=no;
//+-----------------------------------+
input uint Numberof_Alerts_Maximum_Iterations=2;
uint counterBUY=0;
uint counterSELL=0;
double Ask,Bid;
string text,sAsk,sBid,sPeriod;
datetime SignalTime;
datetime LastSignalTime;
double SIGNAL_ALARM_BUY_Divergence_Regular_Buffer[];
double SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer[];
double SIGNAL_ALARM_SELL_Divergence_Regular_Buffer[];
double SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer[];
//+-----------------------------------+
//----
input bool On_Push = true;                        //allow to send push-messages
input bool On_Email = true;                       //allow to send e-mail messages
input bool On_Alert= true;                        //allow to put alert
input bool On_Play_Sound = true;                  //allow to put sound signal
input string NameFileSound="alert.wav";          //name of the file with sound
input string  CommentSirName="Divergence on Awesome Oscillator: ";  //the first part of the allert comment
//+-----------------------------------+
bool foreground;
//+------------------------------------------------------------------+
void OnInit()
  {
//------------------------------------------------------------------------------------------ Awesome_Oscillator
   SetIndexBuffer(0,Ext_AO_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColor_AO_Buffer,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,DATA_LIMIT);
   AO_handle=iAO(NULL,0);
   ArraySetAsSeries(Ext_AO_Buffer,true);
   ArraySetAsSeries(ExtColor_AO_Buffer,true);
//+++++++
   SetIndexBuffer(2,AO_BUY_Divergence_Regular_Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,AO_SELL_Divergence_Regular_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(AO_BUY_Divergence_Regular_Buffer,true);
   ArraySetAsSeries(AO_SELL_Divergence_Regular_Buffer,true);
   PlotIndexSetInteger(1,PLOT_ARROW,AO_BUY_Divergence_Regular_Code);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,Zero_Value);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,AO_BUY_Divergence_Regular_Shift);
   PlotIndexSetInteger(2,PLOT_ARROW,AO_SELL_Divergence_Regular_Code);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,Zero_Value);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-AO_SELL_Divergence_Regular_Shift);
//+++
   SetIndexBuffer(4,AO_BUY_Divergence_Hidden_Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,AO_SELL_Divergence_Hidden_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(AO_BUY_Divergence_Hidden_Buffer,true);
   ArraySetAsSeries(AO_SELL_Divergence_Hidden_Buffer,true);
   PlotIndexSetInteger(3,PLOT_ARROW,AO_BUY_Divergence_Hidden_Code);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,Zero_Value);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,AO_BUY_Divergence_Hidden_Shift);
   PlotIndexSetInteger(4,PLOT_ARROW,AO_SELL_Divergence_Hidden_Code);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,Zero_Value);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-AO_SELL_Divergence_Hidden_Shift);
//+-----------------------------------+
   SetIndexBuffer(6,SIGNAL_ALARM_BUY_Divergence_Regular_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(SIGNAL_ALARM_BUY_Divergence_Regular_Buffer,true);
   SetIndexBuffer(7,SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer,true);
   SetIndexBuffer(8,SIGNAL_ALARM_SELL_Divergence_Regular_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(SIGNAL_ALARM_SELL_Divergence_Regular_Buffer,true);
   SetIndexBuffer(9,SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer,INDICATOR_DATA);
   ArraySetAsSeries(SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer,true);

   foreground=ChartGetInteger(0,CHART_FOREGROUND);
   ChartSetInteger(0,CHART_FOREGROUND,false);

   short_name="AO_Divergence";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- initialization done
  }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double   &Open[],
                const double   &High[],
                const double   &Low[],
                const double   &Close[],
                const long     &TickVolume[],
                const long     &Volume[],
                const int      &Spread[])
  {

   ArraySetAsSeries(Time,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   TOTAL_BAR=rates_total;
//------------------------------------------------------------------------------------------ Awesome_Oscillator
   int copy_AO=CopyBuffer(AO_handle,0,0,rates_total,Ext_AO_Buffer);
   int copy_AO_Color=CopyBuffer(AO_handle,1,0,rates_total,ExtColor_AO_Buffer);
//----------------------------------- 

   for(int j=ObjectsTotal(0)-1;j>=0;j--)
     {
      if(StringFind(ObjectName(0,j),"AO_Indicator_Divergence")!=-1 || 
         StringFind(ObjectName(0,j),"AO_Price_Divergence")!=-1)
         if(!ObjectDelete(0,ObjectName(0,j)))
            Print("Error in deleting object (",GetLastError(),")");
     }

   for(int ad=0; ad<rates_total; ad++)
     {
      AO_BUY_Divergence_Regular_Buffer[ad]=Zero_Value;
      AO_SELL_Divergence_Regular_Buffer[ad]=Zero_Value;
      AO_BUY_Divergence_Hidden_Buffer[ad]=Zero_Value;
      AO_SELL_Divergence_Hidden_Buffer[ad]=Zero_Value;
     }
//----------------------------------------------------------------------//
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(),tm);
   text=TimeToString(TimeCurrent(),TIME_DATE)+" "+string(tm.hour)+":"+string(tm.min);
   Ask=Close[0];
   Bid=Close[0]+Spread[0];
   sAsk=DoubleToString(Ask,_Digits);
   sBid=DoubleToString(Bid,_Digits);
   sPeriod=EnumToString(ChartPeriod());
   if(rates_total!=prev_calculated) {counterBUY=0;counterSELL=0;}

   for(int bar=rates_total-10; bar>0; bar--)
     {

      //----
      int draw_TrendLine=1;

      //---- 
      Indicator_count_bar_above(bar);
      if(Indicator_count_bar_above(bar)!=0)
        {
         IsIndicatorPeak(count_bar_above,bar);
         GetIndicatorLastPeak(count_bar_above,bar);
         LastPeak_bar=GetIndicatorLastPeak(count_bar_above,bar);
         GetIndicatorALL_LastPeak_bar(count_bar_above,bar);
        }
      if(IsIndicatorPeak(count_bar_above,bar)==true && GetIndicatorLastPeak(count_bar_above,bar)>=3)
        {
         for(int l=1;l<200;l++)
           {
            if(l>=2 && ALL_LastPeak_bar[l]==0 && ALL_LastPeak_bar[l-1]>=0) break;
            if(High[bar]>=High[ALL_LastPeak_bar[l]] && 
               Ext_AO_Buffer[bar]<Ext_AO_Buffer[ALL_LastPeak_bar[l]])
              {
               //+++  Indicator lines must going across through the indicators/histogram body ?    yes/no
               if(Indicator_Trend_Line_Allowed_across_through_the_histogram_body==no)
                 {
                  int BAR_body_check=Bars(Symbol(),Period(),Time[ALL_LastPeak_bar[l]],Time[bar])-1;
                  double SLOPE=(Ext_AO_Buffer[bar]-Ext_AO_Buffer[ALL_LastPeak_bar[l]])/(BAR_body_check);
                  for(int d=1; d<=BAR_body_check; d++)
                    {
                     double VALUE_body_line=Ext_AO_Buffer[ALL_LastPeak_bar[l]]+SLOPE*d;
                     if(Time[ALL_LastPeak_bar[l]-d]>=Time[bar]) break;
                     if(Ext_AO_Buffer[ALL_LastPeak_bar[l]-d]>(VALUE_body_line*(1.0+Deviation_percent)))
                       {
                        draw_TrendLine=0;
                        break;
                       }
                    }
                 }
               if(draw_TrendLine==1)
                 {
                  DrawIndicatorTrendLine(bar,Time[bar],Time[ALL_LastPeak_bar[l]],
                                         Ext_AO_Buffer[bar],Ext_AO_Buffer[ALL_LastPeak_bar[l]],Red,STYLE_SOLID);
                  DrawPriceTrendLine(bar,Time[bar],Time[ALL_LastPeak_bar[l]],
                                     High[bar],High[ALL_LastPeak_bar[l]],Red,STYLE_SOLID);
                  AO_SELL_Divergence_Regular_Buffer[bar]=Ext_AO_Buffer[bar];

                 }
              }
            //--- 
            if(Low[bar]<=Low[ALL_LastPeak_bar[l]] && 
               Ext_AO_Buffer[bar]>Ext_AO_Buffer[ALL_LastPeak_bar[l]])
              {
               //+++  Indicator lines must going across through the indicators/histogram body ?    yes/no
               if(Indicator_Trend_Line_Allowed_across_through_the_histogram_body==no)
                 {
                  int BAR_body_check=Bars(Symbol(),Period(),Time[ALL_LastPeak_bar[l]],Time[bar])-1;
                  double SLOPE=(Ext_AO_Buffer[bar]-Ext_AO_Buffer[ALL_LastPeak_bar[l]])/(BAR_body_check);
                  for(int d=1; d<=BAR_body_check; d++)
                    {
                     double VALUE_body_line=Ext_AO_Buffer[ALL_LastPeak_bar[l]]+SLOPE*d;
                     if(Time[ALL_LastPeak_bar[l]-d]>=Time[bar]) break;
                     if(Ext_AO_Buffer[ALL_LastPeak_bar[l]-d]>(VALUE_body_line*(1.0+Deviation_percent)))
                       {
                        draw_TrendLine=0;
                        break;
                       }
                    }
                 }
               if(draw_TrendLine==1)
                 {
                  DrawIndicatorTrendLine(bar,Time[bar],Time[ALL_LastPeak_bar[l]],
                                         Ext_AO_Buffer[bar],Ext_AO_Buffer[ALL_LastPeak_bar[l]],Aqua,STYLE_DOT);
                  DrawPriceTrendLine(bar,Time[bar],Time[ALL_LastPeak_bar[l]],
                                     Low[bar],Low[ALL_LastPeak_bar[l]],Aqua,STYLE_DOT);

                  AO_BUY_Divergence_Hidden_Buffer[bar]=Ext_AO_Buffer[bar];

                 }
              }
           }
        }
      //-----------------------------------
      Indicator_count_bar_down(bar);
      if(Indicator_count_bar_down(bar)!=0)
        {
         IsIndicatorTrough(count_bar_down,bar);
         GetIndicatorLastTrough(count_bar_down,bar);
         LastTrough_bar=GetIndicatorLastTrough(count_bar_down,bar);
         GetIndicatorALL_LastTrough_bar(count_bar_down,bar);
        }
      if(IsIndicatorTrough(count_bar_down,bar)==true && GetIndicatorLastTrough(count_bar_down,bar)>=3)
        {
         for(int l=1;l<200;l++)
           {
            if(l>=2 && ALL_LastTrough_bar[l]==0 && ALL_LastTrough_bar[l-1]>=0) break;

            if(Low[bar]<=Low[ALL_LastTrough_bar[l]] && 
               Ext_AO_Buffer[bar]>Ext_AO_Buffer[ALL_LastTrough_bar[l]])
              {
               //+++  Indicator lines must going across through the indicators/histogram body ?    yes/no
               if(Indicator_Trend_Line_Allowed_across_through_the_histogram_body==no)
                 {
                  int BAR_body_check=Bars(Symbol(),Period(),Time[ALL_LastTrough_bar[l]],Time[bar])-1;
                  double SLOPE=(Ext_AO_Buffer[bar]-Ext_AO_Buffer[ALL_LastTrough_bar[l]])/(BAR_body_check);
                  for(int d=1; d<=BAR_body_check; d++)
                    {
                     double VALUE_body_line=Ext_AO_Buffer[ALL_LastTrough_bar[l]]+SLOPE*d;
                     if(Time[ALL_LastTrough_bar[l]-d]>=Time[bar]) break;
                     if(Ext_AO_Buffer[ALL_LastTrough_bar[l]-d]<(VALUE_body_line*(1.0+Deviation_percent)))
                       {
                        draw_TrendLine=0;
                        break;
                       }
                    }
                 }
               if(draw_TrendLine==1)
                 {
                  DrawIndicatorTrendLine(bar,Time[bar],Time[ALL_LastTrough_bar[l]],
                                         Ext_AO_Buffer[bar],Ext_AO_Buffer[ALL_LastTrough_bar[l]],Blue,STYLE_SOLID);
                  DrawPriceTrendLine(bar,Time[bar],Time[ALL_LastTrough_bar[l]],
                                     Low[bar],Low[ALL_LastTrough_bar[l]],Blue,STYLE_SOLID);

                  AO_BUY_Divergence_Regular_Buffer[bar]=Ext_AO_Buffer[bar];

                 }
              }
            //---  
            if(Low[bar]>=Low[ALL_LastTrough_bar[l]] && 
               Ext_AO_Buffer[bar]<Ext_AO_Buffer[ALL_LastTrough_bar[l]])
              {
               //+++  Indicator lines must going across through the indicators/histogram body ?    yes/no
               if(Indicator_Trend_Line_Allowed_across_through_the_histogram_body==no)
                 {
                  int BAR_body_check=Bars(Symbol(),Period(),Time[ALL_LastTrough_bar[l]],Time[bar])-1;
                  double SLOPE=(Ext_AO_Buffer[bar]-Ext_AO_Buffer[ALL_LastTrough_bar[l]])/(BAR_body_check);
                  for(int d=1; d<=BAR_body_check; d++)
                    {
                     double VALUE_body_line=Ext_AO_Buffer[ALL_LastTrough_bar[l]]+SLOPE*d;
                     if(Time[ALL_LastTrough_bar[l]-d]>=Time[bar]) break;
                     if(Ext_AO_Buffer[ALL_LastTrough_bar[l]-d]<(VALUE_body_line*(1.0+Deviation_percent)))
                       {
                        draw_TrendLine=0;
                        break;
                       }
                    }
                 }
               if(draw_TrendLine==1)
                 {
                  DrawIndicatorTrendLine(bar,Time[bar],Time[ALL_LastTrough_bar[l]],
                                         Ext_AO_Buffer[bar],Ext_AO_Buffer[ALL_LastTrough_bar[l]],Orange,STYLE_DOT);
                  DrawPriceTrendLine(bar,Time[bar],Time[ALL_LastTrough_bar[l]],
                                     Low[bar],Low[ALL_LastTrough_bar[l]],Orange,STYLE_DOT);

                  AO_SELL_Divergence_Hidden_Buffer[bar]=Ext_AO_Buffer[bar];

                 }
              }
           }
        }
     }
//----------------------------------------------------------------------------------------------------------//

   for(int i=0; i<rates_total; i++)
     {
      if(AO_BUY_Divergence_Regular_Buffer[i]!=Zero_Value) SIGNAL_ALARM_BUY_Divergence_Regular_Buffer[i]=1;
      else SIGNAL_ALARM_BUY_Divergence_Regular_Buffer[i]=0;
      if(AO_BUY_Divergence_Hidden_Buffer[i]!=Zero_Value) SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer[i]=1;
      else SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer[i]=0;
      if(AO_SELL_Divergence_Regular_Buffer[i]!=Zero_Value) SIGNAL_ALARM_SELL_Divergence_Regular_Buffer[i]=1;
      else SIGNAL_ALARM_SELL_Divergence_Regular_Buffer[i]=0;
      if(AO_SELL_Divergence_Hidden_Buffer[i]!=Zero_Value) SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer[i]=1;
      else SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer[i]=0;
     }

   if(counterBUY<Numberof_Alerts_Maximum_Iterations)
     {
      if(SIGNAL_ALARM_BUY_Divergence_Regular_Buffer[1]==1 || SIGNAL_ALARM_BUY_Divergence_Hidden_Buffer[1]==1)
        {BUY_ALARM();counterBUY++;}
     }

   if(counterSELL<Numberof_Alerts_Maximum_Iterations)
     {
      if(SIGNAL_ALARM_SELL_Divergence_Regular_Buffer[1]==1 || SIGNAL_ALARM_SELL_Divergence_Hidden_Buffer[1]==1)
        {SELL_ALARM();counterSELL++;}
     }

//----------------------------------------------------------------------------------------------------------// 

   Comment(""

           );

//--- done
   return(rates_total);
  }
//----------------------------------------------------------------------------------------------------------//
void OnDeinit(const int reason)
  {
   Comment("");

   for(int j=ObjectsTotal(0)-1;j>=0;j--)
     {
      if(StringFind(ObjectName(0,j),"AO_Indicator_Divergence")!=-1 || 
         StringFind(ObjectName(0,j),"AO_Price_Divergence")!=-1)
         if(!ObjectDelete(0,ObjectName(0,j)))
            Print("Error in deleting object (",GetLastError(),")");
     }
   ChartRedraw();
   ChartSetInteger(0,CHART_FOREGROUND,foreground);
  }
//----------------------------------------------------------------------------------------------------------//
//+------------------------------------------------------------------+
//| Check domain_above Awesome_Oscillator bar                        |
//+------------------------------------------------------------------+
int Indicator_count_bar_above(int bar)
  {
   count_bar_above=0;
   for(int j=bar; j<TOTAL_BAR-10; j++)
     {
      if(Ext_AO_Buffer[j]>=0.0)
        {
         if(Ext_AO_Buffer[j]>=0.0 && Ext_AO_Buffer[j+1]<=0.0)
           {
            count_bar_above=j+1;
            break;
           }
        }
      else break;
     }
   return(count_bar_above);
  }
//----------------------------------------------------------------------------------------------------------//   
//+------------------------------------------------------------------+
//| Check domain_down Awesome_Oscillator bar                         |
//+------------------------------------------------------------------+
int Indicator_count_bar_down(int bar)
  {
   count_bar_down=0;
   for(int j=bar; j<TOTAL_BAR-10; j++)
     {
      if(Ext_AO_Buffer[j]<=0.0)
        {
         if(Ext_AO_Buffer[j]<=0.0 && Ext_AO_Buffer[j+1]>=0.0)
           {
            count_bar_down=j+1;
            break;
           }
        }
      else break;
     }
   return(count_bar_down);
  }
//----------------------------------------------------------------------------------------------------------//   
//+------------------------------------------------------------------+
//| Get Awesome_Oscillator last Peak                                 |
//+------------------------------------------------------------------+
int GetIndicatorLastPeak(int count_bar,int bar)
  {
   int LastPeak=0;
   if(count_bar<6) return(LastPeak);
   for(int j=bar+3; j<=count_bar-2; j++)
     {
      if(Ext_AO_Buffer[j]>=Ext_AO_Buffer[j+1]&& Ext_AO_Buffer[j]>Ext_AO_Buffer[j+2]&&
         Ext_AO_Buffer[j]>=Ext_AO_Buffer[j-1]&& Ext_AO_Buffer[j]>Ext_AO_Buffer[j-2])
        {
         LastPeak=j;
         break;
        }
     }
   return(LastPeak);
  }
//----------------------------------------------------------------------------------------------------------//   
int GetIndicatorALL_LastPeak_bar(int count_bar,int bar)
  {
   for(int i=0;i<200; i++) ALL_LastPeak_bar[i]=0;
   ALL_LastPeak_bar[0]=bar;
   int ii=1;
   for(int j=bar+3; j<=count_bar-2; j++)
     {
      ALL_LastPeak_bar[ii]=GetIndicatorLastPeak(count_bar,ALL_LastPeak_bar[ii-1]);
      if(ii>1 && ALL_LastPeak_bar[ii]==0 && ALL_LastPeak_bar[ii-1]>=0) break;
      ii++;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Get Awesome_Oscillator last Trough                               |
//+------------------------------------------------------------------+
int GetIndicatorLastTrough(int count_bar,int bar)
  {
   int LastTrough=0;
   if(count_bar<6) return(LastTrough);
   for(int j=bar+3; j<=count_bar-2; j++)
     {
      if(Ext_AO_Buffer[j]<=Ext_AO_Buffer[j+1]&& Ext_AO_Buffer[j]<Ext_AO_Buffer[j+2]&&
         Ext_AO_Buffer[j]<=Ext_AO_Buffer[j-1]&& Ext_AO_Buffer[j]<Ext_AO_Buffer[j-2])
        {
         LastTrough=j;
         break;
        }
     }
   return(LastTrough);
  }
//----------------------------------------------------------------------------------------------------------//
int GetIndicatorALL_LastTrough_bar(int count_bar,int bar)
  {
   for(int i=0;i<200; i++) ALL_LastTrough_bar[i]=0;
   ALL_LastTrough_bar[0]=bar;
   int ii=1;
   for(int j=bar+3; j<=count_bar-2; j++)
     {
      ALL_LastTrough_bar[ii]=GetIndicatorLastTrough(count_bar,ALL_LastTrough_bar[ii-1]);
      if(ii>1 && ALL_LastTrough_bar[ii]==0 && ALL_LastTrough_bar[ii-1]>=0) break;
      ii++;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Is Awesome_Oscillator Peak                                       |
//+------------------------------------------------------------------+
bool IsIndicatorPeak(int Peak,int bar)
  {
   if(Peak<4) return(false);
   if(Ext_AO_Buffer[bar]>=Ext_AO_Buffer[bar+1] && Ext_AO_Buffer[bar]>Ext_AO_Buffer[bar+2] && 
      Ext_AO_Buffer[bar]>Ext_AO_Buffer[bar-1]) return(true);
   return(false);
  }
//----------------------------------------------------------------------------------------------------------// 
//+------------------------------------------------------------------+
//| Is Awesome_Oscillator Trough                                     |
//+------------------------------------------------------------------+
bool IsIndicatorTrough(int Trough,int bar)
  {
   if(Trough<4) return(false);
   if(Ext_AO_Buffer[bar]<=Ext_AO_Buffer[bar+1] && Ext_AO_Buffer[bar]<Ext_AO_Buffer[bar+2] && 
      Ext_AO_Buffer[bar]<Ext_AO_Buffer[bar-1]) return(true);
   return(false);
  }
//----------------------------------------------------------------------------------------------------------//
//+------------------------------------------------------------------+
//| Function for drawing a trend line in the indicator window        |
//+------------------------------------------------------------------+
void DrawIndicatorTrendLine(int bar,datetime x1,datetime x2,double y1,double y2,color lineColor,int style)
  {
   int indicatorWindow=ChartWindowFind(0,short_name);
   if(indicatorWindow<0) return;
   string label="AO_Indicator_Divergence"+IntegerToString(bar)+TimeToString(x2);
   if(ObjectFind(0,label)==-1)
     {
      ObjectCreate(0,label,OBJ_TREND,indicatorWindow,x1,y1,x2,y2);
      ObjectSetInteger(0,label,OBJPROP_COLOR,lineColor);
      ObjectSetInteger(0,label,OBJPROP_STYLE,style);
      ObjectSetInteger(0,label,OBJPROP_WIDTH,0);
      ObjectSetInteger(0,label,OBJPROP_RAY,0);
      ObjectSetInteger(0,label,OBJPROP_BACK,false);
     }
   else
     {
      ObjectMove(0,label,0,x1,y1);
      ObjectMove(0,label,1,x2,y2);
     }
  }
//----------------------------------------------------------------------------------------------------------//
//+------------------------------------------------------------------+
//| Function for drawing a trend line in a price chart window        |
//+------------------------------------------------------------------+
void DrawPriceTrendLine(int bar,datetime x1,datetime x2,double y1,double y2,color lineColor,int style)
  {
   string label="AO_Price_Divergence"+IntegerToString(bar)+TimeToString(x2);
   if(ObjectFind(0,label)==-1)
     {
      ObjectCreate(0,label,OBJ_TREND,0,x1,y1,x2,y2);
      ObjectSetInteger(0,label,OBJPROP_COLOR,lineColor);
      ObjectSetInteger(0,label,OBJPROP_STYLE,style);
      ObjectSetInteger(0,label,OBJPROP_WIDTH,0);
      ObjectSetInteger(0,label,OBJPROP_RAY,0);
      ObjectSetInteger(0,label,OBJPROP_BACK,false);
     }
   else
     {
      ObjectMove(0,label,0,x1,y1);
      ObjectMove(0,label,1,x2,y2);
     }
  }
//----------------------------------------------------------------------------------------------------------//
//********************************************************************************************************************
void BUY_ALARM()
  {
   if(On_Play_Sound) PlaySound(NameFileSound);
   if(On_Alert) Alert("BUY # ",Symbol(),"\n Period=",sPeriod,"\n Ask=",sAsk,"\n Bid=",sBid,"\n currtime=",text);
   if(On_Email) SendMail("BUY #",Symbol()+" Period="+sPeriod+", Ask="+sAsk+", Bid="+sBid+", currtime="+text);
   if(On_Push) SendNotification("BUY #"+Symbol()+" Period="+sPeriod+", Ask="+sAsk+", Bid="+sBid+", currtime="+text);
  }
//+------------------------------------------------------------------+
void SELL_ALARM()
  {
   if(On_Play_Sound) PlaySound(NameFileSound);
   if(On_Alert) Alert("SELL # ",Symbol(),"\n Period=",sPeriod,"\n Ask=",sAsk,"\n Bid=",sBid,"\n currtime=",text);
   if(On_Email) SendMail("SELL #",Symbol()+" Period="+sPeriod+", Ask="+sAsk+", Bid="+sBid+", currtime="+text);
   if(On_Push) SendNotification("SELL #"+Symbol()+" Period="+sPeriod+", Ask="+sAsk+", Bid="+sBid+", currtime="+text);
  }
//********************************************************************************************************************
