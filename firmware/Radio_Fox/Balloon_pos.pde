/*
// function to poin the antenna at the balloon GPS location

void balloonpos()  {
  
  float Ball_lat, Ball_lon, Ball_alt, angle,dist,x1,x2,y1,y2,z1,z2;
  int head;
  int Rearth= 6378100;
  
    // print error messages if az & el are not numerical values or out of rotator range
    if (sscanf(Keystream,"%*s %f %f %f",&Ball_lat,&Ball_lon,&Ball_alt)<2){
         Serial.println("!!!!!!! Balloon GPS input incorrectly !!!!!!!");
         return; }
         
    // work out heading     
    head = (int) mod(atan2(sin(Ball_lon-lon)*cos(Ball_lat),
           cos(lat)*sin(Ball_lat)-sin(lat)*cos(Ball_lat)*cos(Ball_lon-lon)),
           2*pi);
           
    // work out elevation
    x1=(Rearth+alt)*sin(lon*pi/180)*cos(-lat*pi/180);
    y1=(Rearth+alt)*sin(lon*2*pi)*sin(-lat*pi/180);
    z1=(Rearth+alt)*cos(-lat*pi/180);
    x2=(Rearth+Ball_alt)*sin(Ball_lon*pi/180)*cos(-Ball_lat*pi/180);
    y2=(Rearth+Ball_alt)*sin(Ball_lon*pi/180)*sin(-Ball_lat*pi/180);
    z2=(Rearth+Ball_alt)*cos(-Ball_lat*pi/180);    
    
    
    crosspr = sqrt( (y1*z2 -z1*y2)^2 + (z1*x2 - x1*z2)^2 + (x1*y2-x2*y1)^2);
    angle = asin( (crosspr)/((Rearth+Ball_alt)*(Rearth+alt));
    
    dist= sqrt( (Rearth+Ball_alt)^2 + (Rearth+alt)^2 - 2*(Rearth+alt)*(Rearth+Ball_alt)*cos(angle));
    El = asin( sin(angle)*(Rearth+Ball_alt)/dist)*180/pi - 90;
 
  
}*/
