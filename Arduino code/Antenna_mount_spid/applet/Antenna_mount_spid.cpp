#include <WString.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "WProgram.h"
void setup();
void loop();
void SSerialwrite(int pin_no, char data, int highval, int lowval, int baud, float stopbit);
char SSerialread(int pin_no,int baud, float stopbit);
void writestring(int pin_no,char *str, int highval, int lowval, int baud, float stopbit);
int readstring(int pin_no,char *str, int baud, float stopbit, int endcond);
void moveantenna(int azheading, int horizheading);
void getantennapos();
void getGPS();
int ledPin = 13;    // LED connected to digital pin 13
int antenna_RX = 8;
int antenna_TX = 7;
int GPSoutput = 2;
char Keystream[70], GPSstring[90];
char dataformat[6] = "GPGGA"; //format to recognise GPS string
char Stopstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x0F,0x20,0};
char Movestring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x2F,0x20,0};
char Statusstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x1F,0x20,0};
char Status[13], Command[9];
int Az, El, AzManOfst , ElManOfst, NorthOfst, HorizOfst,Sats,alt;
float AzPos,ElPos,lat,lon,GPStime;
int tempAz,tempEl;

void setup()                    // run once, when the sketch starts
{

  pinMode(ledPin, OUTPUT);      // sets the digital pin as output
  pinMode(antenna_RX,INPUT);    // sets input if we wanted to read from the antenna mount
  pinMode(antenna_TX,OUTPUT);
  pinMode(GPSoutput,INPUT);   //GPS data line
  
  Serial.begin(4800);           // begin serial ouput to computer at bps rate
  Serial.println("Program has begun!!");
  Serial.println("Upload antenna position when ready"); 
  
  //Set offsets initially to zero
  AzManOfst = 0;
  ElManOfst = 0;
  NorthOfst = 0;
  HorizOfst = 0;
  
}




void loop()                     // run over and over again
{
  int i;

                
  while (1){

     digitalWrite(ledPin, HIGH); // flash to show working
     
     //Don't do anything until we have a computer input command
	if (Serial.available() > 0) {
            delay(100);
            i=0;
            while (Serial.available()>0){
                
		// read the incoming byte:
		Keystream[i] = Serial.read();
                i++;
	    }
          Keystream[i]=0;
          
          
          for(int j =0;j<i;j++)
            Serial.print(Keystream[j]);    
            
          Serial.println("  -  Command Received ");
          
          // define command type
          strncpy(Command,Keystream,9);
          Serial.println(Command);
          
          // switch case based on input command
           if (!strncmp(Command,"Move_AzEl",9))
               //Move with Azimuth and Elevation
              moveantenna(0,0);
           else if (!strncmp(Command,"Move_Stop",9))
               //Stop all motion
              writestring(antenna_TX,Stopstring,240,20,600,1);
           else if (!strncmp(Command,"Rqst_AzEl",9))
               //get antenna position
              getantennapos();
           else if (!strncmp(Command,"Manu_Ofst",9)){
               // Set the manual ofsets, which are initialised to zero
               if (sscanf(Keystream,"Manu_Ofst %d %d",&AzManOfst,&ElManOfst)<2){
                  Serial.println("!!!!!!! Ofsets input incorrectly !!!!!!!");
                  }
           }
           else if (!strncmp(Command,"Rqst_Ofst",9)) {
               //Reply with offsets
              Serial.print(AzManOfst);
              Serial.print(" ");
              Serial.println(ElManOfst); }
           else if (!strncmp(Command,"Manu_Algn",9)) {
              //Manually set North and horizontal
              getantennapos();
              NorthOfst = AzPos;
              HorizOfst = ElPos; }
           else if (!strncmp(Command,"Move_HeEl",9)) {
              //Manually set North and horizontal
              moveantenna(NorthOfst,HorizOfst);    }
           else if (!strncmp(Command,"Rqst_GPS_",9)){
              //Get GPS co-ordinates
              getGPS();   
           }
           else {
              Serial.println();
              Serial.println("!!!!!!! COMMAND NOT RECOGNISED !!!!!!!");     }
          
          
          Serial.println();
          Serial.println("Command sent - upload new command");
          Serial.println();    
       }

     digitalWrite(ledPin,LOW);  // blink LED pin 13
   }
}



void SSerialwrite(int pin_no, char data, int highval, int lowval, int baud, float stopbit)
{
  byte mask;
  int timestep; // in microseconds
  
  // now NOT 64 as no change to clock rate
  timestep=(int) (1000000/baud);
  
  //startbit removed
  analogWrite(pin_no,lowval);
  delayMicroseconds(timestep);
  for (mask = 0x01; mask >0;mask <<=1) {       //this part for 8 bit mask >0; mask <<= 1) 
    if (data & mask){ // choose bit
     analogWrite(pin_no,highval); // send high value
     delayMicroseconds((int) (timestep));
    }
    else{
     analogWrite(pin_no,lowval); // send low value
     delayMicroseconds(timestep);
    }
  }
  //stop bit removed
  analogWrite(pin_no, highval);
  delayMicroseconds((int) (timestep*stopbit));
}


char SSerialread(int pin_no,int baud, float stopbit)
{
  byte val = 0;
  int timestep = 1000000/baud -20; // in microseconds
  
  while (digitalRead(pin_no));
  //wait for start bit
  if (digitalRead(pin_no) == LOW) {
    delayMicroseconds((int) (timestep/2));
    
    //start reading
    for (int offset = 0; offset < 8; offset++) {
     delayMicroseconds(timestep);
     val |= digitalRead(pin_no) << offset;
    }
    //wait for stop bit
    delayMicroseconds((int)(timestep*stopbit));
    return val;
  }
  
}



void writestring(int pin_no,char *str, int highval, int lowval, int baud, float stopbit)
{
  int j=0;
  
  while (str[j] != 0 ){
    SSerialwrite(pin_no, str[j], highval, lowval, baud, stopbit);
    j++;
  }
  
}




int readstring(int pin_no,char *str, int baud, float stopbit, int endcond)
{
  int j=0;
  
while (str[j-1] != endcond){
    str[j] = SSerialread(pin_no,baud, stopbit);
    j++;
  }
  return j;
}



void moveantenna(int azheading, int horizheading){
       
       
          if (sscanf(Keystream,"%*s %d %d",&Az,&El)<2){
            Serial.println("!!!!!!! AZ and EL input incorrectly !!!!!!!");
            return; }
          
          
          // Bit of error checking
          if (!(Az > -540 && Az < 540)) {
            Serial.println("!!!!!!! Azimuth not entered with limits !!!!!!!");
            return; }
          if (!(El > -40 && El < 200)) {
            Serial.println("!!!!!!! Elevation not entered with limits !!!!!!!");
            return; }
          
          // Format for SPID protocol
          tempAz = (int)(Az+360 + AzManOfst +azheading);
          tempEl = (int)(El+360 + ElManOfst +horizheading);
          
          Movestring[1]= (tempAz/1000) +0x30;
          tempAz %=1000;
          Movestring[2]= (tempAz/100) +0x30;
          tempAz %=100;
          Movestring[3]= (tempAz/10) +0x30;
          tempAz %=10;
          Movestring[4]= (tempAz) +0x30;
          
          Movestring[6]= (tempEl/1000) +0x30;
          tempEl %=1000;
          Movestring[7]= (tempEl/100) +0x30;
          tempEl %=100;
          Movestring[8]= (tempEl/10) +0x30;
          tempEl %=10;
          Movestring[9]= (tempEl) +0x30;
          
      /*    for(int j =0;j<14;j++){
            Serial.print(Movestring[j],HEX);
            Serial.print(" ");  }
          Serial.print (" -  tried to move to");   */
          
          // Move the antenna
          writestring(antenna_TX,Movestring,240,20,600,1);      
}




void getantennapos(){
          
          writestring(antenna_TX,Statusstring,240,20,600,1);
          readstring(antenna_RX,Status,600,1,0x20);
          
          AzPos = (Status[1]*100+Status[2]*10+Status[3]+Status[4]/10)%360;
          ElPos = (Status[6]*100+Status[7]*10+Status[8]+Status[9]/10)%360;
          
          Serial.println();
          Serial.print("Status - Az ");
          Serial.print(AzPos);
          Serial.print(" El ");
          Serial.print(ElPos);
}




///// FUNCTiON TO GET GPS VALUE
void getGPS(){
    
    int count,i;
    lat=0;
    lon=0;
    alt=0;
       
      // get to $ start of a string
      readstring(GPSoutput,GPSstring,4800,2,'$');
       
       // now record GPS string
      count = readstring(GPSoutput,GPSstring,4800,2,'$');      
      for(i=0;i<count-1;i++)
        Serial.print(GPSstring[i]);
      Serial.println();
      


   // sscanf(GPSstring,"GPGGA,%d.%*d,%d.%d,%1c,%d.%d,%1c,%*d,%d,%*d.%*d,%d.%*d,%*s",&GPStime,&latbig,&latsm,&NorS,&lonbig,&lonsm,&EorW,&Sats,&alt);
    //%*u.%*u,%u.%*u,%*s",&GPStime,&latbig,&latsm,NorS,&lonbig,&lonsm,EorW,&Sats,&Alt) >1 )    {
              
    // Compare GPS string and get values from it
    if (strncmp(GPSstring, dataformat, 5) == 0 && count>4) {
       Serial.print("here!!!");   
      char * pch;
      pch = strtok (GPSstring,",");
      Serial.print("here2");
      i=0;
      while (pch != NULL)
      {
        pch = strtok (NULL, ",");
        Serial.print("here3");
        if (i==0){
          GPStime = strtod(pch,NULL); 
        //  Serial.print("here3");
        //  Serial.println(GPStime);
        }
        if (i==1) {                         // if clauses to choose part of string 
          float rawlat = strtod(pch,NULL);
          lat = (int)(rawlat/100);
          lat += (rawlat - lat*100)/60;
        }
        if (i==2 && *pch=='S') {lat=-lat;}
        if (i==3) {
           float rawlon = strtod(pch,NULL);
           lon = (int)(rawlon/100);
           lon += (rawlon - lon*100)/60;   
        }
        if (i==4 && *pch=='W') { lon=-lon;}
        if (i==6) { Sats=(int) (strtod(pch,NULL));}
        if (i==8) { alt=(int) (strtod(pch,NULL));}
      i++;

      }
      
    

          
                      
                         
            Serial.print("GPS DATA ");
            Serial.print(lat);
            Serial.print(" ");
            Serial.print(lon);
            Serial.print(" ");
            Serial.print(alt);           
                         
        }                
                        return;

}
  
  

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

