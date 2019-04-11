package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net"
)

ln, err := net.Listen("tcp", *addr)
if err != nil {
	log.Fatal(err)
}

for {
	cn, err := ln.Accept()
	if err != nil {
		log.Println("ln.Accept():", err)
		continue
	}

	pcn, err := viaproxy.Wrap(cn)
	if err != nil {
		log.Println("Wrap():", err)
		continue
	}

	log.Printf("remote address is: %v", pcn.RemoteAddr())
	log.Printf("local address is: %v", pcn.LocalAddr())
	log.Printf("proxy address is: %v", pcn.ProxyAddr())
	pcn.Close()
}
