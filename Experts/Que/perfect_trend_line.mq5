// input group                                       "============ Perfect Trend Line Settings ===============";
// input int inpFastLength = 3; // Fast length
// input int inpSlowLength = 7; // Slow length
// int PTLHandle = iCustom(NULL, 0, "SPTL2", inpFastLength, inpSlowLength);

// bool perfect_trendline_signal(marketSignal signal)
// {
//     double up[], down[], PTLArray[];
//     ArraySetAsSeries(up, true);
//     ArraySetAsSeries(down, true);
//     ArraySetAsSeries(PTLArray, true);
//     CopyBuffer(PTLHandle,5,1,3,up); 
//     CopyBuffer(PTLHandle,6,1,3,down);
//     CopyBuffer(PTLHandle,7,1,3,PTLArray);
//     bool _Buy  = (MathMax(up[0],down[0]) < iOpen(NULL,Period(),1) && MathMax(up[1],down[1]) >= iOpen(NULL,Period(),2));  
//     bool _Sell = (MathMin(up[0],down[0]) > iOpen(NULL,Period(),1) && MathMin(up[1],down[1]) <= iOpen(NULL,Period(),2));
//     if(signal == BUY && PTLArray[0] != EMPTY_VALUE && _Buy) 
//     { 
//         close_opposite_trade(LONG);
//         Print("PTL BUY");
//         return true; 
//     }
//     if(signal == SELL && PTLArray[0] != EMPTY_VALUE && _Sell) 
//     { 
//         close_opposite_trade(SHORT);
//         return true; 
//     }
//     return false;
// }


input group                                       "============ Perfect Trend Line Settings ===============";
input int inpFastLength = 3; // Fast length
input int inpSlowLength = 7; // Slow length
int PTLHandle = iCustom(NULL, 0, "SPTL2", inpFastLength, inpSlowLength);

bool perfect_trendline_signal(marketSignal signal)
{
    double PTLArray[];
    ArraySetAsSeries(PTLArray, true);
    CopyBuffer(PTLHandle,7,1,3,PTLArray);
    if(signal == BUY && PTLArray[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1) )
    {
        return true; 
    }
    if(signal == SELL && PTLArray[0] != EMPTY_VALUE && iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1) )
    {
        return true; 
    }
    return false;
}
