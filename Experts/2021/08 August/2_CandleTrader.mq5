#include <Trade\Trade.mqh>
CTrade trade;
CDealInfo m_deal;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

void OnTick() 
{

    if(ExpertHasLatency()) { return ; }

    close_all_positions();

    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit);

    // double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    // trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit);

    
}


/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;

input group                                         "============ Latency Settings ===============";
input bool                                          expertLatency = false; // Trade Latency
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool ExpertHasLatency()
{
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);

    if(!expertLatency) {
        return false;
    } else {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return false;
        }
    }
    return true;
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}
