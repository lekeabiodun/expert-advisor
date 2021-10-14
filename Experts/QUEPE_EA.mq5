
static datetime timestamp;
int QUEPE = iCustom(_Symbol, _Period, "QUEPE");

int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}


void OnTick(){ 

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
   
      double QUEPEArrayOne[];
      double QUEPEArrayTwo[];
      double QUEPEArrayThree[];
      double QUEPEArrayFour[];
      double QUEPEArrayFive[];
      
      ArraySetAsSeries(QUEPEArrayOne, true);
      ArraySetAsSeries(QUEPEArrayTwo, true);
      ArraySetAsSeries(QUEPEArrayThree, true);
      ArraySetAsSeries(QUEPEArrayFour, true);
      ArraySetAsSeries(QUEPEArrayFive, true);
      
      CopyBuffer(QUEPE, 0, 0, 5, QUEPEArrayOne);
      CopyBuffer(QUEPE, 1, 1, 2, QUEPEArrayTwo);
      CopyBuffer(QUEPE, 2, 0, 5, QUEPEArrayThree);
      CopyBuffer(QUEPE, 3, 0, 5, QUEPEArrayFour);
      CopyBuffer(QUEPE, 9, 0, 2, QUEPEArrayFive);
      
      Print("QUEPE 0: ",QUEPEArrayOne[0]);
      Print("QUEPE 1: ",QUEPEArrayOne[1]);
      Print("QUEPE 1: ",QUEPEArrayOne[2]);
      Print("QUEPE 1: ",QUEPEArrayOne[3]);
      
      Print("QUEPE 2: ",QUEPEArrayTwo[1]);
      Print("QUEPE 3,0: ",QUEPEArrayThree[0]);
      Print("QUEPE 3,1: ",QUEPEArrayThree[1]);
      Print("QUEPE 3,2: ",QUEPEArrayThree[2]);
      Print("QUEPE 3,3: ",QUEPEArrayThree[3]);
      Print("QUEPE 4,0: ",QUEPEArrayFour[0]);
      Print("QUEPE 4,1: ",QUEPEArrayFour[1]);
      Print("QUEPE 4,2: ",QUEPEArrayFour[2]);
      Print("QUEPE 4,3: ",QUEPEArrayFour[3]);
      
      Print("QUEPE 5,0: ",QUEPEArrayFive[0]);
//      Print("QUEPE 5: ",QUEPEArray[5]);
//      Print("QUEPE 6: ",QUEPEArray[6]);
//      Print("QUEPE 7: ",QUEPEArray[7]);
//      Print("QUEPE 8: ",QUEPEArray[8]);
//      
   
      
   
   }


}
  