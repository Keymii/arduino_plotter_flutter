# Basic example where server accepts messages from client.

# importing socket library
import socket
import time
from random import randrange

HOST = "192.168.169.89"
PORT = 8000

# socket.AF_INET means we're using IPv4 ( IP version 4 )
# socket.SOCK_STREAM means we're using TCP protocol for data transfer
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connecting to server
s.connect((HOST, PORT))

input()
x = 0
y = 0
while (True):
    s.send((str(x)+","+str(y)).encode('utf-8'))
    x += 10
    y = randrange(-100, 100)
    time.sleep(0.2)
s.close()
