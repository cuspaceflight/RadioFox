
// function to write CW via radio

void uplink(int offset) {
  
  // set PTT high on pin PC2
  digitalWrite(PTT,HIGH);
  
  //start carrier
 digitalWrite(Keyoutput,HIGH);
 delay(1000);
 slowwritestring(Keyoutput, Keystream,55,1,10+offset,0.8,7);
 
 //set PTT low
 digitalWrite(PTT,LOW);
  
 digitalWrite(Keyoutput,LOW);
 delay(1000);
    
}
