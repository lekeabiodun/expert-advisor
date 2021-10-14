
int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
void OnTick()
{
    tradeCurrentTime = (int)TimeCurrent();

    if(tradeCurrentTime - tradeStartTime >= 5) 
    { 
        tradeStartTime = tradeCurrentTime;
        Print("Symbol Name: ", Symbol());
        Print("Symbol point value: ", SymbolInfoDouble(Symbol(), SYMBOL_POINT));
        Print("Value of SYMBOL_TRADE_TICK_VALUE_PROFIT: ", SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE));
        Print("Minimal price change: ", SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE));
        Print("Minimal volume for a deal: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN));
        Print("Maximal  volume for a deal: ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX));
        Print("Maximum allowed aggregate : ", SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_LIMIT));
        Print("The underlying asset of a derivative: ", SymbolInfoString(Symbol(), SYMBOL_BASIS));
        Print("Symbol description: ", SymbolInfoString(Symbol(), SYMBOL_DESCRIPTION));
        Print("Feeder of the current quote(BANK): ", SymbolInfoString(Symbol(), SYMBOL_BANK));
        Print("The name of the exchange in which the financial symbol is traded: ", SymbolInfoString(Symbol(), SYMBOL_EXCHANGE));
        Print("The formula used for the custom symbol pricing: ", SymbolInfoString(Symbol(), SYMBOL_FORMULA));
    }
}