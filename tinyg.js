// Generated by CoffeeScript 1.6.2
(function() {
  var app, clc, current_status, error, express, notice, prod, serial, serialport, sp, totinyg, util, warn,
    __hasProp = {}.hasOwnProperty;

  util = require("util");

  serial = require("serialport");

  serialport = serial.SerialPort;

  express = require("express");

  clc = require("cli-color");

  error = clc.red.bold;

  warn = clc.yellow;

  notice = clc.blue;

  current_status = {};

  app = express();

  app.use(function(req, res, next) {
    console.log(notice('Logger: %s %s', req.method, req.url));
    return next();
  });

  app.use("/sr", function(req, res, next) {
    console.log(notice('Status request: %s %s', req.method, req.url));
    return res.json(current_status);
  });

  app.use(express.bodyParser());

  app.use("/cmd", function(req, res, next) {
    console.log(warn('Command: %s %s', req.url, util.inspect(req.body)));
    totinyg(JSON.stringify(req.body));
    return res.json(current_status);
  });

  app.use(express["static"](__dirname + "/public"));

  app.listen(8080, "127.0.0.1");

  sp = new serialport("/dev/ttyUSB0", {
    baudrate: 115200,
    databits: 8,
    parity: "none",
    stopbits: 1,
    flowcontrol: false,
    parser: serial.parsers.readline("\n")
  });

  totinyg = function(s) {
    console.log(notice(">" + s));
    return sp.write(s + '\n');
  };

  prod = function() {
    var s;

    s = '{"sr":""}';
    return sp.write(s + '\n');
  };

  sp.on("open", function() {
    console.log("open");
    setInterval(prod, 500);
    return sp.on("data", function(data) {
      var d, itemname, text, value, _ref, _results;

      text = data.toString("ascii");
      if (/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
        d = JSON.parse(text);
        console.log(notice(text));
        if (d.sr != null) {
          _ref = d.sr;
          _results = [];
          for (itemname in _ref) {
            if (!__hasProp.call(_ref, itemname)) continue;
            value = _ref[itemname];
            console.log(notice("#itemname is #value"));
            _results.push(current_status[itemname] = value);
          }
          return _results;
        }
      } else {
        return console.log(error("Invalid JSON"));
      }
    });
  });

}).call(this);
