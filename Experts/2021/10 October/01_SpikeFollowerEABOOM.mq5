#include <Trade\Trade.mqh>
CTrade trade;
CDealInfo m_deal;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

// input group                                         "============  EA Settings  ===============";
// input int                                           EXPERT_MAGIC = 555784; // Magic Number
// input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        InputLotSize = 1; // LotSize
input double                                        InputCandleLimit = 4; // Stop loss candle limit

int OnInit() {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}


void OnTick() {

    if(!SpikeLatency()) { return; }

    if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1)) { 
        
        TakeTrade(MARKET_ENTRY_LONG);

    }

    if(CandleLimitHit()) {
        close_all_positions();
    }

}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{
    if(Entry == MARKET_ENTRY_LONG) {
        double ask                             = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        // trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(InputLotSize, Symbol(), ask, 0, 0);
    }

}

//+------------------------------------------------------------------+
//| Spike Latency function                                           |
//+------------------------------------------------------------------+
// input group                                         "===================== Latency Settings =====================";
bool                                          UseSpikeLatency = true; // Use Spike Latency
ENUM_TIMEFRAMES                               ExpertLatencyTimeFrame = PERIOD_M1; // Timeframe

datetime tradeCandleTime;
static datetime tradeTimestamp;

bool SpikeLatency()
{
    if(!UseSpikeLatency) { return true; }

    tradeCandleTime = iTime(Symbol(), ExpertLatencyTimeFrame, 0);
    
    if(tradeTimestamp != tradeCandleTime) 
    {

        tradeTimestamp = tradeCandleTime;

        return true;
    }

    return false;
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

bool CandleLimitHit() {
    for(int i = 0; i < InputCandleLimit; i++) {
        if(iClose(Symbol(), Period(), i) > iOpen(Symbol(), Period(), i)) {
            return false;
        }
    }
    return true;
}
