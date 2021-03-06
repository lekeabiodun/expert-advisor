//+---------------------------------------------------------------------+
//|                                                          MaTMFI.mq5 |
//|                    Copyright © 2010,   VladMsk, contact@mqlsoft.com |
//|                                             http://www.becemal.ru// |
//+---------------------------------------------------------------------+
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+

//---- авторство индикатора
#property copyright "Copyright © 2010, VladMsk, contact@mqlsoft.com"
//---- авторство индикатора
#property link      "http://www.becemal.ru/"
//---- описание индикатора
#property description "True MFI. Based on code MFI.mq4"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- для расчёта и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки индикатора MaTMFI        |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета бычей линии индикатора использован Teal цвет
#property indicator_color1  clrTeal
//---- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//---- отображение бычей метки индикатора
#property indicator_label1  "MaTMFI"
//+----------------------------------------------+
//| Параметры отрисовки индикатора Trigger       |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета медвежьей линии индикатора использован Orange цвет
#property indicator_color2  clrOrange
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//---- отображение медвежьей метки индикатора
#property indicator_label2  "Signal"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 68.169011381620932846223247325497
#property indicator_level2 50.0
#property indicator_level3 31.830988618379067153776752674503
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET 0 // константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//|  Описание класса CXMA                        |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1,XMA2;
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
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
//|  объявление перечислений                     |
//+----------------------------------------------+
/*enum Smooth_Method - перечисление объявлено в файле SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA    //AMA
  }; */
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input uint TMFIPeriod=10;                                //период TMFI
input Smooth_Method XMA_Method=MODE_JJMA;                //метод сглаживания
input int XLength=5;                                     //глубина сглаживания                    
input int XPhase=15;                                     //параметр сглаживания,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE_;                   //ценовая константа
  input ENUM_APPLIED_VOLUME VolumeType=VOLUME_TICK;      //объём
input int Shift=0;                                       //сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double MaTMFIBuffer[];
double SignalBuffer[];
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- Объявление глобальных переменных
int Count[];
double Ma[];
//+------------------------------------------------------------------+
//|  Пересчет позиции самого нового элемента в массиве               |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Возврат по ссылке номера текущего значения ценового ряда
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(XMA1.GetStartBars(XMA_Method,TMFIPeriod,XPhase)+XMA1.GetStartBars(XMA_Method,XLength,XPhase)+4);

//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength", XLength);
   XMA1.XMAPhaseCheck("XPhase", XPhase, XMA_Method);
   
//---- Распределение памяти под массивы переменных  
   ArrayResize(Count,4);
   ArrayResize(Ma,4);
   ArrayInitialize(Count,NULL);
   ArrayInitialize(Ma,NULL);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,MaTMFIBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 2 на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"MaTMFI(",TMFIPeriod,", ",Smooth,", ",XLength,", ",XPhase,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(RESET);

//---- объявления локальных переменных 
   long Volume;
   int first,bar,bar1;
   double rel,negative,positive,sumn,sump,tmfi,price;
   static double negative_,positive_;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров
      negative_=50;
      positive_=50;
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- восстанавливаем значения переменных
   negative=negative_;
   positive=positive_;
   
   bar1=rates_total-2;

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      Ma[Count[0]]=XMA1.XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,TMFIPeriod,price,bar,false);
      
      if(bar<3){Recount_ArrayZeroPos(Count,4); continue;}
      
      sumn=0.0;
      sump=0.0;
      rel=Ma[Count[0]]-Ma[Count[3]]+8*Ma[Count[1]]-8*Ma[Count[2]];
      
       if(VolumeType==VOLUME_TICK) Volume=tick_volume[bar]+2*tick_volume[bar-1]+2*tick_volume[bar-2]+tick_volume[bar-3];
      else  Volume=volume[bar]+2*volume[bar-1]+2*volume[bar-2]+volume[bar-3];

      if(rel>0) sump+=double(Volume);
      else      sumn+=double(Volume);
      
      positive=(positive*(TMFIPeriod-1)+sump)/TMFIPeriod;
      negative=(negative*(TMFIPeriod-1)+sumn)/TMFIPeriod;

      if(negative) tmfi=100.0*(1.0-1.0/(1.0+positive/negative));
      else tmfi=50.0; 
      
      MaTMFIBuffer[bar]=tmfi;      
      SignalBuffer[bar]=XMA2.XMASeries(TMFIPeriod,prev_calculated,rates_total,XMA_Method,XPhase,XLength,tmfi,bar,false);

      //---- запоминаем значения переменных перед прогонами на текущем баре
      if(bar==bar1)
        {
         negative_=negative;
         positive_=positive;
        }
        
      if(bar<rates_total-1) Recount_ArrayZeroPos(Count,4);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
