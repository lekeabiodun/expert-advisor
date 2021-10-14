//+------------------------------------------------------------------+
//|                                                TradeBreakOut.mq5 |
//|                                  Copyright © 2013, Andriy Moraru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, Andriy Moraru"
#property link      "http://www.earnforex.com"
#property version   "1.0"

#property description "Red line crossing 0 from above is a support breakout signal."
#property description "Green line crossing 0 from below is a resistance breakout signal."

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_width1 1
#property indicator_color1 clrGreen
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_label1 "Resistance Breakout"
#property indicator_width2 1
#property indicator_color2 clrRed
#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_label2 "Support Breakout"

enum price_type
{
   Close,
   HighLow
};

input int L = 50; // Period
input price_type PriceType = HighLow;

// Buffers
double TBR_R[], TBR_S[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   SetIndexBuffer(0, TBR_R, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, L);

   SetIndexBuffer(1, TBR_S, INDICATOR_DATA);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, L);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString(INDICATOR_SHORTNAME, "TBR(" + IntegerToString(L) + ")");
}

//+------------------------------------------------------------------+
//| TradeBreakOut                                                    |
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
   int start;
   
   if (rates_total <= L) return(0);
   
   // Skip calculated bars
   start = prev_calculated - 1;
   // First run
   if (start < L) start = L;
   
   for (int i = L; i < rates_total; i++)
   {
      if (PriceType == Close)
      {
         TBR_R[i] = (close[i] - close[ArrayMaximum(close, i - L, L)]) / close[ArrayMaximum(close, i - L, L)];
         TBR_S[i] = (close[i] - close[ArrayMinimum(close, i - L, L)]) / close[ArrayMinimum(close, i - L, L)];
      }
      else if (PriceType == HighLow)
      {
         TBR_R[i] = (high[i] - high[ArrayMaximum(high, i - L, L)]) / high[ArrayMaximum(high, i - L, L)];
         TBR_S[i] = (low[i] - low[ArrayMinimum(low, i - L, L)]) / low[ArrayMinimum(low, i - L, L)];
      }
   }
   
   return(rates_total);
}
//+------------------------------------------------------------------+