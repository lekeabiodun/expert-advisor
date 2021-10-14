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
input int                                           maxTrade = 1; // Max Trade
input bool                                          ExpertIsTakingRecovery = false; // Take Recovery
input group                                         "============  Level Settings  ===============";
input int                                           lookBackCandleRange = 1; // Look back candle range
input int                                           levelModulo = 100; // Level
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

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


    // if(!SpikeLatency()) { return ; }
    
    TradePositionManager();
    
    MaxPrice = MathMax(iOpen(Symbol(), Period(), 1), iClose(Symbol(), Period(), 0));
    MinPrice = MathMin(iOpen(Symbol(), Period(), 1), iClose(Symbol(), Period(), 0));

    for(int i = (int) MinPrice; i <= (int) MaxPrice; i++) 
    {
        if(MathMod(i, levelModulo) == 0)
        {
            CurrLevel = i;

            if(PrevLevel == 0)
            {
                PrevLevel = CurrLevel;
            } 
            else if(CurrLevel - PrevLevel <= -levelModulo || CurrLevel - PrevLevel >= levelModulo) 
            {
                PrevLevel = CurrLevel;
            }
            else
            {
                return;
            }
            
            close_all_orders();
            
            trade.BuyStop(lotSize, i+levelModulo, Symbol(), i, i+(levelModulo*5));
            trade.SellStop(lotSize, i-levelModulo, Symbol(), i, i-(levelModulo*5));

            // trade.BuyStop(lotSize, i+levelModulo, Symbol(), i, i+levelModulo+takeProfit);
            // trade.BuyStop();
            // trade.Buy(lotSize, Symbol(), ask, 0, 0);

            

            // if(MarketDirection(MARKET_DIRECTION_UP, i)) { TakeTrade(MARKET_ENTRY_LONG); }

            // if(MarketDirection(MARKET_DIRECTION_DOWN, i)) { TakeTrade(MARKET_ENTRY_SHORT); }
        }
        
    }
    
}

void TakeTrade(ENUM_MARKET_ENTRY Entry) {

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade && expertAllows(POSITION_TYPE_BUY)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && expertIsTakingSellTrade && expertAllows(POSITION_TYPE_SELL)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
    }

}

/* ##################################################### Trade Position Manager ##################################################### */
void TradePositionManager() {
    for(int i = 0; i < PositionsTotal(); i++) {
        PositionGetSymbol(i);
        // Print(i, " POSITION_SL: ", PositionGetDouble(POSITION_SL), " POSITION_CP: ", PositionGetDouble(POSITION_PRICE_CURRENT));
        if(
            (
                MathMax(PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_PRICE_CURRENT)) - 
                MathMin(PositionGetDouble(POSITION_SL), PositionGetDouble(POSITION_PRICE_CURRENT))
            ) > (levelModulo * 2)
        ) {

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { 
                ulong ticket = PositionGetTicket(i);
                double sl = PositionGetDouble(POSITION_SL);
                double cp = PositionGetDouble(POSITION_PRICE_CURRENT);
                if(cp - sl >= (levelModulo*2)) {
                    trade.PositionModify(ticket, (sl + levelModulo), sl+(levelModulo*5));
                }
            }

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) { 
                ulong ticket = PositionGetTicket(i);
                double sl = PositionGetDouble(POSITION_SL);
                double cp = PositionGetDouble(POSITION_PRICE_CURRENT);
                if(sl - cp >= (levelModulo*2)) {
                    trade.PositionModify(ticket, (sl - levelModulo), sl-(levelModulo*5));
                }
            }
        }
    }
}

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
enum tradeLatency { ZEROLATENCY, TIMELATENCY, TIMEFRAMELATENCY };

input group                                         "============ Latency Settings ===============";
input tradeLatency                                  expertLatency = ZEROLATENCY; // Trade Latency
input int                                           expertLatencyTime = 50; // Time to trade
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool SpikeLatency()
{
    tradeCurrentTime = (int)TimeCurrent();
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);
    if(expertLatency == ZEROLATENCY) {
        return true;
    }
    if(expertLatency == TIMELATENCY) {
        if(tradeCurrentTime - tradeStartTime >= expertLatencyTime) { 
            tradeStartTime = tradeCurrentTime;
            return true;
        }
    }
    if(expertLatency == TIMEFRAMELATENCY)
    {
        if(tradeTimestamp != tradeCandleTime) {
            tradeTimestamp = tradeCandleTime;
            return true;
        }
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


bool expertAllows(ENUM_POSITION_TYPE positionType) 
{
    bool result = true;

    if(!PositionsTotal()) { return true; }

    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == positionType) { 
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

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        double recoveryLotSize = NormalizeDouble(dealLost / stopLoss, 2);

        if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }

    if(Entry == MARKET_ENTRY_SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        double recoveryLotSize = NormalizeDouble(dealLost / stopLoss, 2);

        if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
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

/* ##################################################### Market Direction ##################################################### */
bool MarketDirection(ENUM_MARKET_DIRECTION Direction, int level) 
{
    double sum = 0;
    double average = 0;

    for(int i = 1; i <= lookBackCandleRange; i++) {
        sum = sum + iOpen(Symbol(), Period(), i);
    }

    average = sum / lookBackCandleRange;

    if(Direction == MARKET_DIRECTION_UP && iOpen(Symbol(), Period(), 0) > level) {
        return true;
    }
    
    if(Direction == MARKET_DIRECTION_DOWN && iOpen(Symbol(), Period(), 0) < level) {
        return true;
    }

    return false;

}