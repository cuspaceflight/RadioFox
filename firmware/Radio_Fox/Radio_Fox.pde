//#include <WString.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// define pin numbers, note these are not as numbered on the chip footprint,
// but as on arduino definition
int ledPin = 13;      // LED connected to digital pin 13
int antenna_RX = 6;   
int antenna_TX = 5;  //transmit to antenna 
int GPSoutput = 2;  //GPS chip pin
int Keyoutput = 4; // Gate to mosfet pin
int PTT = 16;    // PTT pin actually on analog in line

char Keystream[100];

// Formats for GPS NMEA string and for Alpha Spid rotator protocol
char dataformat[6] = "GPGGA"; //format to recognise GPS string
char Stopstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x0F,0x20,0};
char Movestring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x2F,0x20,0};
char Statusstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x1F,0x20,0};

char Status[13];
int Az, El, AzManOfst , ElManOfst, NorthOfst, HorizOfst,Sats;
float AzPos,ElPos,lat,lon;
int alt=0;
float GPStime=0.0;
int GPShr, GPSmin;
float GPSsec;
int decode=0;
float pi = 3.141593;
int endstring=0;

void setup()                    // run once, when the sketch starts
{

// define pin I/O status
  pinMode(ledPin, OUTPUT);      // sets the digital pin as output
  pinMode(antenna_RX,INPUT);    // sets input if we wanted to read from the antenna mount
  pinMode(antenna_TX,OUTPUT);
  pinMode(GPSoutput,INPUT);   //GPS data line
  pinMode(Keyoutput,OUTPUT);  // audio jack line to the ICOM radio
  pinMode(PTT,OUTPUT);
 
  // Set PTT to 0 initially
  digitalWrite(PTT,LOW);
  
  Serial.begin(9600);           // begin serial ouput to computer at bps rate
//  Serial.println("Program has begun!!");
//  Serial.println("Upload antenna position when ready"); 
  
  
  //Set offsets initially to zero
  AzManOfst = 0;
  ElManOfst = 0;
  NorthOfst = 0;
  HorizOfst = 0;
  
  // initialise contact with spid and stop it
  writestring(antenna_TX,Stopstring,600,1,0,0.999,8);
  
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
          // add terminating NULL character to form string
          Keystream[i]=0;
          
    // echo command      
    //      for(int j =0;j<i;j++)
    //        Serial.print(Keystream[j]);               
    //      Serial.println("  -  Command Received ");
          
          
          // switch case based on input command
           if (!strncmp(Keystream,"Move_AzEl",9))
               //Move with Azimuth and Elevation
              moveantenna(0,0);
              
           else if (!strncmp(Keystream,"Rqst_Ping",9))
              Serial.println("Pong");
              
           else if (!strncmp(Keystream,"Move_Stop",9))
               //Stop all motion
              writestring(antenna_TX,Stopstring,600,1,0,0.999,8);
              
           else if (!strncmp(Keystream,"Rqst_AzEl",9)) {
               //get antenna position
              getantennapos();
              Serial.println();
              Serial.print("Status - Az ");
              Serial.print(AzPos);
              Serial.print(" El ");
              Serial.print(ElPos); }
              
           else if (!strncmp(Keystream,"Rqst_HeEl",9)) {
               //get antenna position
              getantennapos();
              Serial.println();
              Serial.print("Status - He ");
              Serial.print(AzPos+NorthOfst);
              Serial.print(" El ");
              Serial.print(ElPos+HorizOfst); }
              
           else if (!strncmp(Keystream,"Manu_Ofst",9)){
               // Set the manual ofsets, which are initialised to zero
               if (sscanf(Keystream,"Manu_Ofst %d %d",&AzManOfst,&ElManOfst)<2){
                  Serial.println("!!!!!!! Ofsets input incorrectly !!!!!!!");
                  }   }
           
           else if (!strncmp(Keystream,"Rqst_Ofst",9)) {
               //Reply with offsets
              Serial.print(AzManOfst);
              Serial.print(" ");
              Serial.println(ElManOfst); }
           
           else if (!strncmp(Keystream,"Manu_Algn",9)) {
              //Manually set North and horizontal
              getantennapos();
              NorthOfst = AzPos;
              HorizOfst = ElPos; }
              
           else if (!strncmp(Keystream,"Move_HeEl",9)) {
              //Manually set North and horizontal
              moveantenna(NorthOfst,HorizOfst);    }
              
           else if (!strncmp(Keystream,"Rqst_GPS_",9)){
              //Get GPS co-ordinates
              
              i=0;
              
              while(i<6 && decode==0) {
                getGPS();
                
                if (decode>0)
                  processGPS(1);  
                  
                  
                  i++; }
                // if 6 strings do not return a GPS value, assume no lock yet, output 0's
                // then reset decode value for next loop  
                
                if (decode==0)
                  Serial.println("0.0 0.0 0");
                decode=0;  }
           
           
                
           else if (!strncmp(Keystream,"Uplink___",9)){ 
              //write uplink command
            
              if (Keystream[10]==33){
                uplink(1);}
              else {
                i=0;
              
              //Acknowledge Command
                Serial.print("Command Acknowledged...");
              
              
                while(i<75 && decode==0) {
                  getGPS();

                  // Ackowledge that it's still in loop
                  if ((i%4) == 0){
                  Serial.print(".");}
                 
                  if (decode>0){
                    processGPS(0);  
                 
                    if (((GPSsec>13.4) && (GPSsec<14.4)) || ((GPSsec>33.4) && (GPSsec<34.4)) || ((GPSsec>53.4) && (GPSsec<54.4))) {
                      Serial.print(" ");
                      uplink(0);
                    }
                    else
                      decode=0;
              
                  }
                  i++;
                }
                
                if (i==75){
                  Serial.print(" Time Out");}
                
             }
             decode=0;
           }
              
           else {
              Serial.println();
              Serial.println("!!!!!!! COMMAND NOT RECOGNISED !!!!!!!");     }
          
          
   //       Serial.println();
   //       Serial.println("Command sent - upload new command");
   //       Serial.println();    
   
           // reset Keystream to no input!
           for (i = 0; i < 100; i++){
              Keystream[i]=0;    
           }
           
   
   
       }

   }
}







 
  
