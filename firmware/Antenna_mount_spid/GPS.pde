
extern int alt;
extern float lat,lon;
extern float GPStime;



///// FUNCTION TO GET GPS VALUE
void getGPS(){
    char  GPSstring[90];
    int count,i;
    double rawlat,rawlon;
     
     decode=0;
       
      // get to $ start of a string
      readstring(GPSoutput,GPSstring,4800,2,'$');
       
       // now record GPS string
      count = readstring(GPSoutput,GPSstring,4800,2,'$'); 
      GPSstring[count-1] = 0;     
  /*    for(i=0;i<count-1;i++)
        Serial.print(GPSstring[i]);
      Serial.println();   */
      
              
    // Compare GPS string and get values from it
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
      
      decode=1;

      }    
          
                               
        }                
      

}


// CONVERT RAW DPS DATA FROM MINUTES AND SECONDS INTO DECIMAL VALUES

void processGPS(){
  char temp[100];
  
      int latst= (int) lat;
      int latend= (int)((lat- latst)*10000);
      int lonst= (int) lon;
      int lonend= (lon- lonst)*10000;
      int GPShr = (int) (GPStime/10000)  +  1;   // here for british summertime !!
      int GPSmin = (int) ((GPStime/100-(GPShr-1)*100)) ;  // here for british summertime !!
      int GPSsec = (int) (GPStime-(GPShr-1)*10000-GPSmin*100); // here for british summertime !!
      
      
      Serial.print(latst);
      Serial.print(".");
      Serial.print(latend);
      Serial.print(" ");
      Serial.print(lonst);
      Serial.print(".");
      Serial.print(lonend);
      Serial.print(" ");      
      Serial.println(alt);          
  
  
}




   // sscanf(GPSstring,"GPGGA,%d.%*d,%d.%d,%1c,%d.%d,%1c,%*d,%d,%*d.%*d,%d.%*d,%*s",&GPStime,&latbig,&latsm,&NorS,&lonbig,&lonsm,&EorW,&Sats,&alt);
    //%*u.%*u,%u.%*u,%*s",&GPStime,&latbig,&latsm,NorS,&lonbig,&lonsm,EorW,&Sats,&Alt) >1 )    {
