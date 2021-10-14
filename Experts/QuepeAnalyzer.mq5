

static datetime timestamp_M1;
static datetime timestamp_D1;
static datetime timestamp_W1;

int WEEK = 0;
int DAY = 0;
int HOUR = 0;
int MINUTE = 0;
string store = "";

int spikeWeek = 0;
int spikeDay = 0;
int spikeHour = 0;

int fileHandle = FileOpen("boom500.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON, '\t', CP_ACP);

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    FileClose(fileHandle);
}

void OnTick()
{
   datetime time_M1 = iTime(Symbol(), PERIOD_M1, 0);
   datetime time_D1 = iTime(Symbol(), PERIOD_D1, 0);
   datetime time_W1 = iTime(Symbol(), PERIOD_W1, 0);
   
   if(timestamp_W1 != time_W1) {
   
        timestamp_W1 = time_W1;
        
        FileWrite(fileHandle, "WEEK: ", WEEK, ": ", spikeWeek, " spikes this week");
        WEEK++;
        DAY = 0;
        spikeWeek = 0;
   }
   
   
   if(timestamp_D1 != time_D1) {
   
        timestamp_D1 = time_D1;
        
        FileWrite(fileHandle, "DAY: ",DAY, ": ", spikeDay, " spikes toDay", time_D1);
        DAY++;
        HOUR = 0;
        spikeDay = 0;
   }
   
   if(MINUTE == 60) {
   
        FileWrite(fileHandle, "HOUR: ", HOUR);
        FileWrite(fileHandle, store, ": ", spikeHour, " spikes");
        store = "";
        MINUTE = 0;
        spikeHour = 0;
        HOUR++;
   }
      
   
   if(timestamp_M1 != time_M1) {
   
        timestamp_M1 = time_M1;
        MINUTE++;
        
        if(iClose(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1))
        {
            StringAdd(store, "B");
            spikeHour++;
            spikeDay++;
            spikeWeek++;
        }  
        if(iClose(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1))
        {
            StringAdd(store, "S");
        }
   }
    
}