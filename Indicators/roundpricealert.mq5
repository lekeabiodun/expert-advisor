//+------------------------------------------------------------------+ 
//|                                              RoundPriceAlert.mq5 | 
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2011, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru"
//---- indicator version number
#property version   "1.00"
#property description "Sound signal of rounded price value"
//---- drawing the indicator in the main window
#property indicator_chart_window

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input bool On_Push = false;                        //allow to send push-messages
input bool On_Email = false;                       //allow to send e-mail messages
input bool On_Alert = true;                        //allow to put alert
input bool On_Play_Sound = false;                  //allow to put sound signal
input string NameFileSound = "expert.wav";         //name of the file with sound
input string  CommentSirName="RoundPriceAlert: ";  //the first part of the allert comment
input uint RoundDigits=3;                          //nuber of zeros in the digits
input uint SignalPause=5;                          //pause between the signals in minutes
//+-----------------------------------+
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
double ratio,power;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=2;
   power=MathPow(10,RoundDigits);
   ratio=_Point*power;
   
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname="RoundPriceAlert";
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- put the comment about indicator on the chart
   Comment(shortname);
//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- end of initialization
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
  {
//---- revove comment about indicator from the chart
   Comment("");
//----
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(0);

//----
   static double LastRes;
   static datetime LastSignalTime;
//---- 
   datetime SignalTime=TimeCurrent();
   double Price=Close[rates_total-1];
   double Res=MathFloor(Price/ratio);

   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      LastRes=Res;
      LastSignalTime=SignalTime;
     }
     
   int dTime=int((SignalTime-LastSignalTime)/60);

   if(LastRes!=Res && dTime>int(SignalPause))
     {
      if(On_Play_Sound) PlaySound(NameFileSound);     
      string comment,sTime=" CurrTime="+TimeToString(SignalTime,TIME_MINUTES);
      StringConcatenate(comment,CommentSirName,Symbol(),sTime," The price breakthrough the level ",DoubleToString(Res*ratio,_Digits),"!");   
      if(On_Alert) Alert(comment);
      if(On_Push) SendNotification(comment);
      if(On_Email) SendMail(CommentSirName+Symbol(),comment);     
      LastSignalTime=SignalTime;
      LastRes=Res;
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
