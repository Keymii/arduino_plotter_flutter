import socket               # Import socket module
import errno
import _thread
import os
from uuid import uuid4

clientsockets = {}
threads = {}


def on_new_client(clientsocket, addr, ind):
    global clientsockets
    threads[ind] = 0
    try:
        while True:
            msg = clientsocket.recv(1024)
            # do some checks and if msg == someWeirdSignal: break:
            if (msg.decode('utf-8') != ""):
                print(addr, ' >> ', msg.decode('utf-8'))
                for key in clientsockets:
                    if key != ind:
                        clientsockets[key][0].send(msg)
        threads[ind] = 1
        clientsocket.close()
    except Exception as e:
        print(e)
        print("Closing connection from", addr)
        if ind in clientsockets:
            clientsockets.pop(ind)
        clientsocket.close()
        if e.errno == errno.EPIPE:
            threads[ind] = 2
            print("Pipe is broken restart")
            restartServer()
        else:
            threads[ind] = 1


s = socket.socket()         # Create a socket object
host = "192.168.1.103"  # Get local machine name
port = 8000                # Reserve a port for your service.

s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)


def startServer():
    global s, clientsockets, host, port
    print("Starting server")
    s.bind((host, port))        # Bind to the port
    s.listen(5)                 # Now wait for client connection.
    print('Server started!')
    print('Waiting for clients...')
    while True:
        try:
            c, addr = s.accept()     # Establish connection with client.
            ind = uuid4()
            clientsockets[ind] = (c, addr)
            print('Got connection from', addr)
            _thread.start_new_thread(on_new_client, (c, addr, ind))
        except Exception as e:
            print(e)
            break
    restartServer()


def restartServer():
    global s, clientsockets
    print("Restarting")
    _thread.exit()
    for key in clientsockets:
        clientsockets[key][0].close()
    clientsockets = {}
    s.close()
    print("Start server")
    startServer()


startServer()
