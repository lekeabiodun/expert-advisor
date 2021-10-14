#include <Trade\Trade.mqh>
CTrade trade;

input ENUM_TIMEFRAMES period = PERIOD_CURRENT;
static datetime timestamp_H1;
static datetime timestamp_M1;


int count = 0;
void OnTick() 
{
    datetime time_M1 = iTime(Symbol(), PERIOD_M1, 0);
    
    Comment("TIme: ", time_M1.sec);
    
    // if(timestamp_M1 != time_M1) {
    //     timestamp_M1 = time_M1;
    //     close_all_positions();
    // }

    // datetime time_H1 = iTime(Symbol(), period, 0);

    // if(timestamp_H1 != time_H1) {
    //     timestamp_H1 = time_H1;

    //     close_all_positions();

    //     double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    //     trade.Sell(1, Symbol(), ask, 0, 0);
    // }


}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}