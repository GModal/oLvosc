
## Demos: oLvosc with pure Lua 

Part of the **oLvosc** : *Open Sound Control for LÖVE & Lua* project

All demos are pure Lua (>= 5.3) console scripts.

**oscdump.lua**

```
Usage:

lua oscdump.lua
lua oscdump.lua (port)
lua oscdump.lua 8001
```

  * Dump OSC messages to the console
  * Default port is 8000

**oscpackets.lua**

```
Usage:

lua oscpackets.lua
lua oscpackets.lua (port)
lua oscpackets.lua 8000
```

  * Dump OSC packets and messages to the console
  * Default port is 8000

**oscping.lua**

```
Usage:

lua oscping.lua
```

  * Sends a message to port 8000, once per second

**oscrelay.lua**

**oscrelaymin.lua**

```
Usage:

lua oscrelay.lua
```

  * Receives OSC packets on port 8000
  * Transmits the packets on ports 8001 and 8002