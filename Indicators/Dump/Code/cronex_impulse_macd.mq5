//+------------------------------------------------------------------+ 
//|                                          Cronex_Impulse_MACD.mq5 | 
//|                                        Copyright � 2007, Cronex. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright � 2008, Cronex"
#property  link      "http://www.metaquotes.net/"
//---- ����� ������ ����������
#property version   "1.00"
//---- ��������� ���������� � ��������� ����
#property indicator_separate_window 
//---- ���������� ������������ ������� 4
#property indicator_buffers 4 
//---- ������������ ����� ��� ����������� ����������
#property indicator_plots   2
//+----------------------------------------------+
//| ��������� ��������� ���������� 1             |
//+----------------------------------------------+
//---- ��������� ���������� � ���� �������� ������
#property indicator_type1   DRAW_FILLING
//---- � �������� ������ ���������� ������������
#property indicator_color1  clrLime,clrRed
//---- ����������� ����� ����������
#property indicator_label1  "Cronex_Impulse_MACD Signal"
//+----------------------------------------------+
//| ��������� ��������� ���������� 2             |
//+----------------------------------------------+
//---- ��������� ���������� � ���� �������������� �����������
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//---- � �������� ������ ����������� ����������� ������������
#property indicator_color2 clrMediumVioletRed,clrViolet,clrGray,clrDeepSkyBlue,clrBlue
//---- ����� ���������� - ��������
#property indicator_style2 STYLE_SOLID
//---- ������� ����� ���������� ����� 2
#property indicator_width2 2
//---- ����������� ����� ����������
#property indicator_label2  "Cronex_Impulse_MACD"
//+----------------------------------------------+
//| ���������� ��������                          |
//+----------------------------------------------+
#define RESET  0 // ��������� ��� �������� ��������� ������� �� �������� ����������
//+----------------------------------------------+
//| ������� ��������� ����������                 |
//+----------------------------------------------+
input uint Master_MA=34;  // ������ ���������� MACD
input uint Signal_MA=9;   // ������ ���������� ����� 
//+-----------------------------------+
//---- ���������� ������������ ��������, ������� ����� � 
//---- ���������� ������������ � �������� ������������ �������
double IndBuffer[],ColorIndBuffer[];
double UpBuffer[],DnBuffer[];
//---- ���������� ������������� ���������� ��� ������� �����������
int MAh_Handle,MAl_Handle,MAw_Handle;
//---- ���������� ������������� ���������� ������ ������� ������
int min_rates_total,min_rates_1;
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- ������������� ���������� ������ ������� ������
   min_rates_1=int(Master_MA+1);
   min_rates_total=int(min_rates_1+Signal_MA+1);
//---- ��������� ������ ���������� iMA 1
   MAh_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_HIGH);
   if(MAh_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� iMA 1");
      return(INIT_FAILED);
     }
//---- ��������� ������ ���������� iMA 2
   MAl_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_LOW);
   if(MAl_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� iMA 2");
      return(INIT_FAILED);
     }
//---- ��������� ������ ���������� iMA 3
   MAw_Handle=iMA(NULL,0,Master_MA,0,MODE_SMA,PRICE_WEIGHTED);
   if(MAw_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� iMA 3");
      return(INIT_FAILED);
     }
//---- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(UpBuffer,true);
//---- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(DnBuffer,true);
//---- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(2,IndBuffer,INDICATOR_DATA);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(IndBuffer,true);
//---- ����������� ������������� ������� � ��������, ��������� �����   
   SetIndexBuffer(3,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(ColorIndBuffer,true);
//---- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- ��������� �������� ����������, ������� �� ����� ������ �� �������
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- ��������� �������� ����������, ������� �� ����� ������ �� �������
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- ������������� ���������� ��� ��������� ����� ����������
   string shortname;
   StringConcatenate(shortname,"Cronex_Impulse_MACD(",Master_MA,", ",Signal_MA,")");
//--- �������� ����� ��� ����������� � ��������� ������� � �� ����������� ���������
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- ����������� �������� ����������� �������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- ���������� �������������
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| MACD iteration function                                          | 
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
   if(BarsCalculated(MAh_Handle)<rates_total
      || BarsCalculated(MAl_Handle)<rates_total
      || BarsCalculated(MAw_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//---- ���������� ��������� ���������� 
   int to_copy,limit,bar;
   double MAh[],MAl[],MAw[];
//---- ������� ������������ ���������� ���������� ������ �
//---- ���������� ������ limit ��� ����� ��������� �����
   if(prev_calculated>rates_total || prev_calculated<=0)// �������� �� ������ ����� ������� ����������
     {
      limit=rates_total-min_rates_1-1; // ��������� ����� ��� ������� ���� �����
     }
   else
     {
      limit=rates_total-prev_calculated; // ��������� ����� ��� ������� ����� �����
     }
//----
   to_copy=limit+1; // ��������� ���������� ���� �����  
//---- �������� ����� ����������� ������ � �������
   if(CopyBuffer(MAh_Handle,0,0,to_copy,MAh)<=0) return(RESET);
   if(CopyBuffer(MAl_Handle,0,0,to_copy,MAl)<=0) return(RESET);
   if(CopyBuffer(MAw_Handle,0,0,to_copy,MAw)<=0) return(RESET);
//---- ���������� ��������� � �������� ��� � ����������  
   ArraySetAsSeries(MAh,true);
   ArraySetAsSeries(MAl,true);
   ArraySetAsSeries(MAw,true);
//---- �������� ���� ������� ����������
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      IndBuffer[bar]=0.0;
      if(MAw[bar]>MAh[bar]) IndBuffer[bar]=MAw[bar]-MAh[bar];
      if(MAw[bar]<MAl[bar]) IndBuffer[bar]=MAw[bar]-MAl[bar];
      IndBuffer[bar]/=_Point;
      UpBuffer[bar]=IndBuffer[bar];
      double Sum=0.0;
      if(IndBuffer[bar])
        {
         for(int iii=0; iii<int(Signal_MA) && !IsStopped(); iii++) Sum+=IndBuffer[MathMin(bar+iii,rates_total-1)];
         DnBuffer[bar]=Sum/Signal_MA;
        }
      else
        {
         UpBuffer[bar]=UpBuffer[bar+1];
         DnBuffer[bar]=UpBuffer[bar];
        }
     }
//----
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//---- �������� ���� ��������� ���������� Ind
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int clr=2;
      //----
      if(IndBuffer[bar]>0)
        {
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=4;
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=3;
        }
      //----
      if(IndBuffer[bar]<0)
        {
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=0;
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=1;
        }
      //----
      ColorIndBuffer[bar]=clr;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
