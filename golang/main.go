package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"bufio"
	"time"
	"io"
	"strings"
	"bytes"
)

func main() {
	ln, err := net.Listen("tcp", ":5000")
	if err != nil {
		log.Fatal(err)
	}

	for {
		cn, err := ln.Accept()
		if err != nil {
			log.Println("ln.Accept():", err)
			continue
		}

		pcn, err := NewProxyConn(cn)

		if err != nil {
			log.Println("NewProxyConn():", err)
			continue
		}

		go handle(pcn)
	}
}

func handle(cn net.Conn) {
	defer func() {
		if err := cn.Close(); err != nil {
			log.Println("cn.Close():", err)
		}
	}()

	log.Println("handling connection from", cn.RemoteAddr())
	encoded := EncodeITU(cn.RemoteAddr().String())
	fmt.Fprintf(cn, "Your remote address is %v\n", cn.RemoteAddr())
	fmt.Fprintf(cn, "Your morse code is address is %v\n", encoded)

	data, err := ioutil.ReadAll(cn)
	if err != nil {
		log.Println("reading from client:", err)
	} else {
		log.Printf("client sent %d bytes: %q", len(data), data)
	}
}

type myConn struct {
	cn      net.Conn
	r       *bufio.Reader
	local   net.Addr
	remote  net.Addr
	proxied bool
}

func NewProxyConn(cn net.Conn) (net.Conn, error) {
	c := &myConn{cn: cn, r: bufio.NewReader(cn)}
	if err := c.Init(); err != nil {
		return nil, err
	}
	return c, nil
}

func (c *myConn) Close() error                { return c.cn.Close() }
func (c *myConn) Write(b []byte) (int, error) { return c.cn.Write(b) }

func (c *myConn) SetDeadline(t time.Time) error      { return c.cn.SetDeadline(t) }
func (c *myConn) SetReadDeadline(t time.Time) error  { return c.cn.SetReadDeadline(t) }
func (c *myConn) SetWriteDeadline(t time.Time) error { return c.cn.SetWriteDeadline(t) }

func (c *myConn) LocalAddr() net.Addr  { return c.local }
func (c *myConn) RemoteAddr() net.Addr { return c.remote }

func (c *myConn) Read(b []byte) (int, error) { return c.r.Read(b) }

func (c *myConn) Init() error {
	buf, err := c.r.Peek(5)
	if err != io.EOF && err != nil {
		return err
	}

	if err == nil && bytes.Equal([]byte(`PROXY`), buf) {
		c.proxied = true
		proxyLine, err := c.r.ReadString('\n')
		if err != nil {
			return err
		}
		fields := strings.Fields(proxyLine)
		c.remote = &addr{net.JoinHostPort(fields[2], fields[4])}
		c.local = &addr{net.JoinHostPort(fields[3], fields[5])}
	} else {
		c.local = c.cn.LocalAddr()
		c.remote = c.cn.RemoteAddr()
	}

	return nil
}

func (c *myConn) String() string {
	if c.proxied {
		return fmt.Sprintf("proxied connection %v", c.cn)
	}
	return fmt.Sprintf("%v", c.cn)
}

type addr struct{ hp string }

func (a addr) Network() string { return "tcp" }
func (a addr) String() string  { return a.hp }




func Encode(s string, alphabet map[string]string, letterSeparator string, wordSeparator string) string {

	res := ""

	for _, part := range s {
		p := string(part)
		if p == " " {
			if wordSeparator != "" {
				res += wordSeparator + letterSeparator
			}
		} else if morseITU[p] != "" {
			res += morseITU[p] + letterSeparator
		}
	}
	return strings.TrimSpace(res)
}


func EncodeITU(s string) string {
	return Encode(s, morseITU, " ", "/")
}

var (
	morseITU = map[string]string{
		"a":  ".-",
		"b":  "-...",
		"c":  "-.-.",
		"d":  "-..",
		"e":  ".",
		"f":  "..-.",
		"g":  "--.",
		"h":  "....",
		"i":  "..",
		"j":  ".---",
		"k":  "-.-",
		"l":  ".-..",
		"m":  "--",
		"n":  "-.",
		"o":  "---",
		"p":  ".--.",
		"q":  "--.-",
		"r":  ".-.",
		"s":  "...",
		"t":  "-",
		"u":  "..-",
		"v":  "...-",
		"w":  ".--",
		"x":  "-..-",
		"y":  "-.--",
		"z":  "--..",
		"ä":  ".-.-",
		"ö":  "---.",
		"ü":  "..--",
		"Ch": "----",
		"0":  "-----",
		"1":  ".----",
		"2":  "..---",
		"3":  "...--",
		"4":  "....-",
		"5":  ".....",
		"6":  "-....",
		"7":  "--...",
		"8":  "---..",
		"9":  "----.",
		".":  ".-.-.-",
		",":  "--..--",
		"?":  "..--..",
		"!":  "..--.",
		":":  "---...",
		"\"": ".-..-.",
		"'":  ".----.",
		"=":  "-...-",
	}
)
