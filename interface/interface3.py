from Tkinter import *;

import serial
import os
import time
import math
import json

# These are value placeholders for controls
# Create a textbox, say:
# ent = Entry(root, textvariable=var)
# ent.grid()
#
# and retrieve the values using:
#	var.get()
#
callsign = StringVar()
balloonPositions = []

def UpdateBalloonPositionList (lat, long, alt):
	pass

def UpdateRotatorPositionList (lat, long, alt):
	pass

def UpdateGraphics (lat, long, alt):
	pass

def SendAlert:
	pass

def FetchBalloonPosition:
	global app
	global callsign
	global balloonPositions
	
	print "Fetching latest balloon pos"
	alt = "0"
	callsign_wanted = callsign.get()
	url = "http://habitat.habhub.org/habitat/_design/habitat/_view/" +
		"payload_telemetry?startkey=[%22{0}%22,%22latest%22]&descending=true&limit=1&include_docs=true".format(callsign_wanted)
	data = json.loads(urlopen(url).read())["rows"][0]["doc"]["data"]
	callsign, lat, lng, alt = data["payload"], data["latitude"], data["longitude"], data["altitude"]
	lat = str(lat)
	lng = str(lng)
	alt = str(alt)
	
	# Question: Is there a time field?
	
	print "Got callsign=%s, lat=%s, lng=%s, alt=%s" % (callsign, lat, lng, alt)
	#print "This ones a keeper"
	if callsign == callsign_wanted:
		print "Callsign match, setting balloon pos"
		balloonPositions.insert(0, (lat, lng, alt))
		
		if len(balloonPositions) > 10:
			balloonPositions = balloonPositions[0:9]
		
		## INVOKE EVENT NEW_BALLOON_POSITION -- how to do this?
	else:
		print "Callsign not matched, ignoring"
		#self.SetBalloonPos(None)
	
	our_lat = float(self.controls.ant_lat.GetValue())
	our_lng = float(self.controls.ant_lon.GetValue())
	our_alt = float(self.controls.ant_alt.GetValue())
	lat = float(lat)
	lng = float(lng)
	alt = float(alt)
	d = distance.distance((our_lat, our_lng), (lat, lng)).km
	d_alt = (alt - our_alt)/1000
	dist = math.sqrt(d**2 + d_alt**2)
	print "Distance to payload: {0}".format(dist)
	
	app.after( 20000, UpdateBalloonPositionList )
	
def CreateGraphics:
	global app, root, callsign
	
	root = Tk()
	app = Frame(root)
	app.grid()
	
	ent_callsign = Entry(app, callsign)
	
	
	app.mainloop()

def GetLatestBalloonPos(self):