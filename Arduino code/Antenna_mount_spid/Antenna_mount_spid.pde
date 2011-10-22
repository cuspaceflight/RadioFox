#include <WString.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int ledPin = 13;    // LED connected to digital pin 13
int antenna_RX = 8;
int antenna_TX = 7;
int GPSoutput = 2;
char Keystream[70];
char dataformat[6] = "GPGGA"; //format to recognise GPS string
char Stopstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x0F,0x20,0};
char Movestring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x2F,0x20,0};
char Statusstring[14] = {0x57,0x30,0x30,0x30,0x30,0x01,0x30,0x38,0x37,0x36,0x01,0x1F,0x20,0};
char Status[13], Command[9];
int Az, El, AzManOfst , ElManOfst, NorthOfst, HorizOfst,Sats;
float AzPos,ElPos,lat,lon;
int alt=0;
float GPStime=0.0;
int decode=0;

void setup()                    // run once, when the sketch starts
{

  pinMode(ledPin, OUTPUT);      // sets the digital pin as output
  pinMode(antenna_RX,INPUT);    // sets input if we wanted to read from the antenna mount
  pinMode(antenna_TX,OUTPUT);
  pinMode(GPSoutput,INPUT);   //GPS data line
  
  Serial.begin(9600);           // begin serial ouput to computer at bps rate
  Serial.println("Program has begun!!");
  Serial.println("Upload antenna position when ready"); 
  
  //Set offsets initially to zero
  AzManOfst = 0;
  ElManOfst = 0;
  NorthOfst = 0;
  HorizOfst = 0;
  
  // initialise contact with spid and stop it
  writestring(antenna_TX,Stopstring,240,20,600,1);
  
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
              i=0;
              while(i<6 && decode==0) {
                getGPS();
                if (decode>0)
                  processGPS();  
                i++; 
              }  
              if (decode==0)
                Serial.print("0.0 0.0 0");
              decode=0;  
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







 
  
