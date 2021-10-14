//+------------------------------------------------------------------+
//|                                               CronexDeMarker.mq5 |
//|                                        Copyright � 2007, Cronex. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright � 2007, Cronex"
#property  link      "http://www.metaquotes.net/"
//--- ����� ������ ����������
#property version   "1.00"
//--- ��������� ���������� � ��������� ����
#property indicator_separate_window 
//--- ���������� ������������ ������� 2
#property indicator_buffers 2 
//--- ������������ ���� ����������� ����������
#property indicator_plots   1
//+-----------------------------------+
//|  ��������� ��������� ����������   |
//+-----------------------------------+
//--- ��������� ���������� � ���� �������� ������
#property indicator_type1   DRAW_FILLING
//--- � �������� ������ ���������� ������������
#property indicator_color1  clrTeal,clrMagenta
//--- ����������� ����� ����������
#property indicator_label1  "CronexDeMarker"
//+-----------------------------------+
//| �������� ������ CXMA              |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//--- ���������� ���������� ������ CXMA �� ����� SmoothAlgorithms.mqh
CXMA XMA1,XMA2;
//+-----------------------------------+
//| ���������� ��������               |
//+-----------------------------------+
#define RESET 0 // ��������� ��� �������� ��������� ������� �� �������� ����������
//+-----------------------------------+
//| ������� ��������� ����������      |
//+-----------------------------------+
input uint DeMarkerPeriod=25;            // ������ ���������� DeMarker
input Smooth_Method XMA_Method=MODE_SMA; // ����� ����������
input uint FastPeriod=14;                // ������ �������� ����������
input uint SlowPeriod=25;                // ����� ���������� ����������
input int XPhase=15;                     // �������� ����������� (-100..100)
//--- ���������� ������������ ��������, ������� � ����������
//--- ����� ������������ � �������� ������������ �������
double ExtABuffer[],ExtBBuffer[];
//--- ���������� ������������� ���������� ��� �������� ������� �����������
int Ind_Handle;
//--- ���������� ������������� ���������� ������ ������� ������
int  min_rates_1,min_rates_2,min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- ������������� ���������� ������ ������� ������
   min_rates_1=int(DeMarkerPeriod);
   min_rates_2=min_rates_1+XMA1.GetStartBars(XMA_Method,FastPeriod,XPhase);
   min_rates_total=min_rates_2+XMA1.GetStartBars(XMA_Method,SlowPeriod,XPhase);
//--- ��������� ������ ���������� iDeMarker
   Ind_Handle=iDeMarker(Symbol(),PERIOD_CURRENT,DeMarkerPeriod);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� iDeMarker");
      return(INIT_FAILED);
     }
//--- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//--- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(ExtABuffer,true);
//--- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//--- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(ExtBBuffer,true);
//--- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- ��������� �������� ����������, ������� �� ����� ������ �� �������
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- �������� ����� ��� ����������� � ��������� ������� � �� ����������� ���������
   IndicatorSetString(INDICATOR_SHORTNAME,"CronexDeMarker");
//--- ����������� �������� ����������� �������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS,4);
//--- ���������� �������������
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
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
//--- �������� ���������� ����� �� ������������� ��� �������
   if(rates_total<min_rates_total || BarsCalculated(Ind_Handle)<rates_total) return(RESET);
//--- ���������� ��������� ���������� 
   int to_copy,limit,bar,maxbar1,maxbar2;
//--- ���������� ���������� � ��������� ������  
   double DeMark[];
//--- ���������� ��������� � �������� ��� � ����������  
   ArraySetAsSeries(DeMark,true);
//--- ������� ������������ ���������� ���������� ������
//--- � ���������� ������ limit ��� ����� ��������� �����
   if(prev_calculated>rates_total || prev_calculated<=0)// �������� �� ������ ����� ������� ����������
     {
      limit=rates_total-min_rates_1-1; // ��������� ����� ��� ������� ���� �����
     }
   else limit=rates_total-prev_calculated; // ��������� ����� ��� ������� ����� �����
//---   
   to_copy=limit+1;
//--- �������� ����� ����������� ������ � �������
   if(CopyBuffer(Ind_Handle,0,0,to_copy,DeMark)<=0) return(RESET);
   maxbar1=rates_total-min_rates_1-1;
   maxbar2=rates_total-min_rates_2-1;
//--- ������ ���� ������� ����������
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtABuffer[bar]=XMA1.XMASeries(maxbar1,prev_calculated,rates_total,XMA_Method,XPhase,FastPeriod,DeMark[bar],bar,true);
      ExtBBuffer[bar]=XMA2.XMASeries(maxbar2,prev_calculated,rates_total,XMA_Method,XPhase,SlowPeriod,ExtABuffer[bar],bar,true);
     } 
//---
   return(rates_total);
  }
//+------------------------------------------------------------------+
