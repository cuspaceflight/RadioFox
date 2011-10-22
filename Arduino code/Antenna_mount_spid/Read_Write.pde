
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
