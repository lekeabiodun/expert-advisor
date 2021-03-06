//+---------------------------------------------------------------------+
//|                                                    MaTMFI_Cloud.mq5 |
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
//---- для расчёта и отрисовки индикатора использовано шесть буферов
#property indicator_buffers 6
//---- использовано три графических построения
#property indicator_plots   3
//----
#property indicator_minimum 0
#property indicator_maximum 100
//+----------------------------------------------+
//| Параметры отрисовки верхнего облака          |
//+----------------------------------------------+
//---- отрисовка индикатора в виде облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета линии индикатора использован цвет C'230,255,255'
#property indicator_color1 C'230,255,255'
//---- отображение метки индикатора
#property indicator_label1  "Upper MaTMFI_Cloud"
//+----------------------------------------------+
//| Параметры отрисовки нижнего облака           |
//+----------------------------------------------+
//---- отрисовка индикатора в виде облака
#property indicator_type2   DRAW_FILLING
//---- в качестве цвета линии индикатора использован цвет C'255,230,255'
#property indicator_color2 C'255,230,255'
//---- отображение метки индикатора
#property indicator_label2  "Lower MaTMFI_Cloud"
//+----------------------------------------------+
//| Параметры отрисовки индикатора MaTMFI        |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде цветного облака
#property indicator_type3   DRAW_FILLING
//---- в качестве цветjd индикатора использованы
#property indicator_color3  clrSpringGreen,clrMagenta
//---- отображение бычей метки индикатора
#property indicator_label3  "MaTMFI;Trigger"
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
input uint HighLevel=60;                                 //уровень перекупленности
input uint MiddleLevel=50;                               //серелина диапазона
input uint LowLevel=40;                                  //уровень перепроданности
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в дальнейшем использованы в качестве индикаторных буферов
double UpUpBuffer[],UpDnBuffer[],DnUpBuffer[],DnDnBuffer[];
double MaTMFIBuffer[],SignalBuffer[];
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

//--- инициализация индикаторных буферов  
   IndInit(0,UpUpBuffer,INDICATOR_DATA);
   IndInit(1,UpDnBuffer,INDICATOR_DATA);
//--- инициализация индикаторов
   PlotInit(0,EMPTY_VALUE,min_rates_total,Shift);
//--- инициализация индикаторных буферов  
   IndInit(2,DnUpBuffer,INDICATOR_DATA);
   IndInit(3,DnDnBuffer,INDICATOR_DATA);
//--- инициализация индикаторов
   PlotInit(1,EMPTY_VALUE,min_rates_total,Shift); 
//----
//--- инициализация индикаторных буферов  
   IndInit(4,MaTMFIBuffer,INDICATOR_DATA);
   IndInit(5,SignalBuffer,INDICATOR_DATA);
//--- инициализация индикаторов
   PlotInit(2,EMPTY_VALUE,min_rates_total,Shift); 

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"MaTMFI_Cloud(",TMFIPeriod,", ",Smooth,", ",XLength,", ",XPhase,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   
//---- параметры отрисовки уровней индикатора
   IndicatorSetInteger(INDICATOR_LEVELS,3);
//---- значения горизонтальных уровней индикатора   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,MathMax(MathMin(100,HighLevel),0));
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,MathMin(MathMax(0,MiddleLevel),100));
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,MathMin(MathMax(0,LowLevel),100));
//---- в качестве цветов линий горизонтальных уровней использованы 
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrMagenta);
//---- в линии горизонтального уровня использован короткий штрих-пунктир  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_SOLID);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_SOLID);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//----
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],ENUM_INDEXBUFFER_TYPE Type)
  {
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(Number,Buffer,Type);
//---
  }
//+------------------------------------------------------------------+
//| Инициализация индикатора                                         |
//+------------------------------------------------------------------+    
void PlotInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//---- запрет на отображение значений индикатора в левом верхнем углу окна индикатора
   PlotIndexSetInteger(Number,PLOT_SHOW_DATA,false);
//---
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
      
      UpUpBuffer[bar]=100;
      UpDnBuffer[bar]=double(HighLevel);
      //----      
      DnUpBuffer[bar]=double(LowLevel);
      DnDnBuffer[bar]=0;
      //---- 

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
