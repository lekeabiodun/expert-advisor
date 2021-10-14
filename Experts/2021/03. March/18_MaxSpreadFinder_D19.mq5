int OnInit() { return(INIT_SUCCEEDED); }

void OnDeinit(const int reason) { 
    Print("Max: ", maxspread); 
    Print("Min: ", minspread); 
}

double maxspread = 0;
double minspread = 10;

void OnTick() 
{
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
    double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
    // double spread = MathMax(ask, bid) - MathMin(bid, ask);
    double spread = (MathMax(ask, bid) - MathMin(bid, ask)) * MathPow(10, _Digits);

    maxspread = MathMax(maxspread, spread);

    minspread = MathMin(minspread, spread);

    // Print("Ask: ", ask);
    // Print("Bid: ", bid);
    // Print("Diff: ", spread);

    return;
}

