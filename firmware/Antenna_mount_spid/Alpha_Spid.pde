

void moveantenna(int azheading, int horizheading){
        
          int tempAz,tempEl;
       
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
