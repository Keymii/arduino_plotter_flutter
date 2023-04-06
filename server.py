import socket               # Import socket module
import _thread
from uuid import uuid4

clientsockets = {}


def on_new_client(clientsocket, addr, ind):
    try:
        while True:
            msg = clientsocket.recv(1024)
            # do some checks and if msg == someWeirdSignal: break:
            if (msg.decode('utf-8') != ""):
                print(addr, ' >> ', msg.decode('utf-8'))
                for key in clientsockets:
                    if key != ind:
                        clientsockets[key].send(msg)
        clientsocket.close()
    except Exception as e:
        print(e)
        print("Closing connection from", addr)
        clientsockets.pop(ind)
        clientsocket.close()


s = socket.socket()         # Create a socket object
host = "192.168.169.89"  # Get local machine name
port = 8000                # Reserve a port for your service.

s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

s.bind((host, port))        # Bind to the port
s.listen(5)                 # Now wait for client connection.
print('Server started!')
print('Waiting for clients...')
while True:
    c, addr = s.accept()     # Establish connection with client.
    ind = uuid4()
    clientsockets[ind] = c
    print('Got connection from', addr)
    _thread.start_new_thread(on_new_client, (c, addr, ind))
s.close()