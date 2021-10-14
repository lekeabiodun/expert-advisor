int fileHandle = FileOpen("text.txt", FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON);
int OnInit()
{
    
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   
}


void OnTick()
{
    //string filePath = "C:\\Users\\Algorithm\\Desktop\\BOOM\\text.txt"; // C:\Users\Algorithm\Desktop\BOOM
    
    string filePath = "C//Users//Algorithm//Desktop//BOOM//text.txt"; // C:\Users\Algorithm\Desktop\BOOM
    

    if(fileHandle != INVALID_HANDLE)
    {
        Print("Opened");
        FileWriteString(fileHandle, "Test \r\n");
        FileWriteString(fileHandle, "Testes Megoo \r\n");
        FileWriteString(fileHandle, "Loogogogo \r\n");
    }
    if(FileIsExist(filePath))
    {
        Print("Yes");
        
    }
    FileClose(fileHandle);

}

