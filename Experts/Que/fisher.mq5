
input group                                       "============  Fisher Settings  ===============";
input bool                                         FisherFactor = true; // Use signal Fisher
input int                                          FisherPeriod = 10; // Fisher Period

int FisherHandle = iCustom(Symbol(), Period(), "Dump/Fisher", FisherPeriod);

bool fisher_signal(marketSignal signal)
{
    if(!FisherFactor) return true;
    double FisherArray[];
    ArraySetAsSeries(FisherArray, true);
    CopyBuffer(FisherHandle, 0, 0, 3, FisherArray);
    if(signal == BUY && FisherArray[0] > 0)  { Print("Fisher Signal true"); return true; }
    if(signal == SELL && FisherArray[0] < 0) { return true; }
    return false;
}