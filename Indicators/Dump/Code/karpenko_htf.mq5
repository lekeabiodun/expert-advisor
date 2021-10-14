//+------------------------------------------------------------------+ 
//|                                                 Karpenko_HTF.mq5 | 
//|                               Copyright � 2014, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright � 2014, Nikolay Kositsin"
#property link "arria@mail.redcom.ru"
//--- ����� ������ ����������
#property version   "1.60"
#property description "Karpenko � ������������ ��������� ���������� �� ������� ����������"
//--- ��������� ���������� � ������� ����
#property indicator_chart_window
//--- ���������� ������������ ������� 2
#property indicator_buffers 2 
//--- ������������ ���� ����������� ����������
#property indicator_plots   1
//+----------------------------------------------+
//|  ���������� ��������                         |
//+----------------------------------------------+
#define RESET 0                    // ��������� ��� �������� ��������� ������� �� �������� ����������
#define INDICATOR_NAME "Karpenko"  // ��������� ��� ����� ����������
#define SIZE 1                     // ��������� ��� ���������� ������� ������� CountIndicator ����
//+----------------------------------------------+
//| ��������� ��������� ���������� 1             |
//+----------------------------------------------+
//--- ��������� ���������� � ���� �������� ������
#property indicator_type1   DRAW_FILLING
//--- � �������� ������ ���������� ������������
#property indicator_color1  clrPaleGreen,clrLightPink
//--- ����������� ����� ����������
#property indicator_label1  "Signal HTF"
//+----------------------------------------------+
//| ������� ��������� ����������                 |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;        // ������ ������� ���������� (���������)
input uint Basic_MA=144;                          // ������ MA
input uint History=500;                           // ������ �������
input int Shift=0;                                // ����� ���������� �� ����������� � �����
//+----------------------------------------------+
//--- ���������� ������������ ��������, ������� � ����������
//--- ����� ������������ � �������� ������������ �������
double UpIndBuffer[];
double DnIndBuffer[];
//--- ���������� ������������� ���������� ������ ������� ������
int min_rates_total;
//--- ���������� ������������� ���������� ��� ������� �����������
int Ind_Handle;
//+------------------------------------------------------------------+
//|  ��������� ���������� � ���� ������                              |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- �������� �������� �������� �� ������������
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame)) return(INIT_FAILED);
//--- ������������� ���������� 
   min_rates_total=2;
//--- ��������� ������ ���������� Karpenko
   Ind_Handle=iCustom(Symbol(),TimeFrame,"Karpenko",Basic_MA,History);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" �� ������� �������� ����� ���������� Karpenko");
      return(INIT_FAILED);
     }
//--- ������������� ������������ �������
   IndInit(0,UpIndBuffer,INDICATOR_DATA);
   IndInit(1,DnIndBuffer,INDICATOR_DATA);
//--- ������������� �����������
   PlotInit(0,0.0,0,Shift);
//--- �������� ����� ��� ����������� � ��������� ������� � �� ����������� ���������
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- ����������� �������� ����������� �������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- ���������� �������������
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
   if(rates_total<min_rates_total) return(RESET);
   if(BarsCalculated(Ind_Handle)<Bars(Symbol(),TimeFrame)) return(prev_calculated);
//--- ���������� ��������� � �������� ��� � ����������  
   ArraySetAsSeries(time,true);
//---
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,UpIndBuffer,1,DnIndBuffer,time,rates_total,prev_calculated,min_rates_total))
      return(RESET);
//---     
   return(rates_total);
  }
//---
//+------------------------------------------------------------------+
//| ������������� ������������� ������                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],ENUM_INDEXBUFFER_TYPE Type)
  {
//--- ����������� ������������� ������� � ������������ �����
   SetIndexBuffer(Number,Buffer,Type);
//--- ���������� ��������� � ������ ��� � ���������
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| ������������� ����������                                         |
//+------------------------------------------------------------------+    
void PlotInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//--- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- ��������� �������� ����������, ������� �� ����� ������ �� �������
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- ������������� ������ ���������� �� ����������� �� Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//---
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // ����� ������� CountLine �� ������ � ���� ���������� (��������� ����� - 0)
                    string   Symb,            // ������ �������
                    ENUM_TIMEFRAMES TFrame,   // ������ �������
                    int      IndHandle,       // ����� ��������������� ����������
                    uint     UpBuffNumb,      // ����� �������� ������ ��������������� ���������� ��� ������
                    double&  UpIndBuf[],      // �������� ������� ����� ���������� ��� ������
                    uint     DnBuffNumb,      // ����� ������� ������ ��������������� ���������� ��� ������
                    double&  DnIndBuf[],      // �������� ������ ����� ���������� ��� ������
                    const datetime& iTime[],  // ��������� �������
                    const int Rates_Total,    // ���������� ������� � ����� �� ������� ����
                    const int Prev_Calculated,// ���������� ������� � ����� �� ���������� ����
                    const int Min_Rates_Total)// ����������� ���������� ������� � ����� ��� �������
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- ������� ������������ ���������� ���������� ������
//--- � ���������� ������ limit ��� ����� ��������� �����
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// �������� �� ������ ����� ������� ����������
     {
      limit=Rates_Total-Min_Rates_Total-1; // ��������� ����� ��� ������� ���� �����
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // ��������� ����� ��� ������� ����� ����� 
//--- �������� ���� ������� ����������
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- �������� ����� ����������� ������ � ������ IndTime
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);

      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double UpArr[1],DnArr[1];
         //--- �������� ����� ����������� ������ � �������
         if(CopyBuffer(IndHandle,UpBuffNumb,iTime[bar],1,UpArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,DnBuffNumb,iTime[bar],1,DnArr)<=0) return(RESET);

         UpIndBuf[bar]=UpArr[0];
         DnIndBuf[bar]=DnArr[0];
        }
      else
        {
         UpIndBuf[bar]=UpIndBuf[bar+1];
         DnIndBuf[bar]=DnIndBuf[bar+1];
        }
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame) //������ ������� ���������� (���������)
  {
//--- �������� �������� �������� �� ������������
   if(TFrame<Period() && TFrame!=PERIOD_CURRENT)
     {
      Print("������ ������� ��� ���������� "+IndName+" �� ����� ���� ������ ������� �������� �������!");
      Print("������� �������� ������� ��������� ����������!");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
