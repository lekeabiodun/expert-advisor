//+------------------------------------------------------------------+
//|                                                     Fibo_Bar.mq5 |
//|                                                  © Tecciztecatl  |
//+------------------------------------------------------------------+
#property copyright     "© Tecciztecatl 2016"
#property link          "https://www.mql5.com/en/users/tecciztecatl"
#property version       "1.00"
#property description   "This indicator draws Fibo levels on the last bar."
#property strict
#property indicator_chart_window
#property indicator_plots 0

extern string comm0="";                      //-     -   -- ---- FIBO ---- --   -     -
extern ENUM_TIMEFRAMES Fibo_Bar=PERIOD_D1;   //Last Bar for Fibo
extern color  fibo_color1=SkyBlue;           //Upper color 
extern color  fibo_color0=LimeGreen;         //Main color 
extern color  fibo_color2=Orange;            //Lower color 
extern ENUM_LINE_STYLE fibo_style=STYLE_DOT; //Style lines
input  int    fibo_width=1;                  //Line Width

double FIBO_levels[];
double FIBO_prices[];
string fibo_txt[];
string fibo_levels0="0 23.6 38.2 50 61.8 76.4 100"; //7+18+24
string fibo_levels1="123.6 138.2 150 161.8 176.4 200 223.6 238.2 250 261.8 276.4 300 323.6 338.2 350 361.8 376.4 400";
string fibo_levels2="-23.6 -38.2 -50 -61.8 -76.4 -100 -123.6 -138.2 -150 -161.8 -176.4 -200 -223.6 -238.2 -250 -261.8 -276.4 -300 -323.6 -338.2 -350 -361.8 -376.4 -400";
string Label_prefix="Fibo_";
int    allBars;
datetime    ArrDate[1];
double      ArrDouble[1];
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteObjects();
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(Fibo_Bar==PERIOD_CURRENT) Fibo_Bar=(ENUM_TIMEFRAMES)Period();
   return(INIT_SUCCEEDED);
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
   if(allBars!=Bars(_Symbol,Fibo_Bar) || ObjectFind(0,Label_prefix+"f0")<0)
     {
      allBars=Bars(_Symbol,Fibo_Bar);
      BuildLevels();
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+


void BuildLevels()
  {

   double Maximum = iHigh(NULL,Fibo_Bar,1);
   double Minimum = iLow (NULL,Fibo_Bar,1);
   datetime time1 = iTime(NULL,Fibo_Bar,0)+PeriodSeconds(Fibo_Bar)*7;
   datetime time2 = iTime(NULL,Fibo_Bar,1);
   string   tf=TFtoStr(Fibo_Bar);

   MakeFibo(fibo_levels0);
   SetFibo(Label_prefix+"f0",time1,Maximum,time2,Minimum,fibo_color0,fibo_width,clrNONE);
   ObjectSetString(0,Label_prefix+"f0",OBJPROP_LEVELTEXT,6,"High last "+tf+" "+ObjectGetString(0,Label_prefix+"f0",OBJPROP_LEVELTEXT,6));
   ObjectSetString(0,Label_prefix+"f0",OBJPROP_LEVELTEXT,0,"Low last "+tf+" "+ObjectGetString(0,Label_prefix+"f0",OBJPROP_LEVELTEXT,0));

   MakeFibo(fibo_levels1);
   SetFibo(Label_prefix+"f1",time1,Maximum,time2,Minimum,fibo_color1,fibo_width,clrNONE);

   MakeFibo(fibo_levels2);
   SetFibo(Label_prefix+"f2",time1,Maximum,time2,Minimum,fibo_color2,fibo_width,clrNONE);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetFibo(const string   nname,
             datetime        time1,
             double          price1,
             datetime        time2,
             double          price2,
             color           cvet,
             int             wiDth,
             color           cvet_full,
             )
  {
   int levels=ArraySize(FIBO_levels);
   if(ObjectFind(0,nname)<0)
     {
      ObjectCreate(0,nname,OBJ_FIBO,0,time1,price1,time2,price2);
      ObjectSetInteger(0,nname,OBJPROP_COLOR,cvet_full);
      ObjectSetInteger(0,nname,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,nname,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,nname,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,nname,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,nname,OBJPROP_BACK,true);
      ObjectSetInteger(0,nname,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,nname,OBJPROP_HIDDEN,true);
     }
   else
     {
      ObjectMove(0,nname,0,time1,price1);
      ObjectMove(0,nname,1,time2,price2);
     }

   ObjectSetInteger(0,nname,OBJPROP_LEVELS,levels);
   for(int i=0;i<levels;i++)
     {
      FIBO_prices[i]=NormalizeDouble((price1-price2)*FIBO_levels[i]+price2,_Digits);
      ObjectSetDouble(0,nname,OBJPROP_LEVELVALUE,i,FIBO_levels[i]);
      ObjectSetString(0,nname,OBJPROP_LEVELTEXT,i,"("+DoubleToString(100*FIBO_levels[i],1)+") "+DoubleToString(FIBO_prices[i],_Digits));
      ObjectSetInteger(0,nname,OBJPROP_LEVELCOLOR,i,cvet);
      ObjectSetInteger(0,nname,OBJPROP_LEVELWIDTH,i,wiDth);
      ObjectSetInteger(0,nname,OBJPROP_LEVELSTYLE,i,fibo_style);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TFtoStr(ENUM_TIMEFRAMES TimeFrameInt)
  {
   string TimeFrame;
   if(TimeFrameInt==PERIOD_M1)TimeFrame="M1";
   if(TimeFrameInt==PERIOD_M2)TimeFrame="M2";
   if(TimeFrameInt==PERIOD_M3)TimeFrame="M3";
   if(TimeFrameInt==PERIOD_M4)TimeFrame="M4";
   if(TimeFrameInt==PERIOD_M5)TimeFrame="M5";
   if(TimeFrameInt==PERIOD_M6)TimeFrame="M6";
   if(TimeFrameInt==PERIOD_M10)TimeFrame="M10";
   if(TimeFrameInt==PERIOD_M12)TimeFrame="M12";
   if(TimeFrameInt==PERIOD_M15)TimeFrame="M15";
   if(TimeFrameInt==PERIOD_M30)TimeFrame="M20";
   if(TimeFrameInt==PERIOD_M30)TimeFrame="M30";
   if(TimeFrameInt==PERIOD_H1)TimeFrame="H1";
   if(TimeFrameInt==PERIOD_H2)TimeFrame="H2";
   if(TimeFrameInt==PERIOD_H3)TimeFrame="H3";
   if(TimeFrameInt==PERIOD_H4)TimeFrame="H4";
   if(TimeFrameInt==PERIOD_H6)TimeFrame="H6";
   if(TimeFrameInt==PERIOD_H8)TimeFrame="H8";
   if(TimeFrameInt==PERIOD_H12)TimeFrame="H12";
   if(TimeFrameInt==PERIOD_D1)TimeFrame="D1";
   if(TimeFrameInt==PERIOD_W1)TimeFrame="W1";
   if(TimeFrameInt==PERIOD_MN1)TimeFrame="MN1";
   return(TimeFrame);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MakeFibo(string   text)
  {
   ushort u_sep=StringGetCharacter(" ",0);
   int num_levels=StringSplit(text,u_sep,fibo_txt);
   ArrayResize(FIBO_levels,num_levels);
   ArrayResize(FIBO_prices,num_levels);
   for(int i=0;i<num_levels;i++)
      FIBO_levels[i]=NormalizeDouble(StringToDouble(fibo_txt[i])/100,3);
   ArraySort(FIBO_levels);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteObjects()
  {
   for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
     {
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,"Fibo_",0)>=0)
         ObjectDelete(0,name);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime iTime(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   if(index<0) index=0;
   if(CopyTime(symbol, timeframe, index, 1, ArrDate)>0) return(ArrDate[0]);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLow(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   if(index < 0) return(-1);
   if(CopyLow(symbol, timeframe, index, 1, ArrDouble)>0) return(ArrDouble[0]);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   if(index < 0) return(-1);
   if(CopyHigh(symbol, timeframe, index, 1, ArrDouble)>0) return(ArrDouble[0]);
   else return(-1);
  }
//+------------------------------------------------------------------+
