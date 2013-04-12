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