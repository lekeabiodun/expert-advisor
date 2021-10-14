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
input double                                        TakeProfit = 0.0; // Take Profit in Pips
input double                                        StopLosss = 0.0; // Stop Loss in Pips
input int                                           LevelModulo = 100; // Level
input double                                        TPPadd = 2.5; // TP Padding
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

int NextSellLevel;
int CurrSellLevel;
int PrevSellLevel;

int NextBuyLevel;
int CurrBuyLevel;
int PrevBuyLevel;

MqlRates rates[];

void OnTick() 
{

    if(!SpikeLatency()) { return ; }

    if(RunAwayProfitTargetHit()) { return; }
    
    ArraySetAsSeries(rates, true);

    int copied=CopyRates(NULL, 0, 0, 5, rates);

    double MaxHigh = MathMax(rates[1].high, rates[0].high);
    double MaxLow = MathMax(rates[1].low, rates[0].low);
    
    MaxPrice = (int) MathMax(MaxHigh, MaxLow);
    MinPrice = (int) MathMin(MaxHigh, MaxLow);

    // Comment("MaxPrice: ", MaxPrice, " MinPrice: ", MinPrice);

    for(int NewLevel = MinPrice; NewLevel <= MaxPrice; NewLevel++) 
    {
        if(MathMod(NewLevel, LevelModulo) == 0)
        {

            if(rates[1].high < rates[0].high)
            {
                PrevBuyLevel = CurrBuyLevel;

                CurrBuyLevel = NewLevel;

                NextBuyLevel = CurrBuyLevel + LevelModulo;

                if(PrevBuyLevel == CurrBuyLevel) {  return ; }

                TakeTrade(MARKET_ENTRY_LONG);

            }

            if(rates[1].high > rates[0].high)
            {
                PrevSellLevel = CurrSellLevel;

                CurrSellLevel = NewLevel;
                
                NextSellLevel = CurrSellLevel - LevelModulo;

                if(PrevSellLevel == CurrSellLevel) {  return; }
                
                TakeTrade(MARKET_ENTRY_SHORT);
            }
        
        }
        
    }
    
}

void TakeTrade(ENUM_MARKET_ENTRY Entry) 
{
    if(Entry == MARKET_ENTRY_LONG && ExpertIsTakingBuyTrade && ExpertAllows(POSITION_TYPE_BUY)) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, ask - StopLosss, NextBuyLevel - TPPadd);
    }

    if(Entry == MARKET_ENTRY_SHORT && expertIsTakingSellTrade && ExpertAllows(POSITION_TYPE_SELL)) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, bid + StopLosss, NextSellLevel + TPPadd);
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

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
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
        if((ENUM_DEAL_REASON)reason==DEAL_REASON_SL) 
        {
        }
        else {
            if((ENUM_DEAL_REASON)reason==DEAL_REASON_TP) 
            {
            }
        }
        if(m_deal.Entry() == DEAL_ENTRY_IN)
        {
        }
    }
}

//+------------------------------------------------------------------+
//| Run Away function                                        |
//+------------------------------------------------------------------+
input group                                         "============  Run Away Profit Settings ===============";
input bool                                          ExpertIsUsingRunAwayProfitTarget = false; // Use Run Away Profit Target
input ENUM_TIMEFRAMES                               RunAwayProfitFrequency = PERIOD_D1; // Frequency
input int                                           RunAwayProfitTarget = 15; // Profit Target
input int                                           RunAwayLossTarget = 15; // Loss Target
input int                                           MaxTradeTarget = 4; // Max Trade Target
datetime RunAwayCandleTime = iTime(Symbol(), RunAwayProfitFrequency, 0);

int ProfitPeriod = 0;
int LossPeriod = 0;
int TradePeriod = 0;

double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
double AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY);

bool RunAwayProfitTargetHit()
{
    if(!ExpertIsUsingRunAwayProfitTarget) { return false; }

    datetime freq = iTime(Symbol(), RunAwayProfitFrequency, 0);

    if(freq != RunAwayCandleTime) {
        RunAwayCandleTime = freq;
        ProfitPeriod = 0;
        LossPeriod = 0;
        TradePeriod = 0;
        CurrSellLevel = 0;
        CurrBuyLevel = 0;
        AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        return false;
    }

    if(ProfitPeriod >= RunAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(TradePeriod >= MaxTradeTarget) { 
        return true; 
    }

    double CurrentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(CurrentEquity - AccountBalance >= RunAwayProfitTarget) { 
        close_all_positions(); 
        return true; 
    }

    if(CurrentEquity - AccountBalance <= -RunAwayLossTarget) { 
        close_all_positions(); 
        return true; 
    }
    
    return false;
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
