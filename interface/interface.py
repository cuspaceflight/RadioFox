import wx
from wx import xrc
import wxMeta

import serial
import os
import time
import math

import sched

from urllib import urlopen
from threading import Timer

foo = 3

#s = sched.scheduler(time.time, time.sleep)

def FindPort():

    pingcmd = "Rqst_Ping"
    pingresp = "Pong"
    
    if os.name == 'nt':
        # scan through ports by number
        # for i in range(15):
        if True:
            try:
                s = serial.Serial("COM9", 9600)
                time.sleep(10)
                s.write(pingcmd)
                if s.read(len(pingresp)) == pingresp:
                    s.close()
                    return "COM9"
                s.close()
            except serial.SerialException:
                pass
    else:
        import glob
        ports = glob.glob('/dev/ttyS*') + glob.glob('/dev/ttyUSB*') + glob.glob('/dev/tty.usb*')
        for port in ports:
            try:
                print "Trying serial port in 15 secs: %s" % port
                s = serial.Serial(port, 9600)
                time.sleep(15)
                print "Trying now!"
                s.write(pingcmd)
                if s.read(len(pingresp)) == pingresp:
                    s.close()
                    return port
                s.close()
            except serial.SerialException:
                pass

def balloon_azel(lat,lon,alt,Ball_lat,Ball_lon,Ball_alt):

    Rearth = 6378100
    
    lat=math.radians(lat)
    lon=math.radians(lon)
    Ball_lat=math.radians(Ball_lat)
    Ball_lon=math.radians(Ball_lon)
    

    #work out heading
    head = int(round(  (math.degrees(math.atan2(math.sin(Ball_lon-lon)*math.cos(Ball_lat),
        math.cos(lat)*math.sin(Ball_lat)-math.sin(lat)*math.cos(Ball_lat)*math.cos(Ball_lon-lon)) ) +360) % 360))

    #work out elevation
    x1=(Rearth+alt)*math.sin(math.pi/2-lat)*math.cos(lon)
    y1=(Rearth+alt)*math.sin(math.pi/2-lat)*math.sin(lon)
    z1=(Rearth+alt)*math.cos(math.pi/2-lat)
    x2=(Rearth+Ball_alt)*math.sin(math.pi/2-Ball_lat)*math.cos(Ball_lon)
    y2=(Rearth+Ball_alt)*math.sin(math.pi/2-Ball_lat)*math.sin(Ball_lon)
    z2=(Rearth+Ball_alt)*math.cos(math.pi/2-Ball_lat)

    angle = math.acos((x1*x2 +y1*y2 + z1*z2)/((Rearth+alt)*(Rearth+Ball_alt)) )

    dist= math.sqrt( math.pow((Rearth+Ball_alt),2) + math.pow((Rearth+alt),2) - 2*(Rearth+alt)*(Rearth+Ball_alt)*math.cos(angle))
    El = int(round( - math.degrees(math.asin( math.sin(angle)*(Rearth+Ball_alt)/dist)) + 90 ))

    return (head, El)
    


class UplinkInterface(wxMeta.SimpleApp):
    """Uplink Controller Interface"""
    def Init(self):   
        self.port = FindPort()
        if self.port:
            print "Using serial port: ", self.port
            self.ser =  serial.Serial(self.port, 9600, timeout=1)
        else:
            dlg = wx.MessageDialog(self.controls.main_window, "Plug in the controller, wait till LED lights and then restart the program.", "No uplink controller found!", wx.OK | wx.ICON_EXCLAMATION)
            dlg.ShowModal()
            self.ser = self
            #return False
            
        self.controls.OnClose_main_window = self.CloseMain
        self.controls.OnClick_go = self.SetAzEl
        self.controls.OnClick_stop = self.Stop
        self.controls.OnClick_uplink = self.Uplink
        self.controls.OnClick_bal = self.SetBalloonPos
        self.controls.OnClick_gps = self.GetAntGPS
        
        return True
        
    def write(self, str):
        print str
        
    def close(self):
        pass

    def SetBalloonPos(self, evt):
        lat = float(self.controls.ant_lat.GetValue())
        lon = float(self.controls.ant_lon.GetValue())
        alt = float(self.controls.ant_alt.GetValue())
        Ball_lat = float(self.controls.bal_lat.GetValue())
        Ball_lon = float(self.controls.bal_lon.GetValue())
        Ball_alt = float(self.controls.bal_alt.GetValue())
        print "? lat=%f, lng=%f, alt=%f" % (Ball_lat, Ball_lon, Ball_alt)
        (az, el) = balloon_azel(lat,lon,alt,Ball_lat,Ball_lon,Ball_alt)
        print "? az=%f, el=%f" % (az,el)
        self.controls.ant_az.SetValue(str(az))
        self.controls.ant_el.SetValue(str(el))
        if self.ser:
            self.ser.write("Move_HeEl %d %d" % (az, el))
        if self.controls.update_balloon.IsChecked():
            Timer(20, self.GetLatestBalloonPos, ()).start()
            #s.enter(20, 1, self.GetLatestBalloonPos, ())
            #s.run()
            
    def GetLatestBalloonPos(self):
        print "Fetching latest balloon pos"
        alt = "0"
        #while(int(alt)<5000):
        callsign_wanted = self.controls.callsign.GetValue()
        (callsign, lat,lng,alt) =  urlopen('http://www.robertharrison.org/listen/lastpos.php?callsign=%s' % callsign_wanted).read().split(',')[:4]
        print "Got callsign=%s, lat=%s, lng=%s, alt=%s" % (callsign, lat, lng, alt)
        #print "This ones a keeper"
        if callsign == callsign_wanted:
            print "Callsign match, setting balloon pos"
            self.controls.bal_lat.SetValue(lat)
            self.controls.bal_lon.SetValue(lng)
            self.controls.bal_alt.SetValue(alt)
            self.SetBalloonPos(None)
        else:
            print "Callsign not matched, ignoring"
            self.SetBalloonPos(None)

    def GetAntGPS(self, evt):
        if self.ser:
            self.ser.write("Rqst_GPS_")
            gps_string = ""
            gps_char = ""
            while gps_char != "\n":
                gps_char = self.ser.read(1)
                gps_string += gps_char
            print gps_string
            (lat, lon, alt) = map(float, gps_string.split(" "))
            self.controls.ant_lat.SetValue(str(lat))
            self.controls.ant_lon.SetValue(str(lon))
            self.controls.ant_alt.SetValue(str(alt))
                    
    def CloseMain(self, evt):
        if self.ser:
            self.ser.close()
        self.controls.main_window.Destroy()
        pass
    
    def SetAzEl(self, evt):
        if self.ser:
            self.ser.write("Move_AzEl %d %d" % (int(self.controls.ant_az.GetValue()), int(self.controls.ant_el.GetValue())))

    def Stop(self, evt):
        if self.ser:
            self.ser.write("Move_Stop")
            
    def Uplink(self, evt):
        if self.ser:
            dlg = wx.MessageDialog(self.controls.main_window, "Are you sure you want to uplink the command '%s'?" % self.controls.uplink_string.GetValue(), "Uplink Command", wx.YES_NO | wx.ICON_QUESTION | wx.NO_DEFAULT)
            if dlg.ShowModal() == wx.ID_YES:
                self.ser.write("Uplink___ %s" % str(self.controls.uplink_string.GetValue()))
            
if __name__ == '__main__':
    app = UplinkInterface('interface.xrc', 'main_window')
    app.MainLoop()

