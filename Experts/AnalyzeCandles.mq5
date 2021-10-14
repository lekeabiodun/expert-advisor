
static datetime timestamp_M1;
static datetime timestamp_D1;
static datetime timestamp_W1;

int count = 0;
string store = "";
int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("String Len: ", StringLen(store));
   Print(store);
   Print("DOne"); 
}

void OnTick()
{
   datetime time_M1 = iTime(Symbol(), PERIOD_M1, 0);
   datetime time_D1 = iTime(Symbol(), PERIOD_D1, 0);
   datetime time_W1 = iTime(Symbol(), PERIOD_W1, 0);
   
   if(timestamp_M1 != time_M1) {
   
        timestamp_M1 = time_M1;
      
        MqlRates PriceInformation[];
        ArraySetAsSeries(PriceInformation, true);
        int data = CopyRates(Symbol(), Period(), 0, 3, PriceInformation);
        
        if(PriceInformation[1].close > PriceInformation[1].open)
        {
            StringAdd(store, "B");
        }  
        if(PriceInformation[1].close < PriceInformation[1].open)
        {
            StringAdd(store, "S");
        }
   }
   
   //if(timestamp_D1 != time_D1) {
   //     timestamp_D1 = time_D1;
   //     Print(store);
   //     store = "";
   //}
   
   //if(timestamp_W1 != time_W1) {
   //     timestamp_W1 = time_W1;
   //     Print(store);
   //     store = "";
   //}
   

}

