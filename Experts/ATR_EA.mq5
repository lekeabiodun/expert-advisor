

static datetime timestamp;
int ATR = iCustom(NULL, 0, "Step_Average_ATR");

void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
      double ATRArray[];

      ArraySetAsSeries(ATRArray, true);
   
      CopyBuffer(ATR, 0,1,3,ATRArray);
      
      Print("PTL 0: ",ATRArray[2]);
      //Print("PTL 1: ",PTLArray[1]);
      //Print("PTL 2: ",PTLArray[2]);
      //Print("PTL 3: ",PTLArray[3]);
      //Print("PTL 4: ",PTLArray[4]);
      //Print("PTL 5: ",PTLArray[5]);
      //Print("PTL 6: ",PTLArray[6]);
      //Print("PTL 7: ",PTLArray[7]);
      //Print("PTL 8: ",PTLArray[8]);
      
      //int NUM = 0;
      
      //Print("PTL ",NUM, ": ",PTLArray[NUM]);
      
      //Print("PTL 0: ",PTLArray[0]);
      //Print("PTL 1: ",PTLArray[1]);
      //Print("PTL 2: ",PTLArray[2]);
   
   //Print("PTL 6: ",PTLArray[6]);
//      if(PTLArray[0] != EMPTY_VALUE){
//         Print("Trend Change");
//         
//   
//      }
//      Print("EMPTY: ", EMPTY_VALUE);
//      Print("DBL  : ", DBL_MAX);

//      
   }

}