#include <Trade\Trade.mqh>

enum enumTradeType{Buy, Sell};

input group                                       "============  EA Settings ===============";
input ulong                                       EXPERT_MAGIC = 787878;

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in Pips (Min:100)
input double                                       takeProfit = 0.0; // Take Profit in Pips (Min:100)

input group                                       "============  Position Management Settings ===============";
input bool                                         closeOnOppositeSignal = true; // Close Trade on Opposite Signal

input group                                       "============  Stochastic Settings  ===============";
input int stoch_kperiod = 5; // % K Period
input int stoch_dperiod = 3; // % D Period
input int stoch_slowing = 3; // Slowing
input ENUM_STO_PRICE stoch_price = STO_LOWHIGH;  // Price Field
input ENUM_MA_METHOD stoch_mode = MODE_SMA; // Method

input group                                       "============  Stochastic Levels  ===============";
input bool stoch_levels = true; // Use Stochastic levels
input int overbought = 80; // Overbought Level
input int oversold = 20; // Oversold level

static datetime timestamp;
CTrade trade;

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{


}


void OnTick()
{
   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
         
      timestamp = time;

      double KArray[], DArray[];
      
      ArraySetAsSeries(KArray, true);
      ArraySetAsSeries(DArray, true);
      
      int Stochastic = iStochastic(_Symbol, _Period, stoch_kperiod, stoch_dperiod, stoch_slowing, stoch_mode, stoch_price);
      
      CopyBuffer(Stochastic, 0, 0, 3, KArray);
      CopyBuffer(Stochastic, 1, 0, 3, DArray);
      
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      
      if(signal(Buy, KArray[0], DArray[0])){
         if(KArray[0]>DArray[0] && KArray[1] < DArray[1]){
         
            if(closeOnOppositeSignal){ 
               trade.SetExpertMagicNumber(EXPERT_MAGIC);
               trade.PositionClose(PositionGetSymbol(0)); 
            }
            
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
            trade.Buy(lotSize, _Symbol, Bid, setStopLoss(Bid, Buy), setTakeProfit(Bid, Buy), "-----Buying----");
         
         }
      } 
      if(signal(Sell, KArray[0], DArray[0])){  
         if(KArray[0]<DArray[0] && KArray[1] > DArray[1]){
         
            if(closeOnOppositeSignal){ 
               trade.SetExpertMagicNumber(EXPERT_MAGIC);
               trade.PositionClose(PositionGetSymbol(0)); 
            }
            
            trade.SetExpertMagicNumber(EXPERT_MAGIC);
            trade.Sell(lotSize, _Symbol, Bid, setStopLoss(Bid, Sell), setTakeProfit(Bid, Sell), "-----Selling-----");
         
         }
      }
   }


}

bool signal(enumTradeType signal, double klevel, double dlevel){
   if(!stoch_levels) return true;
   
   if(signal == Buy && klevel<20 && dlevel<20) return true;
   
   if(signal == Sell && klevel>20 && dlevel>20) return true;
   
   return false;
}


double setStopLoss(double Bid, enumTradeType tradeType){
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(Bid, tradeType);
}

double calculateStopLoss(double Bid, enumTradeType tradeType){
   if(tradeType == Buy){ return Bid-stopLoss; }
   if(tradeType == Sell){ return Bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double Bid, enumTradeType tradeType){
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(Bid, tradeType);
}

double calculateTakeProfit(double Bid, enumTradeType tradeType){
   if(tradeType == Buy){ return  Bid+takeProfit; }
   if(tradeType == Sell){ return Bid-takeProfit; } 
   return 0.0;
}

