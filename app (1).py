#!/usr/bin/env python3

import sys
import socket
import selectors
import types
import re 

sel = selectors.DefaultSelector()

# Dictionary representing the morse code chart 
MORSE_CODE_DICT = {  
                    '1':'.----', '2':'..---', '3':'...--', 
                    '4':'....-', '5':'.....', '6':'-....', 
                    '7':'--...', '8':'---..', '9':'----.', 
                    '0':'-----', '.':'.-.-.-'} 
 

# Function to encrypt the string 
# according to the morse code chart 
def encrypt(message): 
    cipher = '' 
    for letter in message:
            cipher += MORSE_CODE_DICT[letter] + ' '

    return cipher 



def accept_wrapper(sock):
    conn, addr = sock.accept()  # Should be ready to read
    print("accepted connection from", addr)
    conn.setblocking(False)
    data = types.SimpleNamespace(addr=addr, inb=b"", outb=b"")
    events = selectors.EVENT_READ | selectors.EVENT_WRITE
    sel.register(conn, events, data=data)


def service_connection(key, mask):
    sock = key.fileobj
    data = key.data
#    if mask & selectors.EVENT_READ:
#        recv_data = sock.recv(1024)  # Should be ready to read
#        if recv_data:
#             data.outb += recv_data   
#        else:
#            print("closing connection to", data.addr)
#            sel.unregister(sock)
#            sock.close()
#    if mask & selectors.EVENT_WRITE:
#        if data.outb:
    print("sending morse-code to:",  data.addr)
    ipaddr = data.addr[0]
    morsecode = encrypt(ipaddr)
    dataoutb  = "IP is {} Morse-code is {}".format(ipaddr, morsecode)
    sent = sock.send(dataoutb.encode())
    data.outb = data.outb[sent:]
    print("closing connection to", data.addr)
    sel.unregister(sock)
    sock.close()


if len(sys.argv) != 3:
    print("usage:", sys.argv[0], "<host> <port>")
    sys.exit(1)

host, port = sys.argv[1], int(sys.argv[2])
lsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
lsock.bind((host, port))
lsock.listen()
print("listening on", (host, port))
lsock.setblocking(False)
sel.register(lsock, selectors.EVENT_READ, data=None)

try:
    while True:
        events = sel.select(timeout=None)
        for key, mask in events:
            if key.data is None:
                accept_wrapper(key.fileobj)
            else:
                service_connection(key, mask)
except KeyboardInterrupt:
    print("caught keyboard interrupt, exiting")
finally:
    sel.close()

