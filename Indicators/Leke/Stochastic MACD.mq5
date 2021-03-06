//------------------------------------------------------------------
#property copyright   "© mladen, 2020"
#property link        "mladenfx@gmail.com"
#property version     "1.00"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_width1  2
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCoral
#property indicator_style2  STYLE_DOT

//
//---
//

input int                inpStoPeriod  = 45;          // Stochastic period
input int                inpFastPeriod = 12;          // Fast period
input int                inpSlowPeriod = 26;          // Slow period
input int                inpSignPeriod = 9;           // Signal period
input ENUM_APPLIED_PRICE inpPrice      = PRICE_CLOSE; // Price
input double             inpLevelOb    =  10;         // Ovberbought level
input double             inpLevelOs    = -10;         // Ovbersold level

double  val[],vals[]; int _minmaxPeriod;

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

int OnInit()
{
   SetIndexBuffer(0,val ,INDICATOR_DATA);
   SetIndexBuffer(1,vals,INDICATOR_DATA);

   //
   //
   //
      
      _minmaxPeriod = MathMax(inpStoPeriod-1,1);
         iFast.OnInit(inpFastPeriod);
         iSlow.OnInit(inpSlowPeriod);
         iSignal.OnInit(inpSignPeriod);
      IndicatorSetInteger(INDICATOR_LEVELS,2);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,0,inpLevelOb);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,1,inpLevelOs);
      
      //
      //
      //
      
   IndicatorSetString(INDICATOR_SHORTNAME,"Stochastic MACD ("+(string)inpFastPeriod+","+(string)inpSlowPeriod+","+(string)inpSignPeriod+","+(string)inpStoPeriod+")");
   return(INIT_SUCCEEDED);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

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
   int limit = prev_calculated-1; if (limit<0) limit=0;
         static datetime prev_time=0;
         static double   prev_max,prev_min;

   //
   //---
   //
  
   for(int i=limit; i<rates_total && !_StopFlag; i++)
   {
      if (prev_time != time[i])
      {
            prev_time = time[i];
            int start = i-inpStoPeriod+1; if (start<0) start=0;
                prev_max = high[ArrayMaximum(high,start,_minmaxPeriod)];
                prev_min = low [ArrayMinimum(low ,start,_minmaxPeriod)];
      }
      
      //
      //
      //
      
      double prc=0;
         switch(inpPrice)
         {
            case PRICE_CLOSE:    prc =  close[i];                              break;
            case PRICE_OPEN:     prc =  open[i];                               break;
            case PRICE_HIGH:     prc =  high[i];                               break;
            case PRICE_LOW:      prc =  low[i];                                break;
            case PRICE_MEDIAN:   prc = (high[i]+low[i])/2.0;                   break;
            case PRICE_TYPICAL:  prc = (high[i]+low[i]+close[i])/3.0;          break;
            case PRICE_WEIGHTED: prc = (high[i]+low[i]+close[i]+close[i])/4.0; break;
         }
      double fastEma   = iFast.OnCalculate(prc,i,rates_total);
      double slowEma   = iSlow.OnCalculate(prc,i,rates_total);
      double max       = (high[i]>prev_max) ? high[i] : prev_max;
      double min       = (low[i] <prev_min) ? low[i]  : prev_min;
      double fastStoch = (max!=min) ? (fastEma-min)/(max-min) : 0;
      double slowStoch = (max!=min) ? (slowEma-min)/(max-min) : 0;

      //
      //
      //
         
      val[i]  = 100.0*(fastStoch-slowStoch);
      vals[i] = iSignal.OnCalculate(val[i],i,rates_total);
   }
   return(rates_total);
}

 
//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//

class CEma
{
   private :
         double m_alpha;
         double m_period;
         double m_array[];
         int    m_arraySize;
   public :
      CEma() : m_alpha(1), m_arraySize(-1), m_period(1) {}
     ~CEma()                                            {}
     
      //
      //---
      //
     
      void OnInit(double period)
         {
            m_period = (period>1) ? period : 1;
            m_alpha  = 2.0/(1.0+m_period);
         }
      double OnCalculate(double value, int i, int bars)
         {
            if (m_arraySize<bars) m_arraySize=ArrayResize(m_array,bars+500);
            
            //
            //
            //
            
            if (i>0)
                    m_array[i] = m_array[i-1]+m_alpha*(value-m_array[i-1]); 
            else    m_array[i] = value;
            return (m_array[i]);
         }   
};
CEma iFast,iSlow,iSignal;