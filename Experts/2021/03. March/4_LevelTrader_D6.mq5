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
input bool                                          ExpertIsTakingRecovery = false; // Take Recovery
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input int                                           LevelModulo = 100; // Level
input int                                           maxCTrade = 1; // Max consecutive trade
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

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

int MaxPrice = 0;
int MinPrice = 0; 

int CurrSellLevel;
int PrevSellLevel;

int CurrBuyLevel;
int PrevBuyLevel;

double open[];

void OnTick() 
{

    if(!SpikeLatency()) { return ; }
    
    ArraySetAsSeries(open, true);

    CopyOpen(Symbol(), Period(), 0, 5, open);
    
    MaxPrice = (int) MathRound(MathMax(open[1], open[0]));
    MinPrice = (int) MathMin(open[1], open[0]);

    if(PositionsTotal() >= maxCTrade) { return ; }

    for(int i = MinPrice; i <= MaxPrice; i++) 
    {
        if(MathMod(i, LevelModulo) == 0)
        {

            if(open[1] < open[0])
            {
                PrevBuyLevel = CurrBuyLevel;
                CurrBuyLevel = i;

                if(PrevBuyLevel == CurrBuyLevel) {  return; }

                TakeTrade(MARKET_ENTRY_LONG);

            }
            if(open[1] > open[0])
            {
                PrevSellLevel = CurrSellLevel;
                CurrSellLevel = i;

                if(PrevSellLevel == CurrSellLevel) {  return; }
                
                TakeTrade(MARKET_ENTRY_SHORT);
            }
        
        }
        
    }
    
}

void TakeTrade(ENUM_MARKET_ENTRY Entry) {

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade && expertAllows(POSITION_TYPE_BUY)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && expertIsTakingSellTrade && expertAllows(POSITION_TYPE_SELL)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
    }

}

/* ##################################################### Spike LATENCY ##################################################### */
datetime tradeCandleTime;
static datetime tradeTimestamp;

input group                                         "============ Latency Settings ===============";
input bool                                          expertLatency = false; // Trade Latency
input ENUM_TIMEFRAMES                               expertLatencyTimeFrame = PERIOD_M1; // Timeframe

bool SpikeLatency()
{
    tradeCandleTime = iTime(Symbol(), expertLatencyTimeFrame, 0);

    if(!expertLatency) {
        return true;
    }

    else
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
        trade.Buy(recoveryLotSize, Symbol(), ask, ask - stopLoss, ask + takeProfit, "Recovery");
    }

    if(Entry == MARKET_ENTRY_SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        double recoveryLotSize = NormalizeDouble(dealLost / stopLoss, 2);

        if(recoveryLotSize > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }
        if(recoveryLotSize < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)) { recoveryLotSize = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, bid + stopLoss, bid - takeProfit, "Recovery");
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

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {

    ENUM_TRADE_TRANSACTION_TYPE type=trans.type;

    if(type==TRADE_TRANSACTION_DEAL_ADD)
    {
        if(HistoryDealSelect(trans.deal)) {
            m_deal.Ticket(trans.deal);
        }
        else {
            Print(__FILE__," ",__FUNCTION__,", ERROR: HistoryDealSelect(",trans.deal,")");
            return;
        }
        //---
        long reason=-1;
        if(!m_deal.InfoInteger(DEAL_REASON,reason))
        {
            Print(__FILE__," ",__FUNCTION__,", ERROR: InfoInteger(DEAL_REASON,reason)");
            return;
        }
        if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL) {

            // Print("TP HIT");

        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) {

                // close_all_orders();
                // close_all_positions();


            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {

            // close_all_orders();
        }
    }
}