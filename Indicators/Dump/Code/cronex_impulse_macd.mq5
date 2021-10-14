//+------------------------------------------------------------------+ 
//|                                          Cronex_Impulse_MACD.mq5 | 
//|                                        Copyright © 2007, Cronex. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2008, Cronex"
#property  link      "http://www.metaquotes.net/"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов 4
#property indicator_buffers 4 
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки индикатора 1             |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветов индикатора использованы
#property indicator_color1  clrLime,clrRed
//---- отображение метки индикатора
#property indicator_label1  "Cronex_Impulse_MACD Signal"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 2             |
//+----------------------------------------------+
//---- отрисовка индикатора в виде четырехцветной гистограммы
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//---- в качестве цветов пятицветной гистограммы использованы
#property indicator_color2 clrMediumVioletRed,clrViolet,clrGray,clrDeepSkyBlue,clrBlue
//---- линия индикатора - сплошная
#property indicator_style2 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width2 2
//---- отображение метки индикатора
#property indicator_label2  "Cronex_Impulse_MACD"
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint Master_MA=34;  // Период усреднения MACD
input uint Signal_MA=9;   // Период сигнальной линии 
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
double UpBuffer[],DnBuffer[];
//---- объявление целочисленных переменных для хендлов индикаторов
int MAh_Handle,MAl_Handle,MAw_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_1;
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_1=int(Master_MA+1);
   min_rates_total=int(min_rates_1+Signal_MA+1);
//---- получение хендла индикатора iMA 1
   MAh_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_HIGH);
   if(MAh_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA 1");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора iMA 2
   MAl_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_LOW);
   if(MAl_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA 2");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора iMA 3
   MAw_Handle=iMA(NULL,0,Master_MA,0,MODE_SMA,PRICE_WEIGHTED);
   if(MAw_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA 3");
      return(INIT_FAILED);
     }
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpBuffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnBuffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,IndBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(3,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorIndBuffer,true);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Cronex_Impulse_MACD(",Master_MA,", ",Signal_MA,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| MACD iteration function                                          | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(MAh_Handle)<rates_total
      || BarsCalculated(MAl_Handle)<rates_total
      || BarsCalculated(MAw_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//---- объявления локальных переменных 
   int to_copy,limit,bar;
   double MAh[],MAl[],MAw[];
//---- расчеты необходимого количества копируемых данных и
//---- стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_1-1; // стартовый номер для расчета всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }
//----
   to_copy=limit+1; // расчетное количество всех баров  
//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(MAh_Handle,0,0,to_copy,MAh)<=0) return(RESET);
   if(CopyBuffer(MAl_Handle,0,0,to_copy,MAl)<=0) return(RESET);
   if(CopyBuffer(MAw_Handle,0,0,to_copy,MAw)<=0) return(RESET);
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(MAh,true);
   ArraySetAsSeries(MAl,true);
   ArraySetAsSeries(MAw,true);
//---- основной цикл расчета индикатора
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
//---- основной цикл раскраски индикатора Ind
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
