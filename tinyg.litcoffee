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
	error = clc.redBright.bold
	warn = clc.yellow
	notice = clc.white

Right now, I only interface to one device at a time, and I use this variable to keep track of its status:

	current_status = {}

This part of the code handles the http interface, using express. First I log everything, then respond to status report requests
on ./sr then commands on ./cmd, with the command being delivered in the body as JSON. Otherwise I serve up a static file.
Obviously, I will need to allow gcode file uploads at some point soon!

Need 404 response and restrictions on which files may be served.

	app = express()

	app.use (req, res, next) ->
		msg notice "Logger: #{req.method}, #{req.url}"
		next()

	app.use "/sr", (req, res, next) ->
		msg notice "Status request: #{req.method}, #{req.url}"
		console.log warn util.inspect(current_status)
		res.json current_status

	app.use express.bodyParser()

	app.use "/cmd", (req, res, next) ->
		msg warn 'Command: %s %s', req.url, util.inspect(req.body)
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
		console.log warn "Sending: "+s 
		sp.write s+'\n'

	# ask for a status report
	prod = ->
		s = '{"sr":""}'
	#   console.log "Sending "+s
		sp.write s+'\n'
		process.stdout.write( clc.moveTo(1, 23))
		process.stdout.write( "#{Math.round(process.uptime())}: sending: #{s}")

	# Display messages lower down the screen
	msg = (s) ->
		process.stdout.write( clc.moveTo(1, 25))
		process.stdout.write( "#{Math.round(process.uptime())}: #{s}")

	# Initialize for MRBT Mk 1 mill
	# NC switches, only Y connected just now
	init_cmds = ["ST 1", "XSN 0", "XSX 0", "YSN 3", "YSX 3", "ZSN 0", "ZSX 0", "ASN 0", "ASX 0"]

Once the port is open the 'open' event is fired and the following function gets called. It, in turn, defines the action to
perform when a 'data' event is fired. The big regexp is
an invocation from the Great Wizard Crockford that wards against broken JSON.

	sp.on "open", ->

		process.stdout.write clc.reset
		process.stdout.write clc.moveTo(1,1) + "Node TinyG"
		process.stdout.write clc.moveTo(1,2) + "Port opened"
		msg "open"

		# Set up prod to ask for regular status updates.
		setInterval prod, 2000

		sp.on "data", (data) ->
			text = data.toString("ascii")
			msg text
	#      console.log(s)
			if /^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@')
												.replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']')
												.replace(/(?:^|:|,)(?:\s*\[)+/g, ''))
				d = JSON.parse(text)
				msg warn text
				# console.log warn "Recv: "+util.inspect(d)
				sr = d.r.sr if d.r? 
				sr = d.sr if d.sr?
				for own itemname, value of sr
					# console.log notice "#{itemname} is #{value}"
					current_status[itemname] = value

				process.stdout.write( clc.moveTo(1, 3))
				process.stdout.write( util.inspect(current_status))
			else
				 msg error("Invalid JSON")