### Summary
To provide an easy-to-use method for 2 nodes to pass data between each other on the same machine.

Lua-IPC will use UDP as the transport method due to its lightweight nature resulting in low latency. The reliability of TCP is not required as the data is always residing on localhost.

### Limitations
Since Lua-IPC uses [lua-MessagePack](http://fperrad.github.io/lua-MessagePack/msgpack.html#reference) to package data for transmission, it inherits the limitations that library has for packaging and unpackaging data. At the time of this writing, it does not support working with functions and tables with cyclic references.

### Nodes
Each Lua runtime environment is a **node**. Nodes are able to send and receive data between each other at the same time.
