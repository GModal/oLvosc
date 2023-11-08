
## Demos: oLvosc with pure Lua 

Part of the **oLvosc** : *Open Sound Control for LÖVE & Lua* project

All demos are pure Lua (>= 5.3) console scripts.

**oscdump.lua**

```
Usage:

lua oscdump.lua
lua oscdump.lua (port) (t or l)
    lua oscdump.lua 7770 l
```

  * Dump OSC messages to the console
  * Default port is 3819
  * Prints both a formatted nested table and a flattened list
      * argument 2 options: 
          * 't' nested tables only
          * 'l' list only
  * oscdump.lua now supports bundles

**bundlesearch.lua**

```
Usage:

lua bundlesearch.lua
lua bundlesearch.lua (port) search_term
     lua bundlesearch.lua 8001 MyString
```

  * searches the bundle for the search_term in the message address
  * Default port is 7770
  * Default search term is 'Bundle'
  * prints any messages with the search term

**sendbundle.lua**

```
Usage:

lua sendbundle.lua
lua sendbundle.lua (port)
     lua sendbundle.lua 8001
```

  * Simple demo, building and sending a bundle
  * Default port is 7770

**sendrandpacket.lua**

```
Usage:

lua oscdump.lua
lua oscdump.lua (port)
     lua oscdump.lua 8001
```

  * Sends random packets, both bundles and simple messages
  * Default port is 7770
  * Random bundles can (and will) be nested

**oscpackets.lua**

```
Usage:

lua oscpackets.lua
lua oscpackets.lua (port)
lua oscpackets.lua 8000
```

  * Dump OSC packets and messages to the console
  * Default port is 8000
  * No bundle support (yet)

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