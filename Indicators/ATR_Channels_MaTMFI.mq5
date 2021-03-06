//+---------------------------------------------------------------------+
//|                                             ATR_Channels_MaTMFI.mq5 |
//|                            Copyright © 2005, Luis Guilherme Damiani |
//|                                         http://www.damianifx.com.br |
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2005, Luis Guilherme Damiani"
#property link      "http://www.damianifx.com.br"
#property description "ATR_Channels_MaTMFI"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов
#property indicator_buffers 9
//---- использовано всего восемь графических построений
#property indicator_plots   8
//+--------------------------------------------------+
//| Параметры отрисовки индикатора MaTMFI            |
//+--------------------------------------------------+
//---- отрисовка индикатора 1 в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветjd индикатора использованы
#property indicator_color1  clrSpringGreen,clrMagenta
//---- отображение бычей метки индикатора
#property indicator_label1  "MaTMFI;Trigger"
//+--------------------------------------------------+
//|  Параметры отрисовки индикатора                  |
//+--------------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета линии индикатора использован сине-фиолетовый цвет
#property indicator_color2 clrBlueViolet
//---- линия индикатора - сплошная линия
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора равна 1
#property indicator_width2  1
//---- отображение метки индикатора
#property indicator_label2  "ATR"
//+--------------------------------------------------+
//|  Параметры отрисовки индикатора Envelope уровней |
//+--------------------------------------------------+
//---- отрисовка уровней в виде линий
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_LINE
//---- выбор цветов уровней
#property indicator_color3  clrPurple
#property indicator_color4  clrRed
#property indicator_color5  clrBlue
#property indicator_color6  clrBlue
#property indicator_color7  clrRed
#property indicator_color8  clrPurple
//---- уровни - штрихпунктирные кривые
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_DASHDOTDOT
#property indicator_style5 STYLE_DASHDOTDOT
#property indicator_style6 STYLE_DASHDOTDOT
#property indicator_style7 STYLE_DASHDOTDOT
#property indicator_style8 STYLE_DASHDOTDOT
//---- толщина уровней равна 1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
//---- отображение меток уровней
#property indicator_label3  "+3 Envelope"
#property indicator_label4  "+2 Envelope"
#property indicator_label5  "+1 Envelope"
#property indicator_label6  "-1 Envelope"
#property indicator_label7  "-2 Envelope"
#property indicator_label8  "-3 Envelope"
//+-----------------------------------+
//| объявление констант               |
//+-----------------------------------+
#define RESET 0                    // Константа для возврата терминалу команды на пересчет индикатора
//+-----------------------------------+
//|  Описание классов усреднений      |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA;
//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
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
//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
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
   MODE_AMA,   //AMA
  }; */
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input uint TMFIPeriod=10;                                //период TMFI
input uint   ATRPeriod=18;
input double Mult_Factor1=10000;
input double Mult_Factor2=20000;
input double Mult_Factor3=30000;
input Smooth_Method XMA_Method=MODE_JJMA;                //метод сглаживания
input int XLength=5;                                     //глубина сглаживания                    
input int XPhase=15;                                     //параметр сглаживания,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
//----
input Smooth_Method XMA_Method1=MODE_SMA_;               //метод усреднения
input uint XLength1=100;                                 //глубина усреднения                
input int XPhase1=15;                                    //параметр усреднения,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE_;                   //ценовая константа
  input ENUM_APPLIED_VOLUME VolumeType=VOLUME_TICK;      //объём
input int Shift=0; // сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в дальнейшем использованы в качестве индикаторных буферов
double UpIndBuffer[],DnIndBuffer[],ExtLineBuffer0[];
double ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[];
double ExtLineBuffer4[],ExtLineBuffer5[],ExtLineBuffer6[];
//---- Объявление переменной для хранения хендла индикатора
int ATR_Handle,MaTMFI_Handle;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_MaTMFI,min_rates_XMA,min_rates_total,min_rates_1;
//+------------------------------------------------------------------+   
//| ATR Channels indicator initialization function                   | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора MaTMFI
   MaTMFI_Handle=iCustom(NULL,PERIOD_CURRENT,"MaTMFI",TMFIPeriod,XMA_Method,XLength,XPhase,IPC,VolumeType,0);
   if(MaTMFI_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора MaTMFI");
      return(INIT_FAILED);
     }
//---- Инициализация переменных начала отсчёта данных
   min_rates_MaTMFI=int(TMFIPeriod)+1;
   min_rates_XMA=min_rates_MaTMFI+GetStartBars(XMA_Method,XLength,XPhase);   
   min_rates_1=min_rates_XMA+GetStartBars(XMA_Method1,XLength1,XPhase1);   
   min_rates_total=min_rates_1+int(ATRPeriod);

//---- установка алертов на недопустимые значения внешних переменных
   XMA.XMALengthCheck("XLength",XLength);
   XMA.XMAPhaseCheck("XPhase",XPhase,XMA_Method);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,UpIndBuffer,INDICATOR_DATA);
//---- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(UpIndBuffer,true);
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(1,DnIndBuffer,INDICATOR_DATA);
//---- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(DnIndBuffer,true);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- запрет на отображение значений индикатора в левом верхнем углу окна индикатора
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,ExtLineBuffer0,INDICATOR_DATA);
//---- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(ExtLineBuffer0,true);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(3,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(5,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(7,ExtLineBuffer5,INDICATOR_DATA);
   SetIndexBuffer(8,ExtLineBuffer6,INDICATOR_DATA);
//---- установка позиции, с которой начинается отрисовка уровней
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- запрет на отображение значений индикатора в левом верхнем углу окна индикатора
   PlotIndexSetInteger(1,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(2,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(3,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(4,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(5,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(6,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(7,PLOT_SHOW_DATA,false);
//---- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);
   ArraySetAsSeries(ExtLineBuffer3,true);
   ArraySetAsSeries(ExtLineBuffer4,true);
   ArraySetAsSeries(ExtLineBuffer5,true);
   ArraySetAsSeries(ExtLineBuffer6,true);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth=XMA.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"ATR_Channels_MaTMFI(",TMFIPeriod,",",XLength,",",Smooth,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| ATR Channels iteration function                                  | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(MaTMFI_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- Объявление переменных с плавающей точкой  
   double mfi,xmfi,Range[];
//---- Объявление целых переменных и получение уже посчитанных баров
   int to_copy,limit,bar;
   int maxbar=rates_total-1-min_rates_MaTMFI;

//---- расчёты необходимого количества копируемых данных и стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=maxbar; // расчётное количество всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
     }
   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массив Range[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(RESET);
//---- копируем вновь появившиеся данные в индикаторные буферы
   if(CopyBuffer(MaTMFI_Handle,0,0,to_copy,UpIndBuffer)<=0) return(RESET);
   if(CopyBuffer(MaTMFI_Handle,1,0,to_copy,DnIndBuffer)<=0) return(RESET);

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(Range,true);

//---- Основной цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- делаем расчёт уровней ATR
      mfi=UpIndBuffer[bar];
      xmfi=XMA.XMASeries(maxbar-100,prev_calculated,rates_total,XMA_Method1,XPhase1,XLength1,mfi,bar,true);
      ExtLineBuffer0[bar]=xmfi;
      ExtLineBuffer1[bar]=xmfi+Range[bar]*Mult_Factor3;
      ExtLineBuffer2[bar]=xmfi+Range[bar]*Mult_Factor2;
      ExtLineBuffer3[bar]=xmfi+Range[bar]*Mult_Factor1;
      ExtLineBuffer4[bar]=xmfi-Range[bar]*Mult_Factor1;
      ExtLineBuffer5[bar]=xmfi-Range[bar]*Mult_Factor2;
      ExtLineBuffer6[bar]=xmfi-Range[bar]*Mult_Factor3;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
