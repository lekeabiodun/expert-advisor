//+------------------------------------------------------------------+
//|                                        Murrey_Math_FixPeriod.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
/* 8/8 th's and 0/8 th's Lines (Ultimate Resistance).
   These lines are the hardest to penetrate on the way up, and give the greatest support on the way down.
   --------------------------------------------------------------------------------------------
   7/8 th's Line (Weak, Stall and Reverse). Weak, Stall and Reverse
   This line is weak. If prices run up too far too fast, and if they stall at this line 
   they will reverse down fast. If prices do not stall at this line they will move up to the 8/8 th's line.
   --------------------------------------------------------------------------------------------
   1/8 th Line (Weak, Stall and Reverse). Weak, Stall and Reverse
   This line is weak. If prices run up too far too fast, and if they stall at this line 
   they will reverse up fast. If prices do not stall at this line they will move down to the 0/8 th's line.
   --------------------------------------------------------------------------------------------
   6/8 th's and 2/8 th's Lines (Pivot, Reverse). Pivot, Reverse
   These two lines are second only to the 4/8 th's line in their ability to force prices to reverse.
   --------------------------------------------------------------------------------------------
   5/8 th's Line (Top of Trading Range). Top of Trading Range
   The prices of all entities will spend 40% of the time moving between the 5/8 th's and 3/8 th's lines. 
   If prices move above the 5/8 th's line and stay above it for 10 to 12 days, the entity is said 
   to be selling at a premium to what one wants to pay for it and prices will tend to stay 
   above this line in the "premium area". If, however, prices fall below the 5/8 th's line then they will tend to 
   fall further looking for support at a lower level.
   --------------------------------------------------------------------------------------------
   3/8 th's Line (Bottom of Trading Range). Bottom of Trading Range
   If prices are below this line and moving upwards, this line is difficult to penetrate. 
   If prices penetrate above this line and stay above this line for 10 to 12 days 
   then prices will stay above this line and spend 40% of the time moving between this line and the 5/8 th's line.
   --------------------------------------------------------------------------------------------
   4/8 th's Line (Major Support/Resistance). Major Support/Resistance
   This line provides the greatest amount of support and resistance. This price level is the best level to sell and buy. 
   This line has the greatest support when prices are above it and the greatest resistance when prices are 
   below it.
   --------------------------------------------------------------------------------------------*/
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- thirteen buffers are used for calculation and drawing the indicator
#property indicator_buffers 13
//---- 13 plots are used in total
#property indicator_plots   13
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define  width_line            2 // The constant for the indicator line width
//+-----------------------------------+
//|  Indicators drawing parameters    |
//+-----------------------------------+
//--- plot buffer 1
#property indicator_label1  "Pivot, reverse [-2/8]" //"extremely overshoot [-2/8]"
#property indicator_type1   DRAW_LINE
#property indicator_color1  DarkBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  width_line
//--- plot buffer 2
#property indicator_label2  "Weak, stall and reverse [-1/8]" // "overshoot [-1/8]"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DarkViolet
#property indicator_style2  STYLE_SOLID
#property indicator_width2  width_line
//--- plot buffer 3
#property indicator_label3  "Ultimate resistance [0/8]" // "Ultimate Support - extremely oversold [0/8]"
#property indicator_type3   DRAW_LINE
#property indicator_color3  Aqua
#property indicator_style3  STYLE_SOLID
#property indicator_width3  width_line
//--- plot buffer 4
#property indicator_label4  "Weak, stall and reverse [1/8]"
#property indicator_type4   DRAW_LINE
#property indicator_color4  Peru
#property indicator_style4  STYLE_SOLID
#property indicator_width4  width_line
//--- plot buffer 5
#property indicator_label5  "Вращение, разворот [2/8]"
#property indicator_type5   DRAW_LINE
#property indicator_color5  Red
#property indicator_style5  STYLE_SOLID
#property indicator_width5  width_line
//--- plot buffer 6
#property indicator_label6  "Bottom of Trading Range [3/8]" // if 10-12 bars then 40% Time. BUY Premium Zone"
#property indicator_type6   DRAW_LINE
#property indicator_color6  Lime
#property indicator_style6  STYLE_SOLID
#property indicator_width6  width_line
//--- plot buffer 7
#property indicator_label7  "Major Support/Resistance Pivotal Point [4/8]" // "Best New BUY or SELL level"
#property indicator_type7   DRAW_LINE
#property indicator_color7  DarkGray
#property indicator_style7  STYLE_SOLID
#property indicator_width7  width_line
//--- plot buffer 8
#property indicator_label8  "Top of Trading Range [5/8]" // If 10-12 bars then 40% Time. SELL Premium Zone"
#property indicator_type8   DRAW_LINE
#property indicator_color8  Lime
#property indicator_style8  STYLE_SOLID
#property indicator_width8  width_line
//--- plot buffer 9
#property indicator_label9  "Pivot, Reverse [6/8]"
#property indicator_type9   DRAW_LINE
#property indicator_color9  Red
#property indicator_style9  STYLE_SOLID
#property indicator_width9  width_line
//--- plot buffer 10
#property indicator_label10 "Weak, Stall and Reverse - [7/8]"
#property indicator_type10   DRAW_LINE
#property indicator_color10  Peru
#property indicator_style10  STYLE_SOLID
#property indicator_width10  width_line
//--- plot buffer 11
#property indicator_label11  "Ultimate Resistance [8/8]" // "Ultimate Resistance - extremely overbought [8/8]"
#property indicator_type11   DRAW_LINE
#property indicator_color11  Aqua
#property indicator_style11  STYLE_SOLID
#property indicator_width11  width_line
//--- plot buffer 12
#property indicator_label12  "Weak, stall and reverse [+1/8]" // "overshoot [+1/8]"
#property indicator_type12   DRAW_LINE
#property indicator_color12  DarkViolet
#property indicator_style12  STYLE_SOLID
#property indicator_width12  width_line
//--- plot buffer 13
#property indicator_label13  "Pivot, reverse [+2/8]" // "extremely overshoot [+2/8]"
#property indicator_type13   DRAW_LINE
#property indicator_color13  DarkBlue
#property indicator_style13  STYLE_SOLID
#property indicator_width13  width_line
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input ENUM_TIMEFRAMES Timeframe=PERIOD_D1; // Indicator timeframe for lines calculation
input int CalculationPeriod=64;            // P calculation period
input int StepBack=0;
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];
double Buffer5[];
double Buffer6[];
double Buffer7[];
double Buffer8[];
double Buffer9[];
double Buffer10[];
double Buffer11[];
double Buffer12[];
double Buffer13[];
//---- declaration of a variable for storing the indicator initialization result
bool Init;
//---- declaration of the integer variables for the shift of data calculation
int ShiftBarsForward;
//---- declaration of integer variables for the indicators handles
int Murrey_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,Murrey_Calculated;
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+  
bool BufferRecount(uint Number,double &Buffer[],datetime Time,uint bar)
  {
//----
   double Murrey[2];
   if(CopyBuffer(Murrey_Handle,Number,Time,2,Murrey)<=0) return(RESET);
   if(Murrey[1]!=EMPTY_VALUE) Buffer[bar]=Murrey[1];
   else Buffer[bar]=Murrey[0];
//----
   return(true);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   Murrey_Calculated=CalculationPeriod+StepBack+3;
   min_rates_total=Murrey_Calculated*PeriodSeconds(Timeframe)/PeriodSeconds(PERIOD_CURRENT);

   Init=true;
//---- checking correctness of the chart periods
   if(Timeframe<Period() && Timeframe!=PERIOD_CURRENT)
     {
      Print("Murrey_Math indicator chart period cannot be less than the current chart period");
      Init=false;
      return;
     }

//---- getting handle of the Murrey_Math indicator
   Murrey_Handle=iCustom(NULL,Timeframe,"Murrey_Math",CalculationPeriod,StepBack);
   if(Murrey_Handle==INVALID_HANDLE) Print(" Failed to get handle of the Murrey_Math indicator");

//---- indicator buffers mapping
   SetIndexBuffer(0,Buffer1,INDICATOR_DATA);
   SetIndexBuffer(1,Buffer2,INDICATOR_DATA);
   SetIndexBuffer(2,Buffer3,INDICATOR_DATA);
   SetIndexBuffer(3,Buffer4,INDICATOR_DATA);
   SetIndexBuffer(4,Buffer5,INDICATOR_DATA);
   SetIndexBuffer(5,Buffer6,INDICATOR_DATA);
   SetIndexBuffer(6,Buffer7,INDICATOR_DATA);
   SetIndexBuffer(7,Buffer8,INDICATOR_DATA);
   SetIndexBuffer(8,Buffer9,INDICATOR_DATA);
   SetIndexBuffer(9,Buffer10,INDICATOR_DATA);
   SetIndexBuffer(10,Buffer11,INDICATOR_DATA);
   SetIndexBuffer(11,Buffer12,INDICATOR_DATA);
   SetIndexBuffer(12,Buffer13,INDICATOR_DATA);

//---- indexing the elements in buffers as timeseries
   ArraySetAsSeries(Buffer1,true);
   ArraySetAsSeries(Buffer2,true);
   ArraySetAsSeries(Buffer3,true);
   ArraySetAsSeries(Buffer4,true);
   ArraySetAsSeries(Buffer5,true);
   ArraySetAsSeries(Buffer6,true);
   ArraySetAsSeries(Buffer7,true);
   ArraySetAsSeries(Buffer8,true);
   ArraySetAsSeries(Buffer9,true);
   ArraySetAsSeries(Buffer10,true);
   ArraySetAsSeries(Buffer11,true);
   ArraySetAsSeries(Buffer12,true);
   ArraySetAsSeries(Buffer13,true);
//----   
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"Murrey_Math_MT5("
                      +EnumToString(Timeframe)+", "+string(CalculationPeriod)+", "+string(StepBack)+")");
//----  
   for(int i=0; i<13; i++)
     {
      PlotIndexSetInteger(i,PLOT_SHIFT,0);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,EMPTY_VALUE);
     }
//----
   return;
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(Murrey_Handle)<Murrey_Calculated || rates_total<min_rates_total || !Init) return(RESET);
   if(prev_calculated==rates_total) return(rates_total);

//---- declarations of local variables 
   int limit,bar1;
   datetime Time;

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-1;
      for(int bar=limit; bar<=limit-min_rates_total; bar--)
        {
         Buffer1[bar]=EMPTY_VALUE;
         Buffer2[bar]=EMPTY_VALUE;
         Buffer3[bar]=EMPTY_VALUE;
         Buffer4[bar]=EMPTY_VALUE;
         Buffer5[bar]=EMPTY_VALUE;
         Buffer6[bar]=EMPTY_VALUE;
         Buffer7[bar]=EMPTY_VALUE;
         Buffer8[bar]=EMPTY_VALUE;
         Buffer9[bar]=EMPTY_VALUE;
         Buffer10[bar]=EMPTY_VALUE;
         Buffer11[bar]=EMPTY_VALUE;
         Buffer12[bar]=EMPTY_VALUE;
         Buffer13[bar]=EMPTY_VALUE;
        }

      limit-=min_rates_total;
     }
   else limit=rates_total-prev_calculated;

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);

//---- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Time=time[bar];

      if(!BufferRecount(0,Buffer1,Time,bar)) return(RESET);
      if(!BufferRecount(1,Buffer2,Time,bar)) return(RESET);
      if(!BufferRecount(2,Buffer3,Time,bar)) return(RESET);
      if(!BufferRecount(3,Buffer4,Time,bar)) return(RESET);
      if(!BufferRecount(4,Buffer5,Time,bar)) return(RESET);
      if(!BufferRecount(5,Buffer6,Time,bar)) return(RESET);
      if(!BufferRecount(6,Buffer7,Time,bar)) return(RESET);
      if(!BufferRecount(7,Buffer8,Time,bar)) return(RESET);
      if(!BufferRecount(8,Buffer9,Time,bar)) return(RESET);
      if(!BufferRecount(9,Buffer10,Time,bar)) return(RESET);
      if(!BufferRecount(10,Buffer11,Time,bar)) return(RESET);
      if(!BufferRecount(11,Buffer12,Time,bar)) return(RESET);
      if(!BufferRecount(12,Buffer13,Time,bar)) return(RESET);

      bar1=bar+1;

      if(Buffer1[bar]!=Buffer1[bar1]
         ||Buffer2[bar]!=Buffer2[bar1]
         ||Buffer3[bar]!=Buffer3[bar1]
         ||Buffer4[bar]!=Buffer4[bar1]
         ||Buffer5[bar]!=Buffer5[bar1]
         ||Buffer6[bar]!=Buffer6[bar1]
         ||Buffer7[bar]!=Buffer7[bar1]
         ||Buffer8[bar]!=Buffer8[bar1]
         ||Buffer9[bar]!=Buffer9[bar1]
         ||Buffer10[bar]!=Buffer10[bar1]
         ||Buffer11[bar]!=Buffer11[bar1]
         ||Buffer12[bar]!=Buffer12[bar1]
         ||Buffer13[bar]!=Buffer13[bar1])
        {
         Buffer1[bar1]=EMPTY_VALUE;
         Buffer2[bar1]=EMPTY_VALUE;
         Buffer3[bar1]=EMPTY_VALUE;
         Buffer4[bar1]=EMPTY_VALUE;
         Buffer5[bar1]=EMPTY_VALUE;
         Buffer6[bar1]=EMPTY_VALUE;
         Buffer7[bar1]=EMPTY_VALUE;
         Buffer8[bar1]=EMPTY_VALUE;
         Buffer9[bar1]=EMPTY_VALUE;
         Buffer10[bar1]=EMPTY_VALUE;
         Buffer11[bar1]=EMPTY_VALUE;
         Buffer12[bar1]=EMPTY_VALUE;
         Buffer13[bar1]=EMPTY_VALUE;
        }
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
