#include <Trade\Trade.mqh>
CTrade trade;
enum ENUM_MARKET_ENTRY { MARKET_ENTRY_LONG, MARKET_ENTRY_SHORT };
enum ENUM_MARKET_SIGNAL { MARKET_SIGNAL_BUY, MARKET_SIGNAL_SELL };
enum ENUM_MARKET_DIRECTION { MARKET_DIRECTION_UP, MARKET_DIRECTION_DOWN };
enum ENUM_EXPERT_BEHAVIOUR { EXPERT_BEHAVIOUR_REGULAR, EXPERT_BEHAVIOUR_OPPOSITE };
enum ENUM_MARKET_TREND { MARKET_TREND_BULLISH, MARKET_TREND_BEARISH, MARKET_TREND_SIDEWAYS };

input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input ENUM_EXPERT_BEHAVIOUR                         EXPERT_BEHAVIOUR = EXPERT_BEHAVIOUR_REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        LotSize = 1; // Lot Size
input double                                        StopLoss = 0.0; // Stop Loss in Pips
input double                                        TakeProfit = 0.0; // Take Profit in Pips
input int                                           LevelModulo = 100; // Level Modulo in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade
input bool                                          ExpertIsTakingRecovery = false; // Take Recovery

/*
NAME
Level Trader.
DESCRIPTION
Expert Advisor is design to trade levels.
On getting to a new level (Current Level[CL]).
Check the market direction (Market Direction[MD]).
Check the level that the market is coming from (Previous Level[PL]).
Take trade towards market direction (Next Level[NL]).

EXAMPLE
If market is fast approaching level 700
& the market is coming from level 600

BEGIN
Current Level[CL] = 700;
Previous Level[PL] = 600;
IF
Market Direction[MD] = UP;
THEN
Next Level[NL] = 800;
IF
Market Direction[MD] = DOWN;
THEN
Next Level[NL] = 600;
END

*/

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

int PrevLevel = 0;
int CurrLevel = 0;
int NextLevel = 0;
ENUM_MARKET_DIRECTION MarketDirection;

double MaxPrice = 0;
double MinPrice = 0; 

void OnTick() 
{

    if(!SpikeLatency()) { return ; }
    
    // TradePositionManager();

    int curr_level = Level_Crossed();

    double prev_open = iOpen(Symbol(), Period(), 1);
    double curr_open = iOpen(Symbol(), Period(), 0);

    if(curr_level > 0)
    {
        if(curr_level >= prev_open && curr_level <= curr_open)
        {
            
            close_all_positions();

            TakeTrade(MARKET_ENTRY_LONG);
        
        }
        if(curr_level <= prev_open && curr_level >= curr_open)
        {

            close_all_positions();
            
            TakeTrade(MARKET_ENTRY_SHORT);
        
        }
    }

}

int Level_Crossed()
{
    int level = -1;
    
    // double max = MathMax(iHigh(Symbol(), Period(), 1), iHigh(Symbol(), Period(), 0));
    // double min = MathMin(iLow(Symbol(), Period(), 1), iLow(Symbol(), Period(), 0));

    double max = MathMax(iOpen(Symbol(), Period(), 1), iOpen(Symbol(), Period(), 0));
    double min = MathMin(iOpen(Symbol(), Period(), 1), iOpen(Symbol(), Period(), 0));

    for(int i = (int) min; i <= (int) max; i++) 
    {
        Comment("Cross", i);
        if(MathMod(i, LevelModulo) == 0)
        {
            return level = i;
        }
    }

    return level;

}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {
        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl			= NormalizeDouble(ask - StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(ask + TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(LotSize, Symbol(), ask, sl, tp);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - TakeProfit * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
    }

}

/* ##################################################### Spike LATENCY ##################################################### */
input group                                         "===================== Latency Settings =====================";
input bool                                          UseSpikeLatency = false; // Use Spike Latency
input ENUM_TIMEFRAMES                               ExpertLatencyTimeFrame = PERIOD_CURRENT; // Timeframe

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

void close_all_orders() {
    if(OrdersTotal() > 0) {
        for(int i=0; i < OrdersTotal()-1; i++) {
             ulong ticket = OrderGetTicket(i);
             trade.OrderDelete(ticket);
        }
    }
}

bool ExpertAllows(ENUM_POSITION_TYPE PositionType) 
{
    bool result = true;

    if(!PositionsTotal()) { return true; }

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == PositionType) { 
            result = false; 
        }
    }

    return result;
}

/* ##################################################### Recovery ##################################################### */
void TakeRecoveryTrade(ENUM_MARKET_ENTRY Entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {

        double recoveryLotSize = 10;
        double ask          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double sl			= NormalizeDouble(ask - StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(ask + 10 * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, sl, tp, "Recovery");

        // // double recoveryLotSize = NormalizeDouble(dealLost / StopLoss, 2);

        // if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        // if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        // trade.SetExpertMagicNumber(EXPERT_MAGIC);
        // trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {


        double bid          = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double sl			= NormalizeDouble(bid + StopLoss * _Point, _Digits) * (StopLoss > 0);
        double tp			= NormalizeDouble(bid - 10 * _Point, _Digits) * (TakeProfit > 0);
        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(LotSize, Symbol(), bid, sl, tp, "Recovery");



        // double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        // double recoveryLotSize = NormalizeDouble(dealLost / StopLoss, 2);

        // if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        // if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        // trade.SetExpertMagicNumber(EXPERT_MAGIC);
        // trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
    }
}

double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0;

    HistorySelect(0,TimeCurrent());

    for(int i = HistoryDealsTotal()-1; i >= 0; i--) {

        dealTicket = HistoryDealGetTicket(i);
        dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

        if(dealSymbol != Symbol()) { continue; }

        if(dealProfit < 0) { dealLost = dealLost + dealProfit; }

        if(dealProfit > 0) { break; }

    }

    return dealLost;
}

