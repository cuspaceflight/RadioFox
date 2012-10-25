

// function to correctly format the Alpha Spid serial protocol
// azheading & horizheading allow local az & el to be converted into 
// Earth az and el

void moveantenna(int azheading, int horizheading){
        
          int tempAz,tempEl;
       
          // print error messages if az & el are not numerical values or out of rotator range
          if (sscanf(Keystream,"%*s %d %d",&Az,&El)<2){
            Serial.println("!!!!!!! AZ and EL input incorrectly !!!!!!!");
            return; }
          
          if (!(Az > -540 && Az < 540)) {
            Serial.println("!!!!!!! Azimuth not entered with limits !!!!!!!");
            return; }
            
          if (!(El > -40 && El < 200)) {
            Serial.println("!!!!!!! Elevation not entered with limits !!!!!!!");
            return; }
          
          
          // Format for SPID protocol begins with 0x57 then 0x30 + thousands, tens .... of az+360,
          // then 0x01 for 1 degree accuracy then 0x30 + thousands, tens .... of el+360 then 0x01 0x2F and 0x20 to finish
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
                    
          // Move the antenna, with 8N1 serial using whole movestring
          writestring(antenna_TX,Movestring,600,1,0,0.999,8);      
}


//function to return current position of the antenna mount
void getantennapos(){
          
          // send status request and receive input string
          writestring(antenna_TX,Statusstring,600,1,0,0.999,8);
          readstring(antenna_RX,Status,600,1,0x20);
          
          // decode az & el
          AzPos = (Status[1]*100+Status[2]*10+Status[3]+Status[4]/10)%360;
          ElPos = (Status[6]*100+Status[7]*10+Status[8]+Status[9]/10)%360;
          
}
