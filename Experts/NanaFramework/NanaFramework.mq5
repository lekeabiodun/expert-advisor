#include <Trade\Trade.mqh>
CTrade trade;
enum ENTRY_TYPE {
    BUY,                // Buy Signal
    SELL                // Sell Signal
};
enum TREND_TYPE {
    BULLISH,            // Bullish/Uptrend Market
    BEARISH             // Bearish/Downtrend Market
};
enum TRADE_BEHAVIOUR {   
   REGULAR_BEHAVIOUR,   // Take Regular trade
   BUY_BEHAVIOUR,       // Only Take Buy Trade
   SELL_BEHAVIOUR       // Only Take Sell Trade
};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 11235813;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = REGULAR_BEHAVIOUR;    // Trading Behaviour

    
int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

void OnTick()
{
    ENTRY_TYPE signal = BUY;
    
    if(signal == BUY)
    {
        Print("Buy Signal");
    } 
    else if(signal == SELL)
    {
        Print("Sell Signal");    
    }

}
