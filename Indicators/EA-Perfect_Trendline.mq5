//+------------------------------------------------------------------+
//|                                         EA-Perfect_Trendline.mq5 |
//|                                    Copyright 2020, Master_Forex. |
//|                       https://www.mql5.com/en/users/Master_Forex |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Master_Forex."
#property link      "https://www.mql5.com/en/users/Master_Forex"
#property version   "1.00" 
#property description "Created - 25.02.2020 22:03"   
#property description " "
#property description "Customer: Brian Sinclair  ( https://www.mql5.com/en/users/briansinclair )"

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
#include <Trade/Trade.mqh>
 
enum rl     
{
 l1=0,             //Fixed Lot
 l2=1,             //Risk % of Balance 
};

input double inpFastLength   = 3;      // Fast length
input double inpSlowLength   = 7;      // Slow length
input int    Magic           = 1234;   // Magic Number
input bool   UseAddEntries   = 1;      // Use Additional Entries
input ENUM_TIMEFRAMES TF     = PERIOD_CURRENT;//Time Frame 
input rl     LotType         = 0;      // Risk of Balance or Fixed Lot
input double LotOrRisk       = 0.01;   // Lot size or Risk %   
input string Time_Start      = "03:00";// Start time
input string Time_End        = "23:55";// End time 
input bool   Reverse         = 0;      // Reverse Signals
input bool   UseTP           = 0;      // Use Fixed Take Profit
input double TakeProfit      = 0;      // Take Profit 
input bool   UseSL           = 0;      // Use Stop Loss 
input double StopLoss        = 0;      // Stop Loss    
input bool   UseTrailingStop = 0;      // Use Trailing Stop
input uint	 TSStop				   = 0;      // Trailing Stop      
input bool   UseBreakeven    = 0;      // Use Break Even
input double BEStart         = 0;      // Break Even  
input bool   CloseOpposite   = 1;      // Close on opposite signal    

//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
int PT, sh=1;datetime TimeNow, buy, sell;bool Buy=0, Sell=0;string EAComment="EA-Perfect_Trendline";  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{  
//--- getting the handle of the Perfect trend line indicator
   PT=iCustom(_Symbol,TF,"Perfect_Trend_Line_2",inpFastLength,inpSlowLength);
   if(PT==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Perfect trend line indicator");
      return(INIT_FAILED); 
     }              
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{  
   return; 
} 
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{    
   double up[3], dn[3], arr[3];      
//--- go trading only for first ticks of new bar
   
   if(CopyBuffer(PT,5,sh,3,up)<=-2) return; 
   
   if(CopyBuffer(PT,6,sh,3,dn)<=-2) return;
   
   if(CopyBuffer(PT,7,sh,3,arr)<=-2) return; 
           
//--- 
    
   Buy  = (MathMax(up[2],dn[2]) < iOpen(NULL,TF,sh) && MathMax(up[1],dn[1]) >= iOpen(NULL,TF,sh+1));  
   
   Sell = (MathMin(up[2],dn[2]) > iOpen(NULL,TF,sh) && MathMin(up[1],dn[1]) <= iOpen(NULL,TF,sh+1));    
   
//---  
   if(CloseOpposite){ int total = PositionsTotal();  
 
   for(int i=0; i<total; i++)
      { 
       ulong  position_ticket=PositionGetTicket(i);  
       ulong  magic=PositionGetInteger(POSITION_MAGIC);  
       ENUM_POSITION_TYPE ePositionType=(ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);   
       double vol=PositionGetDouble(POSITION_VOLUME);  
       string symbol=PositionGetString(POSITION_SYMBOL);  
       
       if(magic==Magic && symbol==_Symbol)
         { 
			    bool ExitSingle = false;

			    if(ePositionType == POSITION_TYPE_BUY) ExitSingle = (((Reverse && Buy) || (!Reverse && Sell)));
				
		      if(ePositionType == POSITION_TYPE_SELL) ExitSingle = (((!Reverse && Buy) || (Reverse && Sell)));
 		   
			    if(ExitSingle)
		  	    {
				     Print("Exit by opposite signal"); ClosePosition(_Symbol);} 
			      }	 	  			      				     
         }
      }	                
//---- Getting buy signals
   if(TimeFilter() && ((!Reverse && Buy) || (Reverse && Sell)) && arr[2] != EMPTY_VALUE && buy < iTime(NULL,TF,0))
     {          
      if(Positions() < 1) MarketOrder(_Symbol, POSITION_TYPE_BUY, Lots(), 0, 0, 0, Magic, 10, EAComment); buy=iTime(NULL,TF,0);       
     }   
//---- Getting sell signals
   if(TimeFilter() && ((Reverse && Buy) || (!Reverse && Sell)) && arr[2] != EMPTY_VALUE && sell < iTime(NULL,TF,0))
     {
      if(Positions() < 1) MarketOrder(_Symbol, POSITION_TYPE_SELL, Lots(), 0, 0, 0, Magic, 10, EAComment); sell=iTime(NULL,TF,0); 
     }     
//---- Getting buy signals
   if(UseAddEntries && TimeFilter() && ((!Reverse && Buy) || (Reverse && Sell)) && arr[2] == EMPTY_VALUE && buy < iTime(NULL,TF,0))
     {          
      if(Positions() > 0) MarketOrder(_Symbol, POSITION_TYPE_BUY, Lots(), 0, 0, 0, Magic, 10, EAComment); buy=iTime(NULL,TF,0);       
     }   
//---- Getting sell signals
   if(UseAddEntries && TimeFilter() && ((Reverse && Buy) || (!Reverse && Sell)) && arr[2] == EMPTY_VALUE && sell < iTime(NULL,TF,0))
     {
      if(Positions() > 0) MarketOrder(_Symbol, POSITION_TYPE_SELL, Lots(), 0, 0, 0, Magic, 10, EAComment); sell=iTime(NULL,TF,0); 
     } 
//---
	 if(Positions() > 0)
	   { 
	    double tp=TakeProfit, sl=StopLoss;   
	   
	    if((UseTP || UseSL) && (sl > 0 || tp > 0)) InitialSLTP(_Symbol, sl, tp); 
	    if(UseTrailingStop)	TrailingStop(_Symbol, TSStop);
	    if(UseBreakeven) BreakEven(_Symbol, BEStart);
	    if(Time_End != "00:00" && CloseTime(Time_End)) ClosePosition(Symbol());   
	   }           
//--- 

}
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Time Close                                                       |
//+------------------------------------------------------------------+
bool CloseTime(string t1)
{  
   long hs = StringToInteger(StringSubstr(t1, 0, 2)), ms = StringToInteger(StringSubstr(t1, 3, 2)); 
 
   if((TimeHour(TimeCurrent()) == hs && TimeMinute(TimeCurrent()) >= ms) || TimeHour(TimeCurrent()) > hs) return(true);
  
   return(false);   
}  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double Lots()
{  
   double lot=LotOrRisk;

   if(LotType==1 && LotOrRisk > 0){ lot=GetLotSize(AccountInfoDouble(ACCOUNT_BALANCE));}
   
   return RoundLot(_Symbol, lot);
}  
//+------------------------------------------------------------------+
//|  GetLotSize RPTrade                                              |
//+------------------------------------------------------------------+
double GetLotSize(double lotsize)
  {
//--- Gets pair specs  
   CSymbolInfo symInfo;
   int  digits_bn=symInfo.Digits();
   double  points_bn=symInfo.Point();
   string symbol_bn=_Symbol;
//--- adjust lot 
   int tmpdecimal=1;
   double old_lot=lotsize;
//---
   if((NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)*(LotOrRisk/100)/100.0,tmpdecimal)<lotsize)) //is lot fitting risk ?
     {
      lotsize=NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)*(LotOrRisk/100)/100.0,tmpdecimal);  //Calculates new Lotsize 

      if(lotsize<SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_MIN)) //is LotSize fitting minimum broker LotSize ?
        {
         lotsize=SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_MIN);   //No! Setting LotSize to minimum's broker LS
         Print(_Symbol," Lot adjusted from ",old_lot," to minimum size allowed by the server of ",lotsize);
        }
      else
        {
         Print(_Symbol," Lot adjusted from ",old_lot," to ",lotsize," to comply with Maximum Risk condition. Each trade can risk only ",LotOrRisk,"% of free margin.");   //Yes! 
         if(MathAbs(lotsize/SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_STEP)-MathRound(lotsize/SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_STEP)))>1.0E-10) //Is LotSize fitting Broker's allowed step ?
           {
            lotsize=SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_STEP)*NormalizeDouble(lotsize/SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_STEP),0);   //NO! recalculates LotSize.    
            Print("M-",_Symbol," Warning: Your calculated percentage at risk lot size of was not a multiple of minimal step",SymbolInfoDouble(symbol_bn,SYMBOL_VOLUME_STEP),". Lot size changed to",lotsize);
           }
        }
     }
   return(lotsize);
  }
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
bool MarketOrder(const string sSymbol, const ENUM_POSITION_TYPE eType, const double fLot, const double prices, const int nSL = 0, const int nTP = 0, const ulong nMagic = 0, const uint nSlippage = 1000, const string nComment = "")
{
	bool bRetVal = false;
	
	MqlTradeRequest oRequest = {0};
	MqlTradeResult	 oResult = {0};
	
	double fPoint = SymbolInfoDouble(sSymbol, SYMBOL_POINT);
	int nDigits	= (int) SymbolInfoInteger(sSymbol, SYMBOL_DIGITS);
   if(prices == 0){
	oRequest.action		= TRADE_ACTION_DEAL;}
   if(prices > 0){
	oRequest.action		= TRADE_ACTION_PENDING;}	
	oRequest.symbol		= sSymbol;
	oRequest.volume		= fLot;
	oRequest.stoplimit	= 0;
	oRequest.deviation	= nSlippage;
	oRequest.comment	= nComment;
	
	if(eType == POSITION_TYPE_BUY && prices == 0)
	{
		oRequest.type		= ORDER_TYPE_BUY;
		oRequest.price		= NormalizeDouble(SymbolInfoDouble(sSymbol, SYMBOL_ASK), nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price - nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price + nTP * fPoint, nDigits) * (nTP > 0);
	}
	
	if(eType == POSITION_TYPE_SELL && prices == 0)
	{
		oRequest.type		= ORDER_TYPE_SELL;
		oRequest.price		= NormalizeDouble(SymbolInfoDouble(sSymbol, SYMBOL_BID), nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price + nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price - nTP * fPoint, nDigits) * (nTP > 0);
	}
	if(eType == POSITION_TYPE_BUY && prices > 0)
	{
		oRequest.type		= ORDER_TYPE_BUY_LIMIT;
		oRequest.price		= NormalizeDouble(prices, nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price - nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price + nTP * fPoint, nDigits) * (nTP > 0);
	}
	
	if(eType == POSITION_TYPE_SELL && prices > 0)
	{
		oRequest.type		= ORDER_TYPE_SELL_LIMIT;
		oRequest.price		= NormalizeDouble(prices, nDigits);
		oRequest.sl			= NormalizeDouble(oRequest.price + nSL * fPoint, nDigits) * (nSL > 0);
		oRequest.tp			= NormalizeDouble(oRequest.price - nTP * fPoint, nDigits) * (nTP > 0);
	}	
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	{
		oRequest.type_filling = ORDER_FILLING_FOK;}
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	{		
		oRequest.type_filling = ORDER_FILLING_IOC;}
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==0)
	{	
		oRequest.type_filling = ORDER_FILLING_RETURN;
	}
   	//--- check filling
	if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)>2)
	{   	
   if(!FillingCheck(sSymbol))
      return(false);}
	oRequest.magic = nMagic;
	
	MqlTradeCheckResult oCheckResult= {0};
	
	bool bCheck = OrderCheck(oRequest, oCheckResult);

	Print("Order Check MarketOrder:",
			" OrderCheck = ",		bCheck,
			", retcode = ",		oCheckResult.retcode, 
			", balance = ",		NormalizeDouble(oCheckResult.balance, 2),
			", equity = ",			NormalizeDouble(oCheckResult.equity, 2),
			", margin = ",			NormalizeDouble(oCheckResult.margin, 2),
			", margin_free = ",	NormalizeDouble(oCheckResult.margin_free, 2),
			", margin_level = ",	NormalizeDouble(oCheckResult.margin_level, 2),
			", comment = ",		oCheckResult.comment);
	
	if(bCheck == true && oCheckResult.retcode == 0)
	{
		bool bResult = false;
		
		for(int k = 0; k < 5; k++)
		{
			bResult = OrderSend(oRequest, oResult);
			
			if(bResult == true && (oResult.retcode == TRADE_RETCODE_PLACED || oResult.retcode == TRADE_RETCODE_DONE))
				break;
			
			if(k == 4)
				break;
				
			Sleep(100);
		} 
		Print("Order Send MarketOrder:",
				" OrderSend = ",	bResult,
				", retcode = ",	oResult.retcode, 
				", deal = ",		oResult.deal,
				", order = ",		oResult.order,
				", volume = ",		NormalizeDouble(oResult.volume, 2),
				", price = ",		NormalizeDouble(oResult.price, _Digits),
				", bid = ",			NormalizeDouble(oResult.bid, _Digits),
				", ask = ",			NormalizeDouble(oResult.ask, _Digits),
				", comment = ",	oResult.comment,
				", request_id = ",oResult.request_id);	
				
		if(oResult.retcode == TRADE_RETCODE_DONE)
			bRetVal = true;
	}
	else if(oResult.retcode == TRADE_RETCODE_NO_MONEY)
	{
		Print("Недостаточно денег для открытия позиции. Работа эксперта прекращена.");
		ExpertRemove();
	}
	
	return(bRetVal);
} 
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
bool InitialSLTP(const string sSymbol, const double nSL = 0, const double nTP = 0)
{	
	bool bRetVal = false;
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=0; i<total; i++)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);// ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS); // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);    // volume of the position
      double sl=PositionGetDouble(POSITION_SL);  // Stop Loss of the position
      double tp=PositionGetDouble(POSITION_TP);  // Take Profit of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position
      
      //--- if the MagicNumber matches, Stop Loss and Take Profit are not defined
      if(magic==Magic && sl==0 && tp==0 && position_symbol==sSymbol)
        {
         //--- calculate the current price levels
         double price=PositionGetDouble(POSITION_PRICE_OPEN);
         double bid=SymbolInfoDouble(position_symbol,SYMBOL_BID);
         double ask=SymbolInfoDouble(position_symbol,SYMBOL_ASK); 

         if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	         {
	        	request.type_filling = ORDER_FILLING_FOK;
	         }
	       if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	         {		
		        request.type_filling = ORDER_FILLING_IOC;
		       }
	       if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==0)
	         {	
		        request.type_filling = ORDER_FILLING_RETURN;
	         }
      	//--- check filling
	       if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)>2)
	         {   	
            if(!FillingCheck(sSymbol)) return(false);
           }    
                    
         if(type==POSITION_TYPE_BUY)
           {
            if(UseSL && nSL > 0) sl=NormalizeDouble(bid-nSL*point(),digits);
            if(UseTP && nTP > 0) tp=NormalizeDouble(ask+nTP*point(),digits);
           }
         else
           {
            if(UseSL && nSL > 0) sl=NormalizeDouble(ask+nSL*point(),digits);
            if(UseTP && nTP > 0) tp=NormalizeDouble(bid-nTP*point(),digits);
           }
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action  =TRADE_ACTION_SLTP; // type of trade operation
         request.position=position_ticket;   // ticket of the position
         request.symbol=position_symbol;     // symbol 
         request.sl      =sl;                // Stop Loss of the position
         request.tp      =tp;                // Take Profit of the position
         request.magic=Magic;                // MagicNumber of the position
         //--- send the request
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         else bRetVal=true;
        }
     }
	return (bRetVal);
}
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
bool ClosePosition(const string sSymbol, double fLot = 0)
{
	 bool bRetVal = false;
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
      {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position
 
      //--- if the MagicNumber matches
      if(magic==Magic && position_symbol==sSymbol)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result);
         
	       if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	         {
	         	request.type_filling = ORDER_FILLING_FOK;
	         }
	      if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	        {		
		       request.type_filling = ORDER_FILLING_IOC;
		      }
	      if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)==0)
	        {	
		       request.type_filling = ORDER_FILLING_RETURN;
	        }
      	//--- check filling
	     if((int) SymbolInfoInteger(sSymbol, SYMBOL_FILLING_MODE)>2)
	       {   	
           if(!FillingCheck(sSymbol)) return(false);
          }        
         //--- setting the operation parameters
         request.action   =TRADE_ACTION_DEAL;        // type of trade operation
         request.position =position_ticket;          // ticket of the position
         request.symbol   =position_symbol;          // symbol 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =Magic;                    // MagicNumber of the position
         //--- set the price and order type depending on the position type
         if(type==POSITION_TYPE_BUY)
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type =ORDER_TYPE_SELL;
           }
         else
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type =ORDER_TYPE_BUY;
           } 
         //--- send the request
         if(!OrderSend(request,result))
            PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code 
         //---
        }
     }
	return(bRetVal);
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//| Trailing Stop                                                    |
//+------------------------------------------------------------------+
bool TrailingStop(const string sSymbol, const double nTSActivationProfit)
{				
	 bool bRetVal = false;
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position 
		  double fOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	    double fSL = PositionGetDouble(POSITION_SL);
		  double fTP = PositionGetDouble(POSITION_TP);
		  double fPoint = SymbolInfoDouble(position_symbol, SYMBOL_POINT);
		  int nDigits = (int) SymbolInfoInteger(position_symbol, SYMBOL_DIGITS);      
     
      if(magic==Magic && position_symbol==sSymbol)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result); 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =Magic;                    // MagicNumber of the position
         request.position =position_ticket;          // ticket of the position
         
         if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	         {
	        	request.type_filling = ORDER_FILLING_FOK;
	         }
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	         {		
		        request.type_filling = ORDER_FILLING_IOC;
		       }
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==0)
	         {	
		        request.type_filling = ORDER_FILLING_RETURN;
	         }
      	//--- check filling
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)>2)
	         {   	
            if(!FillingCheck(position_symbol)) return(false);
           }     
		
		double fNewSL = 0;
		
		if(type == POSITION_TYPE_BUY)
		{
			double fBid = SymbolInfoDouble(position_symbol, SYMBOL_BID);
			
			if(fBid >= (fOpenPrice + nTSActivationProfit * fPoint))
				fNewSL = fBid - nTSActivationProfit * fPoint;
		}
		if(type == POSITION_TYPE_SELL)
		{
			double fAsk = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
				
			if(fAsk <= (fOpenPrice - nTSActivationProfit * fPoint))
				fNewSL = fAsk + nTSActivationProfit * fPoint;
		}
		
		if((type == POSITION_TYPE_BUY && ND(fNewSL) > ND(fSL)) || (type == POSITION_TYPE_SELL && (fNewSL > 0 && (ND(fNewSL) < ND(fSL) || fSL == 0))))
		  {
			 request.action			= TRADE_ACTION_SLTP;
			 request.symbol			= position_symbol;
			 request.sl					= NormalizeDouble(ND(fNewSL), nDigits);
			 request.tp					= NormalizeDouble(fTP, nDigits);		  
        
       //--- send the request
       if(!OrderSend(request,result)) PrintFormat("OrderSend error %d",GetLastError()); 
       else{ Print("Position modified by Trailing Stop Loss! SL is = ", NormalizeDouble(fNewSL, nDigits)); bRetVal=true;}
       //---
		  }
		}  
	}
	return (bRetVal);
} 
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\\
//+------------------------------------------------------------------+
//| Break Even                                                       |
//+------------------------------------------------------------------+
bool BreakEven(const string sSymbol, const double nBEActivationProfit)
{				
	 bool bRetVal=false; double fNewSL=0; int total=PositionsTotal();
	 
//--- declare and initialize the trade request and result of trade request
   MqlTradeRequest request; MqlTradeResult  result; 
   
//--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
      {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position 
		  double fOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	    double fSL = PositionGetDouble(POSITION_SL);
		  double fTP = PositionGetDouble(POSITION_TP);
		  double fPoint = SymbolInfoDouble(position_symbol, SYMBOL_POINT);  
		  int nDigits = (int) SymbolInfoInteger(position_symbol, SYMBOL_DIGITS);      
     
      if(magic==Magic && position_symbol==sSymbol)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result); 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =Magic;                    // MagicNumber of the position
         request.position =position_ticket;          // ticket of the position
         
         if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_FOK)
	         {
	        	request.type_filling = ORDER_FILLING_FOK;
	         }
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==SYMBOL_FILLING_IOC)
	         {		
		        request.type_filling = ORDER_FILLING_IOC;
		       }
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)==0)
	         {	
		        request.type_filling = ORDER_FILLING_RETURN;
	         }
      	//--- check filling
	       if((int) SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE)>2)
	         {   	
            if(!FillingCheck(position_symbol)) return(false);
           }      
//---            
		     if(type == POSITION_TYPE_BUY)
		       {
			      double fBid = SymbolInfoDouble(position_symbol, SYMBOL_BID);
			
			      if(fBid >= (fOpenPrice + nBEActivationProfit * fPoint)) fNewSL = NormalizeDouble(fOpenPrice, nDigits);
		       }
		     if(type == POSITION_TYPE_SELL)
		       {
			      double fAsk = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
				
			      if(fAsk <= (fOpenPrice - nBEActivationProfit * fPoint)) fNewSL = NormalizeDouble(fOpenPrice, nDigits);
		       }
		
	    	 if((type == POSITION_TYPE_BUY && ND(fNewSL) > ND(fSL)) || (type == POSITION_TYPE_SELL && (fNewSL > 0 && (ND(fNewSL) < ND(fSL) || fSL == 0))))
		       {
			      request.action			= TRADE_ACTION_SLTP;
			      request.symbol			= position_symbol;
			      request.sl					= NormalizeDouble(ND(fNewSL), nDigits);
			      request.tp					= NormalizeDouble(fTP, nDigits);		  
        
            //--- send the request
            if(!OrderSend(request,result)) PrintFormat("OrderSend error %d",GetLastError()); 
            else{ Print("Position modified by Break Even! SL is = ", NormalizeDouble(fNewSL, nDigits)); bRetVal=true;}
           //---
		       }
        }  
      }
	return (bRetVal);
}  
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+
double ND(double price)
{
   if(price > 0) return(NormalizeDouble(price,_Digits));
   
   return(0);
}
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Checks and corrects type of filling policy                       |
//+------------------------------------------------------------------+
bool FillingCheck(const string symbol)
  {
   MqlTradeRequest   m_request={0};         // request data
   MqlTradeResult    m_result={0};          // result data

   ENUM_ORDER_TYPE_FILLING m_type_filling=0;
//--- get execution mode of orders by symbol
   ENUM_SYMBOL_TRADE_EXECUTION exec=(ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
//--- check execution mode
   if(exec==SYMBOL_TRADE_EXECUTION_REQUEST || exec==SYMBOL_TRADE_EXECUTION_INSTANT)
     {
      //--- neccessary filling type will be placed automatically
      return(true);
     }
//--- get possible filling policy types by symbol
   uint filling=(uint)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- check execution mode again
   if(exec==SYMBOL_TRADE_EXECUTION_MARKET)
     {
      //--- for the MARKET execution mode
      //--- analyze order
      if(m_request.action!=TRADE_ACTION_PENDING)
        {
         //--- in case of instant execution order
         //--- if the required filling policy is supported, add it to the request
         if(m_type_filling==ORDER_FILLING_FOK && (filling & SYMBOL_FILLING_FOK)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         if(m_type_filling==ORDER_FILLING_IOC && (filling & SYMBOL_FILLING_IOC)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
        }
      return(true);
     }
//--- EXCHANGE execution mode
   switch(m_type_filling)
     {
      case ORDER_FILLING_FOK:
         //--- analyze order
         if(m_request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               m_request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(m_request.type==ORDER_TYPE_BUY_STOP || m_request.type==ORDER_TYPE_SELL_STOP)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               m_request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
            }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling & SYMBOL_FILLING_FOK)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_IOC:
         //--- analyze order
         if(m_request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               m_request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(m_request.type==ORDER_TYPE_BUY_STOP || m_request.type==ORDER_TYPE_SELL_STOP)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               m_request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
           }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling & SYMBOL_FILLING_IOC)!=0)
           {
            m_request.type_filling=m_type_filling;
            return(true);
           }
         //--- wrong filling policy, set error code
         m_result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_RETURN:
         //--- add filling policy to the request
         m_request.type_filling=m_type_filling;
         return(true);
     }
//--- unknown execution mode, set error code
   m_result.retcode=TRADE_RETCODE_ERROR;
   return(false);
  }
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Check expiration type of pending order                           |
//+------------------------------------------------------------------+
bool ExpirationCheck(const string symbol)
  {
   CSymbolInfo sym;
   MqlTradeRequest   m_request={0};         // request data
   MqlTradeResult    m_result={0};          // result data

//--- check symbol
   if(!sym.Name((symbol==NULL)?Symbol():symbol))
      return(false);
//--- get flags
   int flags=sym.TradeTimeFlags();
//--- check type
   switch(m_request.type_time)
     {
      case ORDER_TIME_GTC:
         if((flags&SYMBOL_EXPIRATION_GTC)!=0)
            return(true);
         break;
      case ORDER_TIME_DAY:
         if((flags&SYMBOL_EXPIRATION_DAY)!=0)
            return(true);
         break;
      case ORDER_TIME_SPECIFIED:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED)!=0)
            return(true);
         break;
      case ORDER_TIME_SPECIFIED_DAY:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED_DAY)!=0)
            return(true);
         break;
      default:
         Print(__FUNCTION__+": Unknown expiration type");
         break;
     }
//--- failed
   return(false);
  }  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//
//+------------------------------------------------------------------+
//| Check Symbol Points                                              |
//+------------------------------------------------------------------+     
double point(string symbol=NULL)  
{  
   string sym=symbol;if(symbol==NULL) sym=_Symbol; 
   return(SymbolInfoDouble(sym,SYMBOL_POINT));
}   
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Check for open positions                                         |
//+------------------------------------------------------------------+
int Positions(int ty=-1)
{
	 int result = 0, total=PositionsTotal(); // number of open positions   
//--- iterate over all open positions
   for(int i=0; i<total; i++)
     {
      //--- parameters of the order
      ulong  position_ticket=PositionGetTicket(i);// ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL); // symbol  
      ulong  magic=PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position 
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position 
       
      if(magic==Magic && position_symbol==_Symbol)
        {  
			   if(type == ty || ty == -1) result++;	
        }	
     }   
	 return(result); // 0 means there are no orders/positions
}  
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
//| Time Filter                                                      |
//+------------------------------------------------------------------+
bool TimeFilter()
{  
  if(Time_End == "00:00" && Time_Start == "00:00") return(true);
  
  long hs1 = StringToInteger(StringSubstr(Time_Start, 0, 2)), ms1 = StringToInteger(StringSubstr(Time_Start, 3, 2));
  long he1 = StringToInteger(StringSubstr(Time_End, 0, 2)), me1 = StringToInteger(StringSubstr(Time_End, 3, 2)); 
 
  if(Time_End != "00:00" && hs1 < he1)
    {
    if(((TimeHour(TimeCurrent()) == hs1 && TimeMinute(TimeCurrent()) >= ms1) && TimeHour(TimeCurrent()) < he1) 
    || (TimeHour(TimeCurrent()) > hs1 && TimeHour(TimeCurrent()) < he1) 
    || ((TimeMinute(TimeCurrent()) <= me1 && TimeHour(TimeCurrent()) == he1) && TimeHour(TimeCurrent()) > hs1) 
    || (TimeHour(TimeCurrent()) < he1 && TimeHour(TimeCurrent()) > hs1))
    return(true);
    }
  if(Time_End != "00:00" && hs1 > he1)
    {
    if((TimeHour(TimeCurrent()) == hs1 && TimeMinute(TimeCurrent()) >= ms1 && TimeHour(TimeCurrent()) < 24)
    || (TimeHour(TimeCurrent()) > hs1 && TimeHour(TimeCurrent()) < 24)
    || (TimeHour(TimeCurrent()) == he1 && TimeMinute(TimeCurrent()) <= me1 && TimeHour(TimeCurrent()) >= 0)
    || (TimeHour(TimeCurrent()) < he1 && TimeHour(TimeCurrent()) >= 0))
    return(true);
    }  
  if(Time_End == "00:00")
    {
    if((TimeHour(TimeCurrent()) == hs1 && TimeMinute(TimeCurrent()) >= ms1) || TimeHour(TimeCurrent()) > hs1)
    return(true);
    } 
   return(false);   
} 
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
int TimeHour(datetime date){ MqlDateTime tm;TimeToStruct(date,tm);return(tm.hour);}
int TimeMinute(datetime date){ MqlDateTime tm;TimeToStruct(date,tm);return(tm.min);} 
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
//+------------------------------------------------------------------+
double RoundLot(const string sSymbol, const double fLot)
{
	double fMinLot  = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_MIN);
	double fMaxLot  = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_MAX);
	double fLotStep = SymbolInfoDouble(sSymbol, SYMBOL_VOLUME_STEP);
	
	int nLotDigits = (int) StringToInteger(DoubleToString(MathAbs(MathLog(fLotStep)/MathLog(10)), 0));
	
	double fRoundedLot = MathFloor(fLot/fLotStep + 0.5) * fLotStep;
	
	fRoundedLot = NormalizeDouble(fRoundedLot, nLotDigits);
	
	if(fRoundedLot < fMinLot)
		fRoundedLot = fMinLot;
		
	if(fRoundedLot > fMaxLot)
		fRoundedLot = fMaxLot;
	
	return(fRoundedLot);
}    
//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH//  
