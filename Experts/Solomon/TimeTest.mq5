void OnTick()
{
    MqlDateTime mq;
    datetime date = TimeCurrent();
    TimeToStruct(date,mq);
    datetime timestamp = TimeCurrent();

    
    if(iTime(Symbol(), PERIOD_D1, 0) == iTime(Symbol(), PERIOD_H1, 0))
    {
        Print("QEQ");
        Print("Min: ", mq.min);
    Print("Hour: ", mq.hour);
    Print("Day: ", mq.day);
    Print("Day of week: ", mq.day_of_week);
    Print("Day of Year: ", mq.day_of_year);
    Print("I Time: ", iTime(Symbol(), Period(), 0));
    Print("I Time H1: ", iTime(Symbol(), PERIOD_H1, 0));
    Print("I Time D1: ", iTime(Symbol(), PERIOD_D1, 0));
    Print("TImecurrent: ", TimeCurrent());
    }
}