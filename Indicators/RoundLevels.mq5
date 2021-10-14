//+------------------------------------------------------------------+
//|                                                  RoundLevels.mq5 |
//|                                         Copyright © 2007, Martes |
//|               http://championship.mql4.com/2007/ru/users/Martes/ |
//+------------------------------------------------------------------+
//---- Copyright
#property copyright "Copyright © 2007, Martes"
//---- link to the website of the author
#property link      "http://championship.mql4.com/2007/users/Martes/"

#property description "This code draws 4 horizontal lines with 00 at the end of"
#property description "the vertical coordinate (price). This 4 horizontal lines with"
#property description "this property are closest to current price."

//---- drawing the indicator in the main window
#property indicator_chart_window 

//---- no buffers used for the calculation and drawing of the indicator
#property indicator_buffers 0
//---- 0 graphical plots are used
#property indicator_plots   0
//+------------------------------------------------+ 
//| Enumeration for the level width                |
//+------------------------------------------------+ 
enum ENUM_WIDTH //Type of constant
  {
   w_1 = 1,   //1
   w_2,       //2
   w_3,       //3
   w_4,       //4
   w_5        //5
  };
//+------------------------------------------------+ 
//| Enumeration for the level style                |
//+------------------------------------------------+ 
enum STYLE
  {
   SOLID_,//Solid line
   DASH_,//Dashed line
   DOT_,//Dotted line
   DASHDOT_,//Dot-dash line
   DASHDOTDOT_   // Dot-dash line with double dots
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input int ZeroCount=2;   //Number of zeros for rounding
input string levels_sirname="Price_Level_1"; //Label of the levels

input color Up_level_color2=clrBlue;    //The color of the second upper level
input STYLE Up_level_style2=SOLID_;     //The style of the second upper level
input ENUM_WIDTH Up_level_width2=w_3;   //The width of the second upper level

input color Up_level_color1=clrLime;    //The color of the first upper level
input STYLE Up_level_style1=SOLID_;     //The style of the first upper level
input ENUM_WIDTH Up_level_width1=w_3;   //The width of the first upper level

input color Dn_level_color1=clrRed;     //The color of the first lower level
input STYLE Dn_level_style1=SOLID_;     //The style of the first lower level
input ENUM_WIDTH Dn_level_width1=w_3;   //The width of the first lower level

input color Dn_level_color2=clrMagenta; //The color of the second lower level
input STYLE Dn_level_style2=SOLID_;     //The style of the second lower level
input ENUM_WIDTH Dn_level_width2=w_3;   //The width of the second lower level
//+----------------------------------------------+

int Normalize;
string UpName2,UpName1,DnName1,DnName2;
//+------------------------------------------------------------------+
//|  Creating the horizontal line                                    |
//+------------------------------------------------------------------+
void CreateHline
(
 long     chart_id,      // chart ID
 string   name,          // object name
 int      nwin,          // window index
 double   price,         // horizontal level price
 color    Color,         // line color
 int      style,         // line style
 int      width,         // line width
 bool     background,// background display of the line
 string   text           // text
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_HLINE,nwin,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  Horizontal line relocation                                      |
//+------------------------------------------------------------------+
void SetHline
(
 long     chart_id,      // chart ID
 string   name,          // object name
 int      nwin,          // window index
 double   price,         // horizontal level price
 color    Color,         // line color
 int      style,         // line style
 int      width,         // line width
 bool     background,// background display of the line
 string   text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   UpName2=levels_sirname+"_UpName2";
   UpName1=levels_sirname+"_UpName1";
   DnName1=levels_sirname+"_DnName1";
   DnName2=levels_sirname+"_DnName2";
   Normalize=_Digits-ZeroCount;
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---- Delete levels
   ObjectDelete(0,UpName2);
   ObjectDelete(0,UpName1);
   ObjectDelete(0,DnName1);
   ObjectDelete(0,DnName2);
//----
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of price lows for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- declaration of local variables 
   double UpLevel2,UpLevel1,DnLevel2,VShift;
   static double DnLevel1;
//----
   DnLevel1=NormalizeDouble(close[rates_total-1],_Digits-ZeroCount);
   VShift=_Point*MathPow(10,ZeroCount);
   UpLevel1=DnLevel1+VShift;
   UpLevel2=UpLevel1+VShift;
   DnLevel2=DnLevel1-VShift;

   SetHline(0,UpName2,0,UpLevel2,Up_level_color2,Up_level_style2,Up_level_width2,false,UpName1);
   SetHline(0,UpName1,0,UpLevel1,Up_level_color1,Up_level_style1,Up_level_width1,false,UpName1);
   SetHline(0,DnName1,0,DnLevel1,Dn_level_color1,Dn_level_style1,Dn_level_width1,false,DnName1);
   SetHline(0,DnName2,0,DnLevel2,Dn_level_color2,Dn_level_style2,Dn_level_width2,false,DnName2);   
//----
   ChartRedraw(0); 
   return(rates_total);
  }
//+------------------------------------------------------------------+
