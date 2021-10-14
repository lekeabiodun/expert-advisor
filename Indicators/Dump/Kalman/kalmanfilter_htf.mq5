//+------------------------------------------------------------------+ 
//|                                             KalmanFilter_HTF.mq5 | 
//|                               Copyright � 2015, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright � 2015, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- ����� ������ ����������
#property version   "1.60"
//---- ��������� ���������� � ������� ����
#property indicator_chart_window
//---- ���������� ������������ ������� 2
#property indicator_buffers 2 
//---- ������������ ����� ���� ����������� ����������
#property indicator_plots   1
//+----------------------------------------------+
//| ��������� ��������� ����������               |
//+----------------------------------------------+
//---- ��������� ���������� � ���� ����������� �����
#property indicator_type1 DRAW_COLOR_LINE
//---- � �������� ������ ����������� ����� ������������
#property indicator_color1  clrOrange,clrTurquoise
//---- ����� ���������� - ��������
#property indicator_style1 STYLE_SOLID
//---- ������� ����� ���������� ����� 3
#property indicator_width1 3
//---- ����������� ����� ���������� �����
#property indicator_label1  "Signal Line"
//+----------------------------------------------+
//| ���������� ������������                      |
//+----------------------------------------------+
enum Applied_price_ //��� ���������
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };
//+----------------------------------------------+
enum Signal_mode
  {
   Trend, //�� ������
   Kalman //�� ��������
  };
//+----------------------------------------------+
//| ���������� ��������                          |
//+----------------------------------------------+
#define RESET 0 // ��������� ��� �������� ��������� ������� �� �������� ����������
//+----------------------------------------------+
//| ������� ��������� ����������                 |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4; // ������ ������� ����������
input double K=1.0;                        // ����������� �����������
input Applied_price_ IPC=PRICE_WEIGHTED;   // ������� ���������
input Signal_mode Signal=Kalman;           // ����� ��������� ������� �����
input int Shift=0;                         // ����� ���������� �� ����������� � �����
input int PriceShift=0;                    // ����� ���������� �� ��������� � �������
input bool ReDraw=true;                    // ������ ����������� ���������� �� ������ �����
//+----------------------------------------------+
//---- ���������� ������������� ���������� ������ ������� ������
int min_rates_total;
//---- ���������� ������������� ���������� ��� ������� �����������
int Ind_Handle;
//---- ���������� ������������ ��������, ������� ����� � 
//---- ���������� ������������ � �������� ������������ �������
double IndBuffer[],ColorIndBuffer[];
//+------------------------------------------------------------------+
//| ��������� ���������� � ���� ������                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//----
   return(StringSubstr(EnumToString(timeframe),7,-1));
  }
//+------------------------------------------------------------------+    
//| KalmanFilter indicator initialization function                   | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- ������������� ���������� ������ ������� ������
   min_rates_total=3;
//---- �������� �������� �������� �� ������������
   if(TimeFrame<Period() && TimeFrame!=PERIOD_CURRENT)
     {
      Print("������ ������� ��� ���������� KalmanFilter �� ����� ���� ������ ������� �������� �������");
      return(INIT_FAILED);
     }
//---- ��������� ������ ���������� KalmanFilter
   Ind_Handle=iCustom(Symbol(),TimeFrame,"KalmanFilter",K,IPC,Signal,0,PriceShift);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� KalmanFilter");
      return(INIT_FAILED);
     }
//---- ����������� ������������� ������� IndBuffer � ������������ �����
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- ��������� �������� ����������, ������� �� ����� ������ �� �������
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(IndBuffer,true);
//---- ����������� ������������� ������� � ��������, ��������� �����   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(ColorIndBuffer,true);
//---- ������������� ���������� ��� ��������� ����� ����������
   string shortname;
   StringConcatenate(shortname,"KalmanFilter HTF( ",GetStringTimeframe(TimeFrame)," )");
//--- �������� ����� ��� ����������� � ��������� ������� � �� ����������� ���������
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- ����������� �������� ����������� �������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- ���������� �������������
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| KalmanFilter iteration function                                  | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // ���������� ������� � ����� �� ������� ����
                const int prev_calculated,// ���������� ������� � ����� �� ���������� ����
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- �������� ���������� ����� �� ������������� ��� �������
   if(rates_total<min_rates_total) return(RESET);
   if(BarsCalculated(Ind_Handle)<Bars(Symbol(),TimeFrame)) return(prev_calculated);
//---- ���������� ������������� ����������
   int limit,bar;
//---- ���������� ���������� � ��������� ������  
   double Ind[1],Col[1];
   datetime IndTime[1];
   static uint LastCountBar;
//---- ������� ������������ ���������� ���������� ������ �
//---- ���������� ������ limit ��� ����� ��������� �����
   if(prev_calculated>rates_total || prev_calculated<=0)// �������� �� ������ ����� ������� ����������
     {
      limit=rates_total-min_rates_total-1; // ��������� ����� ��� ������� ���� �����
      LastCountBar=rates_total;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // ��������� ����� ��� ������� ����� ����� 
//---- ���������� ��������� � �������� ��� � ����������  
   ArraySetAsSeries(time,true);
//---- �������� ���� ������� ����������
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- ������� ���������� ������������ ������� �� �������
      IndBuffer[bar]=EMPTY_VALUE;
      ColorIndBuffer[bar]=0;
      //---- �������� ����� ����������� ������ � ������
      if(CopyTime(Symbol(),TimeFrame,time[bar],1,IndTime)<=0) return(RESET);
      //----
      if(time[bar]>=IndTime[0] && time[bar+1]<IndTime[0])
        {
         LastCountBar=bar;
         //---- �������� ����� ����������� ������ � �������
         if(CopyBuffer(Ind_Handle,0,time[bar],1,Ind)<=0) return(RESET);
         if(CopyBuffer(Ind_Handle,1,time[bar],1,Col)<=0) return(RESET);
         //---- �������� ���������� �������� � ������������ ������
         IndBuffer[bar]=Ind[0];
         ColorIndBuffer[bar]=Col[0];
        }
      if(ReDraw)
        {
         if(IndBuffer[bar+1]!=EMPTY_VALUE && IndBuffer[bar]==EMPTY_VALUE)
           {
            IndBuffer[bar]=IndBuffer[bar+1];
            ColorIndBuffer[bar]=ColorIndBuffer[bar+1];
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
