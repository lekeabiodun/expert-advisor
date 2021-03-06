//------------------------------------------------------------------
#property copyright   "© mladen, 2019"
#property link        "mladenfx@gmail.com"
#property description "RSI combined with CCI for confirmation"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'220,235,220',C'235,220,220'
#property indicator_width2  2
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDarkGray,clrMediumSeaGreen,clrDeepPink
#property indicator_width2  2

//
//--- input parameters
//

input int                inpPeriod = 32;            // RSI and CCI period
input ENUM_APPLIED_PRICE inpPrice  = PRICE_TYPICAL; // Price

//
//--- indicator buffers
//

double val[],valc[],fillu[],filld[],cci[]; 
int  _rsiHandle,_cciHandle,_rsiPeriod; 

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------

int OnInit()
{
   //
   //--- indicator buffers mapping
   //
         SetIndexBuffer(0,fillu,INDICATOR_DATA);
         SetIndexBuffer(1,filld,INDICATOR_DATA);
         SetIndexBuffer(2,val  ,INDICATOR_DATA);
         SetIndexBuffer(3,valc ,INDICATOR_COLOR_INDEX);
         SetIndexBuffer(4,cci  ,INDICATOR_CALCULATIONS); PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
         
         _rsiPeriod   = (inpPeriod>1) ? inpPeriod : 1;
         _rsiHandle   = iRSI(_Symbol,0,_rsiPeriod,inpPrice); if (!_checkHandle(_rsiHandle,"RSI")) return(INIT_FAILED);
         _cciHandle   = iCCI(_Symbol,0,_rsiPeriod,inpPrice); if (!_checkHandle(_cciHandle,"CCI")) return(INIT_FAILED);
   //         
   //--- indicator short name assignment
   //
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI + CCI("+(string)inpPeriod+")");
   return (INIT_SUCCEEDED);
}
void OnDeinit(const int reason) {}

//------------------------------------------------------------------
// Custom indicator iteration function
//------------------------------------------------------------------
//
//---
//

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int _copyCount = rates_total-prev_calculated+1; if (_copyCount>rates_total) _copyCount=rates_total;
         if (CopyBuffer(_rsiHandle,0,0,_copyCount,val)!=_copyCount) return(prev_calculated);
         if (CopyBuffer(_cciHandle,0,0,_copyCount,cci)!=_copyCount) return(prev_calculated);

   //
   //---
   //
   
   int i= prev_calculated-1; if (i<0) i=0; for (; i<rates_total && !_StopFlag; i++)
   {
      valc[i]  = (cci[i]>80) ? 1 :(cci[i]<-80) ? 2 : 0;
      switch ((int)valc[i])
      {
         case 0 : fillu[i] = 50; filld[i] =  50; break;
         case 1 : fillu[i] = 100; filld[i] =  0; break;
         case 2 : filld[i] = 100; fillu[i] =  0; break;
      }         
   }
   return(i);
}

//------------------------------------------------------------------
// Custom function(s)
//------------------------------------------------------------------
//
//---
//

bool _checkHandle(int _handle, string _description)
{
   static int  _chandles[];
          int  _size   = ArraySize(_chandles);
          bool _answer = (_handle!=INVALID_HANDLE);
          if  (_answer)
               { ArrayResize(_chandles,_size+1); _chandles[_size]=_handle; }
          else { for (int i=_size-1; i>=0; i--) IndicatorRelease(_chandles[i]); ArrayResize(_chandles,0); Alert(_description+" initialization failed"); }
   return(_answer);
}  
//------------------------------------------------------------------