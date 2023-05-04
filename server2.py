import socket
import threading

HOST = '192.168.1.103'  # localhost
PORT = 8000  # port number

# Create a socket object
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# Bind the socket to a specific address and port
server_socket.bind((HOST, PORT))
print(f'Server started on port {PORT}...')

# Listen for incoming connections
server_socket.listen()
print('Listening for incoming connections...')

# List of connected clients
clients = []


def handle_client(client_socket, client_address):
    """Handles messages received from a client"""
    print(f'Client {client_address} connected.')
    try:
        while True:
            # Receive data from the client
            data = client_socket.recv(1024)
            if not data:
                break

            # Print the message and the sender's address
            message = data.decode()
            print(f'{client_address}: {message}')

            # Forward the message to all other clients
            for c in clients:
                if c != client_socket:
                    c.sendall(data)
    except:
        # Handle errors and close the connection
        print(
            f'Error occurred for client {client_address}. Closing connection...')
        client_socket.close()
        clients.remove(client_socket)
    else:
        print(f'Client {client_address} disconnected.')
        client_socket.close()
        clients.remove(client_socket)


def accept_connections():
    """Accepts new connections and starts a new thread to handle each one"""
    print('Accepting new connections...')
    while True:
        # Wait for a new connection
        client_socket, client_address = server_socket.accept()

        # Add the new client to the list of connected clients
        clients.append(client_socket)

        # Start a new thread to handle the client
        threading.Thread(target=handle_client, args=(
            client_socket, client_address)).start()


# Start accepting connections in a separate thread
threading.Thread(target=accept_connections).start()

# Keep the main thread running
while True:
    pass
