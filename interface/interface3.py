from Tkinter import *;

import serial
import os
import time
import math
import json

import sched

from urllib import urlopen
#from threading import Timer

# These are value placeholders for controls
# Create a textbox, say:
# ent = Entry(root, textvariable=var)
# ent.grid()
#
# and retrieve the values using:
#	var.get()
#
root = Tk()
callsign = StringVar()
distance = StringVar()
balloonPositions = []

# Notes on these event handlers:
# Tkinter does not support custom events. So we'll have to create
# our own event handling system (i.e. a list of callbacks for each event)
# and invoke these callbacks manually.

events = {
	'balloonPositionUpdated': [],
	'rotatorOrientationUpdated': [],
	'distanceUpdated': [], # shortcut for both balloonPositionUpdated and rotatorPositionUpdated
	'rotatorPositionUpdated': [],
	'rotatorTimeout': [],
	'balloonTimeout': []
}

def invoke_event(event_name, args):
	global app, events
	
	for evt in events[event_name]:
		#app.after(0, evt(args))
		evt(args)

def UpdateBalloonPositionList ():
	"""Invoked when balloon position has been updated.
	
	This updates the list of balloon positions"""
	
	
	pass
	
def UpdateBalloonDistance ():
	"""Invoked when rotator position has been updated (should it ever be?).
	
	This updates the balloon's position on GUI"""
	global distance

	# calculate distance?
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
	
	distance.set(format(dist))

def UpdateRotatorPositionList (lat, long, alt):
	"""Invoked when rotator position has been updated (should it ever be?).
	
	This updates the list of balloon positions"""
	pass

def UpdateRotatorOrientation ():
	"""Invoked when rotator orientation (az, el) has been updated (should it ever be?).
	
	This updates the list of balloon positions"""
	pass

def UpdateGraphics (lat, long, alt):
	"""Invoked when either rotator or balloon position has been updated.
	
	This updates the list of balloon positions"""
	pass

def SendAlert():
	pass

def FetchBalloonPosition():
	global app
	global callsign
	global balloonPositions
	
	print "Fetching latest balloon pos"
	alt = "0"
	callsign_wanted = callsign.get()
	url = "http://habitat.habhub.org/habitat/_design/habitat/_view/" + \
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
			# cull the last positions to 10
			# TODO: need to check if the last 10 readings were taken at the same time
			balloonPositions = balloonPositions[0:9]
		
		invokeEvent('balloonPositionUpdated', [])
	else:
		if False: ## e.g. TIME SINCE LAST UPDATE > 10 mins
			invokeEvent('balloonTimeout', [])
			pass
		print "Callsign not matched, ignoring"
		#self.SetBalloonPos(None)
	
	# poll again after some time. Time is in milliseconds
	app.after( 20000, FetchBalloonPosition )

def FetchRotatorPosition():
	"""Fetches the rotator position, if new values are available.
	Or ping otherwise."""
	pass
	
def CreateGraphics():
	global app, root, callsign
	
	app = Frame(root)
	app.grid()
	
	ent_callsign = Entry(app, textvariable=callsign)
	ent_callsign.grid()
	
	ent_distance = Entry(app, textvariable=distance)
	ent_distance.grid()
	
	# Before invoking mainloop, we need to ensure that our app will
	# call the timer-based procedures
	app.after(1000, FetchBalloonPosition)
	app.after(1000, FetchRotatorPosition)
	
	app.mainloop()

# Attach events
events['balloonPositionUpdated'].extend( [UpdateBalloonPositionList] )
events['rotatorOrientationUpdated'].extend( [UpdateRotatorOrientation] )
events['rotatorPositionUpdated'].extend( [UpdateRotatorPositionList] )
events['distanceUpdated'].extend( [UpdateBalloonDistance] )
events['rotatorTimeout'].extend( [SendAlert] )
events['balloonTimeout'].extend( [SendAlert] )

CreateGraphics() # Main loop starts
