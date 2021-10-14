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
input double                                        RecoveryLotSize = 10; // Recovery Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          ExpertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          ExpertIsTakingSellTrade = false; // Take Sell Trade

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

double GapPrice;

void OnTick() 
{

    if(!SpikeLatency()) { return ; }

    close_all_positions();

    if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) && RSIFILTER() && DoubleSpike())
    {
        TakeTrade(MARKET_ENTRY_SHORT);
    }
    
}

//+------------------------------------------------------------------+
//| Take Trade function                                        |
//+------------------------------------------------------------------+
void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{
    
    if(EXPERT_BEHAVIOUR == EXPERT_BEHAVIOUR_OPPOSITE) 
    {
        if(Entry == MARKET_ENTRY_LONG) 
        {
            Entry = MARKET_ENTRY_SHORT;
        } 
        else if(Entry == MARKET_ENTRY_SHORT)
        {
            Entry = MARKET_ENTRY_LONG;
        }
    }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) 
    {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, 0, 0);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_LONG); }
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, 0, 0);
        if(ExpertIsTakingRecovery) { TakeRecoveryTrade(MARKET_ENTRY_SHORT); }
    }

}

//+------------------------------------------------------------------+
//| Spike Latency function                                        |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Close All Positions function                                        |
//+------------------------------------------------------------------+
void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Close All Orders function                                        |
//+------------------------------------------------------------------+
void close_all_orders() {
    if(OrdersTotal() > 0) {
        for(int i=0; i < OrdersTotal()-1; i++) {
             ulong ticket = OrderGetTicket(i);
             trade.OrderDelete(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Recovery function                                        |
//+------------------------------------------------------------------+
void TakeRecoveryTrade(ENUM_MARKET_ENTRY Entry) {

    double dealLost = getPreviousDealLost() / -1;

    if(dealLost <= 0) { return ; }

    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(RecoveryLotSize, Symbol(), ask, 0, 0, "Recovery");
    }

    if(Entry == MARKET_ENTRY_SHORT && ExpertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);

        trade.SetExpertMagicNumber(EXPERT_MAGIC);

        trade.Sell(RecoveryLotSize, Symbol(), bid, 0, 0, "Recovery");
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

//+------------------------------------------------------------------+
//| RSIFILTER function                                        |
//+------------------------------------------------------------------+

input group                                       "============  RSI Settings  ===============";
input int                                          RSIPeriod = 9; // RSI Period
input ENUM_APPLIED_PRICE                           RSIAppliedPrice = PRICE_CLOSE; // RSI Applied Price
input int                                          RSIOverSoldLevel = 30; // RSI Oversold Level
input int                                          RSIOverBoughtLevel = 70; // RSI Overbought Level

int RSIHandle = iRSI(Symbol(), Period(), RSIPeriod, RSIAppliedPrice);

bool RSIFILTER() 
{
    double RSIArray[];

    ArraySetAsSeries(RSIArray, true);

    CopyBuffer(RSIHandle, 0, 0, 23, RSIArray);

    double RSIValue = RSIArray[0];

    if(RSIValue < RSIOverBoughtLevel && RSIValue > RSIOverSoldLevel) 
    {
        return true; 
    }

    return false;
}

bool DoubleSpike()
{
    if(iClose(Symbol(), Period(), 2) < iOpen(Symbol(), Period(), 2))
    {
        return true;
    }
    return false;
}