//+------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "QQE - multi time frame version"
//+------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_label1  "QQE fast"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkGray
#property indicator_style1  STYLE_DOT
#property indicator_label2  "QQE slow"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkGray
#property indicator_label3  "QQE"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrDarkGray,clrDeepSkyBlue,clrLightSalmon
#property indicator_width3  2
//--- input parameters
enum enTimeFrames
  {
   tf_cu  = PERIOD_CURRENT, // Current time frame
   tf_m1  = PERIOD_M1,      // 1 minute
   tf_m2  = PERIOD_M2,      // 2 minutes
   tf_m3  = PERIOD_M3,      // 3 minutes
   tf_m4  = PERIOD_M4,      // 4 minutes
   tf_m5  = PERIOD_M5,      // 5 minutes
   tf_m6  = PERIOD_M6,      // 6 minutes
   tf_m10 = PERIOD_M10,     // 10 minutes
   tf_m12 = PERIOD_M12,     // 12 minutes
   tf_m15 = PERIOD_M15,     // 15 minutes
   tf_m20 = PERIOD_M20,     // 20 minutes
   tf_m30 = PERIOD_M30,     // 30 minutes
   tf_h1  = PERIOD_H1,      // 1 hour
   tf_h2  = PERIOD_H2,      // 2 hours
   tf_h3  = PERIOD_H3,      // 3 hours
   tf_h4  = PERIOD_H4,      // 4 hours
   tf_h6  = PERIOD_H6,      // 6 hours
   tf_h8  = PERIOD_H8,      // 8 hours
   tf_h12 = PERIOD_H12,     // 12 hours
   tf_d1  = PERIOD_D1,      // daily
   tf_w1  = PERIOD_W1,      // weekly
   tf_mn  = PERIOD_MN1,     // monthly
   tf_cp1 = -1,             // Next higher time frame
   tf_cp2 = -2,             // Second higher time frame
   tf_cp3 = -3              // Third higher time frame
  };
input enTimeFrames       inpTimeFrame          = tf_cu;       // Time frame
input int                inpRsiPeriod          = 14;          // RSI period
input int                inpRsiSmoothingFactor =  5;          // RSI smoothing factor
input double             inpWPFast             = 2.618;       // Fast period
input double             inpWPSlow             = 4.236;       // Slow period
input ENUM_APPLIED_PRICE inpPrice              = PRICE_CLOSE; // Price 
input bool               inpInterpolate        = true;        // Interpolate in multi time frame mode?
//--- buffers declarations
double val[],valc[],levs[],levf[],count[];
//--- mtf handling stuff
int     _mtfHandle=INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),tf_cu,inpRsiPeriod,inpRsiSmoothingFactor,inpWPFast,inpWPSlow,inpPrice)
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,levf,INDICATOR_DATA);
   SetIndexBuffer(1,levs,INDICATOR_DATA);
   SetIndexBuffer(2,val,INDICATOR_DATA);
   SetIndexBuffer(3,valc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,count,INDICATOR_CALCULATIONS);
   timeFrame=MathMax(timeFrameGet((int)inpTimeFrame),_Period);
   if(timeFrame!=_Period)
     {
      _mtfHandle = _mtfCall; if(_mtfHandle==INVALID_HANDLE) return(INIT_FAILED);
     }
//--- indicator short name assignment
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" QQE ("+(string)inpRsiPeriod+","+(string)inpRsiSmoothingFactor+")");
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator de-initialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);
   if(timeFrame!=_Period)
     {
      double result[];
      if(BarsCalculated(_mtfHandle)<0)                     return(prev_calculated);
      if(!timeFrameCheck((ENUM_TIMEFRAMES)timeFrame,time)) return(prev_calculated);
      if(CopyBuffer(_mtfHandle,4,0,1,result)==-1)          return(prev_calculated);

      //
      //---
      //

#define _mtfRatio PeriodSeconds((ENUM_TIMEFRAMES)timeFrame)/PeriodSeconds(_Period)
      int k,n,i=MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0)),_prevMark=0,_seconds=PeriodSeconds(timeFrame);
      for(; i<rates_total && !_StopFlag; i++)
        {
         int _currMark= int(time[i]/_seconds);
         if(_currMark!=_prevMark)
           {
            _prevMark=_currMark;
#define _mtfCopy(_buff,_buffNo) if(CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i]=result[0]
            _mtfCopy(levf,0);
            _mtfCopy(levs,1);
            _mtfCopy(val,2);
            _mtfCopy(valc,3);
           }
         else
           {
            levf[i] = levf[i-1];
            levs[i] = levs[i-1];
            val[i]  = val[i-1];
            valc[i] = valc[i-1];
           }

         //
         //---
         //

         if(!inpInterpolate) continue;
         int _nextMark=(i<rates_total-1) ? int(time[i+1]/_seconds) : _prevMark+1; if(_nextMark==_prevMark) continue;
         for(n=1; (i-n)> 0 && time[i-n] >= (_prevMark)*_seconds; n++) continue;
         for(k=1; (i-k)>=0 && k<n; k++)
           {
#define _mtfInterpolate(_buff) _buff[i-k]=_buff[i]+(_buff[i-n]-_buff[i])*k/n
            _mtfInterpolate(levf);
            _mtfInterpolate(levs);
            _mtfInterpolate(val);
           }
        }
      return(i);
     }
//
//---
//

   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      val[i]=iEma(iRsi(getPrice(inpPrice,open,close,high,low,i,rates_total),inpRsiPeriod,i,rates_total),inpRsiSmoothingFactor,i,rates_total,0);
      double _iEma = iEma((i>0 ? MathAbs(val[i-1]-val[i]) : 0),inpRsiPeriod,i,rates_total,1);
      double _iEmm = iEma(                               _iEma,inpRsiPeriod,i,rates_total,2);
      double _iEmf = _iEmm*inpWPFast;
      double _iEms = _iEmm*inpWPSlow;
      //
      //---
      //
        {
         double tr = (i>0) ? levs[i-1] : 0;
         double dv = tr;
         if(val[i] < tr) { tr = val[i] + _iEms; if((i>0 && val[i-1] < dv) && (tr > dv)) tr = dv; }
         if(val[i] > tr) { tr = val[i] - _iEms; if((i>0 && val[i-1] > dv) && (tr < dv)) tr = dv; }
         levs[i]=tr;
        }
        {
         double tr = (i>0) ? levf[i-1] : 0;
         double dv = tr;
         if(val[i] < tr) { tr = val[i] + _iEmf; if((i>0 && val[i-1] < dv) && (tr > dv)) tr = dv; }
         if(val[i] > tr) { tr = val[i] - _iEmf; if((i>0 && val[i-1] > dv) && (tr < dv)) tr = dv; }
         levf[i]=tr;
        }
      valc[i]=(val[i]>levf[i] && val[i]>levs[i]) ? 1 :(val[i]<levf[i] && val[i]<levs[i]) ? 2 :(i>0) ? valc[i-1]: 0;
     }
   count[rates_total-1]=MathMax(rates_total-prev_calculated+1,1);
   return (i);
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
#define rsiInstances 1
#define rsiInstancesSize 3
double workRsi[][rsiInstances*rsiInstancesSize];
#define _price  0
#define _change 1
#define _changa 2
//
//---
//
double iRsi(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(ArrayRange(workRsi,0)!=bars) ArrayResize(workRsi,bars);
   int z=instanceNo*rsiInstancesSize;

//
//
//
//
//

   workRsi[r][z+_price]=price;
   if(r<period)
     {
      int k; double sum=0; for(k=0; k<period && (r-k-1)>=0; k++) sum+=MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
      workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
      workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
     }
   else
     {
      double alpha=1.0/MathMax(period,1);
      double change=workRsi[r][z+_price]-workRsi[r-1][z+_price];
      workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(        change  - workRsi[r-1][z+_change]);
      workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
     }
   return(50.0*(workRsi[r][z+_change]/MathMax(workRsi[r][z+_changa],DBL_MIN)+1));
  }
//
//---
//
double workEma[][3];
//
//---
//
double iEma(double price,double period,int r,int bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=bars) ArrayResize(workEma,bars);

//
//---
//

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+2.0/(1.0+period)*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }

//
//---
//  
ENUM_TIMEFRAMES _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string          _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
//
//---
//
string timeFrameToString(int period)
  {
   if(period==PERIOD_CURRENT)
      period=_Period;
   int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);
  }
//
//---
//
ENUM_TIMEFRAMES timeFrameGet(int period)
  {
   int _shift=(period<0?MathAbs(period):0);
   if(_shift>0 || period==tf_cu) period=_Period;
   int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;

   return(_tfsPer[(int)MathMin(i+_shift,ArraySize(_tfsPer)-1)]);
  }
//
//---
//
string getIndicatorName()
  {
   string _path=MQL5InfoString(MQL5_PROGRAM_PATH);
   string _partsA[];
   ushort _partsS=StringGetCharacter("\\",0);
   int _partsN = StringSplit(_path,_partsS,_partsA);
   string name = _partsA[_partsN-1]; for(int n=_partsN-2; n>=0 && _toLower(_partsA[n])!="indicators"; n--) name = _partsA[n]+"\\"+name;
   return(name);
  }
string _toLower(string _toConvert) { StringToLower(_toConvert); return(_toConvert); }
//
//---
//
bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame,const datetime &time[])
  {
   static bool warned=false;
   if(time[0]<SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE))
     {
      datetime startTime,testTime[];
      if(SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,startTime))
      if(startTime>0)                       { CopyTime(_Symbol,_timeFrame,time[0],1,testTime); SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE,startTime); }
      if(startTime<=0 || startTime>time[0]) { Comment(MQL5InfoString(MQL5_PROGRAM_NAME)+"\nMissing data for "+timeFrameToString(_timeFrame)+" time frame\nRe-trying on next tick"); warned=true; return(false); }
     }
   if(warned) { Comment(""); warned=false; }
   return(true);
  }
//
//---
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
