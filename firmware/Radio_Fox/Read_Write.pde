//Function to write a byte using a serial protocol, based on 8 bit sending.
// stopbits and baud rates can be varied. Not recommended for bauds < 200
//as delayMicroseconds becomes really innaccurate. Use SlowSerialwrite for these situations
// "factor" is a bodge as Ed's radio (ICOM 7000) elongates binary 1 (not 0) when going through the
// CW keying


void SSerialwrite(int pin_no, char data,int baud, float stopbit, float factor, int bits)
{
  byte mask;
  int timestep; // in microseconds
  
  timestep=(int) (1000000/baud);
  
  //startbit 
  digitalWrite(pin_no,LOW);
  delayMicroseconds(timestep);
  
  for (mask = 0x01; mask >0;mask <<=1) {       //this part for 8 bit mask >0; mask <<= 1) 
    if (data & mask){ // choose bit
     digitalWrite(pin_no,HIGH); // send high value
     delayMicroseconds((int) (timestep*factor));    // bodge here as Ed's radio changes bit
     digitalWrite(pin_no,LOW);                      // width of 1's.
     delayMicroseconds((int)(timestep*(1-factor)));
    }
    else{
     digitalWrite(pin_no,LOW); // send low value
     delayMicroseconds(timestep);
    }
  }
  
  //stop bit 
  digitalWrite(pin_no, HIGH);
  delayMicroseconds((int) (timestep*stopbit));
}



//Function to read via 8-bit serial, here again for faster baud rates as delayMicroseconds used.


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

//function to write a full string via serial. Offset from start of string also possible

void writestring(int pin_no,char *str, int baud, float stopbit, int start, float factor, int bits)
{
  int j=0+start;
  
  while (str[j] != 0 ){
    SSerialwrite(pin_no, str[j], baud, stopbit, factor, bits);
    j++;
  }
}




int readstring(int pin_no,char *str, int baud, float stopbit, int endcond)
{
  int j=0;
  
while ((str[j-1] != endcond) && (j!=89)){
    str[j] = SSerialread(pin_no,baud, stopbit);
    j++;
  }
  if (j==89){
    endstring=0; }
  else {
    endstring=1;}
    
    
  return j;
}

//function for 7-bit serial at baud<200

void SlowSerialwrite(int pin_no, char data,int baud, float stopbit, float factor, int bits)
{
  byte mask;
  int timestep; // in microseconds
  
  timestep=(int) (1000/baud);
  
  //startbit 
  digitalWrite(pin_no,LOW);
  delay(timestep);
  
  for (mask = 0x01; mask <=64;mask <<=1) {       //this part for 7 bit mask 
    if (data & mask){ // choose bit
     digitalWrite(pin_no,HIGH); // send high value
     delay((int) (timestep*factor));    // bodge here as Ed's radio changes bit
     if (!data & (mask << 1))            // width of 1's.
        digitalWrite(pin_no,LOW);        // only apply this if a zero is following              
     delay((int)(timestep*(1-factor)));
    }
    else{
     digitalWrite(pin_no,LOW); // send low value
     delay(timestep);
    }
  }
  //stop bit 
  digitalWrite(pin_no, HIGH);
  delay((int) (timestep*stopbit));
}



void slowwritestring(int pin_no,char *str, int baud, float stopbit, int start, float factor, int bits)
{
  int j=0+start;
  
  while (str[j] != 0 ){
    SlowSerialwrite(pin_no, str[j], baud, stopbit, factor, bits);
    Serial.print(str[j]);
    j++;
  }
  Serial.println();
}
