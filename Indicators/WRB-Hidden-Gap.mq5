//+------------------------------------------------------------------+
//|                                               WRB-Hidden-Gap.mq5 |
//| 				                      Copyright � 2014, EarnForex.com |
//|                                        http://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "EarnForex.com"
#property link      "http://www.earnforex.com"
#property version   "1.01"

#property description "Identifies Wide Range Bars and Hidden Gaps."
#property description "WRB and HG definitions are taken from the WRB Analysis Tutorial-1"
#property description "by M.A.Perry from TheStrategyLab.com."
#property description "Conversion from MQL4 to MQL5, alerts and optimization by Andriy Moraru."

#property indicator_chart_window

#property indicator_plots   1
#property indicator_buffers 1

#property indicator_type1 DRAW_ARROW
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrAqua      // WRB symbol
#property indicator_width1 1

#define UNFILLED_PREFIX "HG_UNFILLED_"
#define FILLED_PREFIX "HG_FILLED_"
#define PREFIX "HG_"

input bool UseWholeBars = false;
input int WRB_LookBackBarCount = 3;
input int WRB_WingDingsSymbol = 115;
input color HGcolor1 = clrDodgerBlue;
input color HGcolor2 = clrBlue;
input ENUM_LINE_STYLE HGstyle = STYLE_SOLID;
input int StartCalculationFromBar = 100;
input bool HollowBoxes = false;
input bool DoAlerts = false;
//---- buffers
double WRB[];

int totalBarCount = -1;

//+------------------------------------------------------------------+
//| Delete all objects with given prefix                             |
//+------------------------------------------------------------------+
void ObDeleteObjectsByPrefix(string Prefix)
{
   int L = StringLen(Prefix);
   int i = 0; 
   while(i < ObjectsTotal(0, -1, OBJ_RECTANGLE))
   {
      string ObjName = ObjectName(0, i, -1, OBJ_RECTANGLE);
      if(StringSubstr(ObjName, 0, L) != Prefix) 
      { 
         i++; 
         continue;
      }
      ObjectDelete(0, ObjName);
   }
}

//+------------------------------------------------------------------+
//|  intersect: Check two bars intersect or not                      |
//+------------------------------------------------------------------+
int intersect(double H1, double L1, double H2, double L2)
{
   if ((L1 > H2) || (H1 < L2)) return (0);
   if ((H1 >= H2) && (L1 >= L2)) return(1);
   if ((H1 <= H2) && (L1 <= L2)) return(2);
   if ((H1 >= H2) && (L1 <= L2)) return(3);
   if ((H1 <= H2) && (L1 >= L2)) return(4);
   return(0);
}  
  
//+------------------------------------------------------------------+
//|  checkHGFilled: Check if the hidden gap is filled or not         |
//+------------------------------------------------------------------+
void checkHGFilled(int barNumber, const double &High[], const double &Low[], const datetime &Time[], int rates_total)
{
   int j, i;
   string ObjectText;
   string Prefix = UNFILLED_PREFIX;
   double box_H, box_L;
   double HGFillPA_H, HGFillPA_L;
   datetime startTime;
   color objectColor;

   int L = StringLen(Prefix);
   i = 0; 
   while(i < ObjectsTotal(0, -1, OBJ_RECTANGLE)) // loop over all unfilled boxes
   {
      string ObjName = ObjectName(0, i, -1, OBJ_RECTANGLE);
      if (StringSubstr(ObjName, 0, L) != Prefix) 
      { 
         i++; 
         continue;
      }
      box_H = ObjectGetDouble(0, ObjName, OBJPROP_PRICE, 0); // get HG high and low values
      box_L = ObjectGetDouble(0, ObjName, OBJPROP_PRICE, 1);
      objectColor = ObjectGetInteger(0, ObjName, OBJPROP_COLOR);
      startTime = ObjectGetInteger(0, ObjName, OBJPROP_TIME, 0);
           
      HGFillPA_H = High[barNumber];
      HGFillPA_L = Low[barNumber];
      
      j = 0;
      while ((intersect(High[barNumber - j], Low[barNumber - j], box_H, box_L) != 0) && (barNumber - j >= 0) && (startTime < Time[barNumber - j]))
      {
         if (High[barNumber - j] > HGFillPA_H) HGFillPA_H = High[barNumber - j];
         if (Low[barNumber - j]  < HGFillPA_L) HGFillPA_L = Low[barNumber - j];
         if ((HGFillPA_H > box_H) && (HGFillPA_L < box_L))
         {
            ObjectDelete(0, ObjName);
            ObjectText = FILLED_PREFIX + TimeToString(startTime, TIME_DATE|TIME_MINUTES);            
            ObjectCreate(0, ObjectText, OBJ_RECTANGLE, 0, startTime, box_H, Time[barNumber], box_L);
            ObjectSetInteger(0, ObjectText, OBJPROP_STYLE, HGstyle);
            ObjectSetInteger(0, ObjectText, OBJPROP_COLOR, objectColor);
            ObjectSetInteger(0, ObjectText, OBJPROP_FILL, !HollowBoxes);
            break;
         }
         j++;
      }
      i++;
   }
}

//+------------------------------------------------------------------+
//| checkWRB: Check if the given bar is a WRB or not                 |
//| The lookback period can be changed by user input                 |
//+------------------------------------------------------------------+
// If UseWholeBars = true, High[] and Low[] will be passed to this function.
bool checkWRB(int i, const double &Open[], const double &Close[])
{
   int j;
   bool WRB_test;
   double body, bodyPrior;
   
   WRB_test = true;
   body = MathAbs(Open[i] - Close[i]);
   for (j = 1; j <= WRB_LookBackBarCount; j++)
   {
      bodyPrior = MathAbs(Open[i - j] - Close[i - j]);
      if (bodyPrior > body)
      {
         WRB_test = false;
         break;
      }            
   }
   
   if (WRB_test) WRB[i] = (Open[i] + Close[i]) / 2;
   else WRB[i] = EMPTY_VALUE;
 
   return(WRB_test);
}

//+------------------------------------------------------------------+
//| checkHG: Checks HG status of the previous bar.                   |
//+------------------------------------------------------------------+
void checkHG(int i, const double &High[], const double &Low[], const double &Open[], const double &Close[], const datetime &Time[])
{
   string ObjectText;
   double H, L, H2, L2, H1, L1, A, B;
   int j;
   color HGcolor = HGcolor1;

   // HG-TEST ( test the previous bar i-1)
   if (WRB[i - 1] != EMPTY_VALUE) // First rule to become a HG is to become a WRB
   {
      H2 = High[i - 2];
      L2 = Low[i - 2];
      H1 = High[i];
      L1 = Low[i];
            
      if (UseWholeBars)
      {
         H = High[i - 1];
         L = Low[i - 1];
      }
      else if (Open[i - 1] > Close[i - 1])
      {
         H = Open[i - 1];
         L = Close[i - 1];
      }
      else
      {
         H = Close[i - 1];
         L = Open[i - 1];
      }
      
      // Older bar higher than the newer.
      if (L2 > H1)
      {
         A = MathMin(L2, H);
         B = MathMax(H1, L);
      }
      else if (L1 > H2)
      {
         A = MathMin(L1, H);
         B = MathMax(H2, L);
      }
      else return;
      
      if (A > B)
      {
         int Length = StringLen(UNFILLED_PREFIX);
         j = 0; 
         while(j < ObjectsTotal(0, -1, OBJ_RECTANGLE)) // loop over all unfilled boxes
         {
            ObjectText = ObjectName(0, j, -1, OBJ_RECTANGLE);
            if (StringSubstr(ObjectText, 0, Length) != UNFILLED_PREFIX) 
            { 
               j++; 
               continue;
            }
            // Switch colors if the new Hidden Gap is intersecting with previous Hidden Gap.
            if (intersect(ObjectGetDouble(0, ObjectText, OBJPROP_PRICE), ObjectGetDouble(0, ObjectText, OBJPROP_PRICE, 1), A, B) != 0)
            {
               HGcolor = ObjectGetInteger(0, ObjectText, OBJPROP_COLOR);
               if (HGcolor == HGcolor1) HGcolor = HGcolor2;
               else HGcolor = HGcolor1;               
               break;
            }
            j++;
         }
      
         ObjectText = UNFILLED_PREFIX + TimeToString(Time[i - 1], TIME_DATE|TIME_MINUTES);
         ObjectCreate(0, ObjectText, OBJ_RECTANGLE, 0, Time[i - 1], A, TimeCurrent() + 10 * 365 * 24 * 60 * 60, B);
         ObjectSetInteger(0, ObjectText, OBJPROP_STYLE, HGstyle);
         ObjectSetInteger(0, ObjectText, OBJPROP_COLOR, HGcolor);
         ObjectSetInteger(0, ObjectText, OBJPROP_FILL, !HollowBoxes);               
      }
   } //End of HG-Test
}

void CheckAlert()
{
   int total = ObjectsTotal(0, -1, OBJ_RECTANGLE);
   // Loop over all unfilled boxes.
   for (int j = 0; j < total; j++)
   {
      string ObjectText = ObjectName(0, j, -1, OBJ_RECTANGLE);
      // Object marked as alerted.
      if (StringSubstr(ObjectText, StringLen(ObjectText) - 1, 1) == "A")
      {
         // Try to find a dupe object (could be result of a bug) and delete it.
         string ObjectNameWithoutA = StringSubstr(ObjectText, 0, StringLen(ObjectText) - 1);
         if (ObjectFind(0, ObjectNameWithoutA) >= 0) ObjectDelete(0, ObjectNameWithoutA);
         continue;
      }
      int Length = StringLen(UNFILLED_PREFIX);
      if (StringSubstr(ObjectText, 0, Length) != UNFILLED_PREFIX) continue;
      
      double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double Price1 = ObjectGetDouble(0, ObjectText, OBJPROP_PRICE);
      double Price2 = ObjectGetDouble(0, ObjectText, OBJPROP_PRICE, 1);
      double High = MathMax(Price1, Price2);
      double Low = MathMin(Price1, Price2);
      
      // Current price above lower border
      if ((Ask > Low) && (Bid < High))
      {
         Alert(Symbol() + ": " + "WRB rectangle breached.");
         PlaySound("alert.wav");
         ObjectSetString(0, ObjectText, OBJPROP_NAME, ObjectText + "A");
         return;
      }
   }
}
  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   SetIndexBuffer(0, WRB, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_ARROW, WRB_WingDingsSymbol);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetString(0, PLOT_LABEL, "WRB");
   IndicatorSetString(INDICATOR_SHORTNAME, "WRB+HG");
   ArrayInitialize(WRB, EMPTY_VALUE);
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObDeleteObjectsByPrefix(PREFIX);
}

//+------------------------------------------------------------------+
//| Custom Market Profile main iteration function                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (DoAlerts) CheckAlert();
   
   // A new bar started.
   if (totalBarCount != rates_total)
   {
      int start = prev_calculated;
      start--;
      // Need at least WRB_LookBackBarCount bars from the end of the chart to work.
      if (start < WRB_LookBackBarCount) start = WRB_LookBackBarCount;
      // Maximum number of bars to calculate is StartCalculationFromBar.
      if (start < rates_total - 1 - StartCalculationFromBar) start = rates_total - 1 - StartCalculationFromBar;
      
      for (int i = start; i < rates_total - 1; i++)
      {
         if (UseWholeBars)checkWRB(i, High, Low);
         else checkWRB(i, Open, Close);
         checkHG(i, High, Low, Open, Close, Time);
         checkHGFilled(i, High, Low, Time, rates_total);
      }
      totalBarCount = rates_total;
   }
   // Additional check to see if current bar made the Hidden Gap filled.
   checkHGFilled(rates_total - 1, High, Low, Time, rates_total);
   WRB[rates_total - 1] = EMPTY_VALUE;
   
   return(rates_total);
}
//+------------------------------------------------------------------+