
extern int alt;
extern float lat,lon;
extern float GPStime;



///// FUNCTION TO GET GPS VALUE, but this program is limited strongly by the stack memory.
// use of strtod etc. uses lots of RAM so decode is in separate function
void getGPS(){
    char  GPSstring[90];
    int count,i;
    double rawlat,rawlon;
     
     decode=0;
      
     
      // get to $ start of a string
      endstring=0;
      readstring(GPSoutput,GPSstring,4800,2,'$');
 //     if (endstring==0){
 //       Serial.println("crap");
 //       Serial.println(GPSstring);}
      while (endstring==0){
         readstring(GPSoutput,GPSstring,4800,2,'$');
 //            if (endstring==0){
 //       Serial.println("crap");
 //       Serial.println(GPSstring);}
      }
      endstring=0;   
      
       // now record GPS string
      count = readstring(GPSoutput,GPSstring,4800,2,13); 
      GPSstring[count-1] = 0;     
 //     for(i=0;i<count-1;i++){
 //       Serial.print(GPSstring[i]);}
 //     Serial.println();
      
      
              
    // Compare GPS string against NMEA GPs string and get values from it
    //strtok cuts up the string based on the "," divider
    // strtod then converts the string to a float
    // sadly sscanf blows the stack!!

    if (strncmp(GPSstring, dataformat, 5) == 0 && count>4) {
  
      char * pch;
      pch = strtok (GPSstring,",");
      
      for(i=0;i<10;i++)
      {
        pch = strtok (NULL, ",");

       if (i==0){       
          GPStime = atof(pch); 

        }
         if (i==1) {                         // if clauses to choose part of string 
          rawlat = strtod(pch,NULL);
          lat = (int)(rawlat/100);
          lat += (rawlat - lat*100)/60;
        }
        if (i==2 && *pch=='S') {lat=-lat;}
        if (i==3) {
           rawlon = strtod(pch,NULL);
           lon = (int)(rawlon/100);
           lon += (rawlon - lon*100)/60;   
        }
        if (i==4 && *pch=='W') { lon=-lon;}
        if (i==6) { Sats=(int) (strtod(pch,NULL));}
        if (i==8) { alt=(int) (strtod(pch,NULL));}       
      
      // set successful decode value
      decode=1;

      }    
          
                               
        }                
      

}



// FUNCTION TO CONVERT RAW DPS DATA FROM MINUTES AND SECONDS INTO DECIMAL VALUES

void processGPS(int printGPS){
  char temp[100];
  
      int latst= (int) lat;
      int latend= (int)((lat- latst)*10000);
      int lonst= (int) lon;
      int lonend= (lon- lonst)*10000;
      GPShr = (int) (GPStime/10000)  +  1;   // here for british summertime !!
      GPSmin = (int) ((GPStime/100-(GPShr-1)*100)) ;  // here for british summertime !!
      GPSsec = (float) (GPStime-(GPShr-1)*10000.0-GPSmin*100.0); // here for british summertime !!
      
      // output modified GPS values
      if (printGPS == 1) {
      
      Serial.print(latst);
      Serial.print(".");
      Serial.print(latend);
      Serial.print(" ");
      Serial.print(lonst);
      Serial.print(".");
      Serial.print(lonend);
      Serial.print(" ");      
      Serial.print(alt);
//      Serial.print(" ");
//      Serial.print(GPShr);
//      Serial.print(" ");
//      Serial.print(GPSmin);
//      Serial.print(" ");
//      Serial.println((int)GPSsec*1000);
      Serial.print("\n"); 
      }
  
  
}


