//+------------------------------------------------------------------+
//|                                              MinChangeSignal.mq5 |
//|                                            Copyright 2013, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The signal is formed if the changes sum calculated on the last bar "
#property description "is less, than the smallest of sums calculated on the specified number of previous bars."
//---
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot CurrentChange
#property indicator_label1  "Current Change Sum"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot MinChange
#property indicator_label2  "Min Change Sum"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Signal
#property indicator_label3  "Signal"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLime
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3
//--- input parameters
input int      InpChangesPeriod = 4;   // Changes Period
input int      InpCheckPeriod = 10;    // Check Period
input bool     InpAbsChange = false;   // Abs Change
//--- indicator buffers
double         CurrentSumBuffer[];
double         MinSumBuffer[];
double         SignalBuffer[];
//---
int            changes_period;
int            check_period;
int            min_required_bars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if ( InpChangesPeriod < 1 || InpCheckPeriod < 2 ) {
      changes_period = 3;
      check_period = 10;
      printf("Incorrect input value InpChangesPeriod = %d or/and InpCheckPeriod =%d. "
         "Indicator will use values %d and %d respectively.", InpChangesPeriod, InpCheckPeriod,
         changes_period, check_period);
   } else {
      changes_period = InpChangesPeriod;
      check_period = InpCheckPeriod;
   }
   min_required_bars = changes_period + check_period + 1;
//--- indicator buffers mapping
   SetIndexBuffer(0, CurrentSumBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, MinSumBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, SignalBuffer, INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(2, PLOT_ARROW, 159);
//---
   for ( int plot = 0; plot < 3; plot++ ) {
      PlotIndexSetInteger(plot, PLOT_DRAW_BEGIN, min_required_bars - 1);
      PlotIndexSetInteger(plot, PLOT_SHIFT, 0);
      PlotIndexSetDouble(plot, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString(INDICATOR_SHORTNAME, "Min Price Change ("+(string)changes_period
      +", "+(string)check_period+")");   
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
//---
   int change_start_bar, check_start_bar, signal_start_bar;
//---
   if ( rates_total < min_required_bars ) {
      Print("Not enough bars for calculations.");
      return(0);
   }
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      change_start_bar = changes_period;
      check_start_bar = change_start_bar + check_period;
      signal_start_bar = check_start_bar + 1;
   } else {
      change_start_bar = prev_calculated - 1;
      check_start_bar = change_start_bar;
      signal_start_bar = change_start_bar;
   }
//---
   for ( int bar = change_start_bar; bar < rates_total; bar++ ) {
      double sum = 0.0;
      
      for ( int shift = bar - changes_period + 1; shift <= bar; shift++ ) {
         if ( InpAbsChange ) {
            sum += MathAbs(price[shift] - price[shift-1]);
         } else {
            sum += price[shift] - price[shift-1];
         }
      }
      CurrentSumBuffer[bar] = MathAbs(sum);
   }
   for ( int bar = check_start_bar; bar < rates_total; bar++ ) {
      MinSumBuffer[bar] = CurrentSumBuffer[ArrayMinimum(CurrentSumBuffer,
         bar-check_period, check_period)];
   }
   for ( int bar = signal_start_bar; bar < rates_total; bar++ ) {
      SignalBuffer[bar] = EMPTY_VALUE;
      if ( CurrentSumBuffer[bar] < MinSumBuffer[bar]
         && CurrentSumBuffer[bar-1] >= MinSumBuffer[bar-1] )
      {
         SignalBuffer[bar] = MinSumBuffer[bar];
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
