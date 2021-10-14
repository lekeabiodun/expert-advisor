
double recentSwing(marketEntry entry) {
    double swingPrice = 0.0;
    if(entry == LONG) {
        swingPrice = iLow(Symbol(), Period(), 1);
        for(int i=1; i<100; i++) {
            if(swingPrice < iLow(Symbol(), Period(), i)) {
                return swingPrice;
            }
            if(swingPrice > iLow(Symbol(), Period(), i)) {
                swingPrice = iLow(Symbol(), Period(), i);
            }
        }
    }
    if(entry == SHORT) {
        swingPrice = iHigh(Symbol(), Period(), 1);
        for(int i=1; i<100; i++) {
            if(swingPrice > iHigh(Symbol(), Period(), i)) {
                return swingPrice;
            }
            if(swingPrice < iHigh(Symbol(), Period(), i)) {
                swingPrice = iHigh(Symbol(), Period(), i);
            }
        }
    }
    return 0;

}


double getPreviousDealLost() {

    ulong dealTicket;
    double dealProfit;
    string dealSymbol;
    double dealLost = 0.0;

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


void takeRecoveryTrade(marketEntry entry) {
    if(entry == LONG && expertIsTakingBuyTrade) {

        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(LONG);
        double recoveryPips = ( MathMax(swingPrice, ask) - MathMin(swingPrice, ask) ) / 2;
        double recoveryLotSize = 0.0;

        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 2); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Buy(recoveryLotSize, Symbol(), ask, setRecoveryStopLoss(ask, LONG), ask+recoveryPips, "Recovery");
    }
    if(entry == SHORT && expertIsTakingSellTrade) {

        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        double dealLost = getPreviousDealLost() / -1;
        double swingPrice = recentSwing(SHORT);
        double recoveryPips = ( MathMax(swingPrice, bid) - MathMin(swingPrice, bid) ) / 2;
        double recoveryLotSize = 0.0;

        if( (dealLost/recoveryPips) < smallestLotSize ) { recoveryLotSize = smallestLotSize; }
        else if( (dealLost/recoveryPips) > biggestLotSize ) { recoveryLotSize = biggestLotSize; }
        else { recoveryLotSize = NormalizeDouble(dealLost/recoveryPips, 2); }

        trade.SetExpertMagicNumber(EXPERT_MAGIC);
        trade.Sell(recoveryLotSize, Symbol(), bid, setRecoveryStopLoss(bid, SHORT), bid-recoveryPips, "Recovery");
    }
}



void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= uptrendTakeProfit && uptrendTakeProfit ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -uptrendStopLoss && uptrendStopLoss) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= downtrendTakeProfit && downtrendTakeProfit) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -downtrendStopLoss && downtrendStopLoss ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}

void close_all_positions() {
    if(PositionsTotal() > 0) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
        }
    }
}



void close_trade(marketSignal signal) {
    if(PositionsTotal() && signal == BUY) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
    if(PositionsTotal() && signal == SELL) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}

void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= uptrendTakeProfit && uptrendTakeProfit ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -uptrendStopLoss && uptrendStopLoss) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= downtrendTakeProfit && downtrendTakeProfit) {
                trade.PositionClose(PositionGetSymbol(i));
            }
            if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) <= -downtrendStopLoss && downtrendStopLoss ) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}



void tradeManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(uptrendTakeProfit && (PositionGetDouble(POSITION_PROFIT) / lotSize) >= uptrendTakeProfit) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(downtrendStopLoss && ( PositionGetDouble(POSITION_PROFIT) / lotSize ) <= -downtrendStopLoss) {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
}


// void trade_management() {
//     if(PositionsTotal()) {
//         for(int i = PositionsTotal()-1; i >= 0; i--) {
//             PositionGetSymbol(i);
//             if(PositionGetDouble(POSITION_PROFIT) >= takeProfit) {
//                 trade.PositionClose(PositionGetSymbol(i));
//             }
//         }
//     }
// }
4

/* ##################################################### Trade Position Manager ##################################################### */
void tradePositionManager() {
    for(int i = PositionsTotal()-1; i >= 0; i--) {
        PositionGetSymbol(i);
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(PositionGetDouble(POSITION_PROFIT) >= tradeExpectedTakeProfit()) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= tradeExpectedStopLoss()) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(PositionGetDouble(POSITION_PROFIT) >= tradeExpectedTakeProfit()) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
            if(PositionGetDouble(POSITION_PROFIT) <= tradeExpectedStopLoss()) {
                ulong ticket = PositionGetTicket(i);
                trade.PositionClose(ticket);
            }
        }
    }
}

double tradeExpectedTakeProfit() { return takeProfit * lotSize; }

double tradeExpectedStopLoss() { return -(stopLoss * lotSize); }