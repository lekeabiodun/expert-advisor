static datetime timestamp;

int sellCount = 0;
int buyCount = 0;
int totalCount = 0;

double sellPips = 0;
double buyPips = 0;
double totalPips = 0;

// double sellCount = 0.0;
// double buyCount = 0.0;


void OnDeinit(const int reason)
{
    totalPips = buyPips + sellPips;
    Print("Sell Count: ", sellCount);
    Print("Buy Count: ", buyCount);
    Print("Total Count: ", totalCount);
    Print("############################");
    Print("Sell Pips: ", sellPips);
    Print("Buy Pips: ", buyPips);
    Print("Total Pips: ", totalPips);
}

void OnTick() 
{
    datetime time = iTime(Symbol(), Period(), 0);

    if(timestamp != time)
    {
        timestamp = time;

        totalCount = totalCount + 1;

        if( iOpen(Symbol(), Period(), 1) > iClose(Symbol(), Period(), 1))
        {
            sellCount = sellCount + 1;
            sellPips = sellPips + iHigh(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1);
        }
        
        if( iOpen(Symbol(), Period(), 1) < iClose(Symbol(), Period(), 1))
        {
            buyCount = buyCount + 1;
            buyPips = buyPips + iHigh(Symbol(), Period(), 1) - iLow(Symbol(), Period(), 1);

        }

    }

}