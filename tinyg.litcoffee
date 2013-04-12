I am a simple web server/proxy for allowing web clients to control and view the status of devices which are attached to my host via a
TinyG controller (made by Synthetos -- https://www.synthetos.com/).

Andrew Price (aprice2704@gmail.com) made me in 2013 and donated me to the Public Domain.

This version assumes TinyG firmware version 0.95 or greater.

I am made of coffeescript (hopefully literate), node.js and various additions (many thanks to their respective makers).
In particular, I use the express framework for routing web requests and node-serialport for accessing the TinyG.
All sorts of web clients should be able to talk to me, but so far 
Andrew had made only one. It can display status and send me commands to forward to the TinyG.

I currently have no security and very little error checking :(

Obviously, I need many more features; in particular, I hope to be able to talk to BotQueue servers at some point.

	util = require("util")
	serial = require("serialport")
	serialport = serial.SerialPort

The express framework, mostly for making responding to http requests nice.

	express = require("express")

I will distract you from my flaws using pretty colours in my text output. Also, less boring.

	clc = require("cli-color")
	error = clc.red.bold
	warn = clc.yellow
	notice = clc.blue

Right now, I only interface to one device at a time, and I use this variable to keep track of its status:

	current_status = {}

This part of the code handles the http interface, using express. First I log everything, then respond to status report requests
on ./sr then commands on ./cmd, with the command being delivered in the body as JSON. Otherwise I serve up a static file.
Obviously, I will need to allow gcode file uploads at some point soon!

Need 404 response and restrictions on which files may be served.

	app = express()

	app.use (req, res, next) ->
		console.log notice 'Logger: %s %s', req.method, req.url
		next()

	app.use "/sr", (req, res, next) ->
		console.log notice 'Status request: %s %s', req.method, req.url
		res.json current_status

	app.use express.bodyParser()

	app.use "/cmd", (req, res, next) ->
		console.log warn 'Command: %s %s', req.url, util.inspect(req.body)
		totinyg JSON.stringify(req.body)
		res.json current_status

	app.use express.static __dirname+"/public"

	app.listen 8080, "127.0.0.1"

In this part of the code I attend to the serial port. Obviously, I need a cl param for port etc. at some point.
First, some setup:

	sp = new serialport "/dev/ttyUSB0",
		baudrate : 115200
		databits : 8
		parity   : "none"
		stopbits : 1
		flowcontrol : false
		parser: serial.parsers.readline "\n" 

	# convenience function for sending text to the port
	totinyg = (s) ->
		console.log notice ">"+s 
		sp.write s+'\n'

	# ask for a status report
	prod = ->
		s = '{"sr":""}'
	#   console.log "Sending "+s
		sp.write s+'\n'


Once the port is open the 'open' event is fired and the following function gets called. It, in turn, defines the action to
perform when a 'data' event is fired. The big regexp is
an invocation from the Great Wizard Crockford that wards against broken JSON.

	sp.on "open", ->

		console.log "open"

		# Set up prod to ask for regular status updates.
		setInterval prod, 500

		sp.on "data", (data) ->
			text = data.toString("ascii")
	#      console.log(s)
			if /^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
												.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
												.replace(/(?:^|:|,)(?:\s*\[)+/g, ''))
				d = JSON.parse(text)
				console.log notice text
				if d.sr?
					for own itemname, value of d.sr
						console.log notice "#itemname is #value"
						current_status[itemname] = value
						# console.log(util.inspect(d))
					 	# current_status = d
			else
				 console.log error "Invalid JSON"