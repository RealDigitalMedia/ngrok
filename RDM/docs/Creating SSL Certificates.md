Title:  Creating SSL Certificates  
Author: Harvey Chapman <hchapman@realdigitalmedia.com>  
Date:   April 28, 2016  

# [%title] #

[%author] <<hchapman@realdigitalmedia.com>>  
[%date]  

## Introduction ##

This outlines the steps needed to create trusted SSL certificates for web servers that may also be used by other programs. These instructions are tailored for running a custom ngrokd[^1] server. There are three approaches that can be taken: generate a self-signed certificate from our own Certificate Authority, or get a free signed certificate from StartCom or LetsEncrypt. Since it's much easier to use certificates from already trusted authorities, we'll skip the self-signed approach and only focus on the others.[^2]

[^1]: See <https://ngrok.com/> for more information about ngrok, and see <https://github.com/inconshreveable/ngrok/> for the source code.

[^2]: Actually, since ngrok clients use compiled in root certificates by default, creating a self-signed certificate wouldn't really have the same problems that you might usually have, e.g. web browsers giving "Untrusted Connection" warnings. However, if you wanted to another server on the same machine, it might be nice to use a single trusted certificate. 

## ngrok SSL ##

Ngrok uses SSL certificates to secure communication. The ngrokd server uses command line options to load a full chain server certificate and private key. The ngrok client however does not use the local machine's list of trusted certificates.[^no_host_certs] It compiles Certificate Authority certificates directly into the application. They are located in `assets/client/tls`. By default, they include ngrok.com and a fake "snake oil" certificate.

The simplest method of changing the certificates is to replace
the ngrok client's certificate in `assets/client/tls`and the snake oil certificate and key in `assets/server/tls`. The release version of the client only uses the ngrok certificate and the server by default (release or debug) will use the compiled in snake oil certificate and key if no alternatives are offered with the `-tlsCrt` and `-tlsKey` command line options.

The better method of changing the certificates is to add the root certificate to `assets/client/tls` as a new file and then add that filename to `release.go` and `debug.go` in `src/ngrok/client`. Then pass your server certificate and key filenames using the `-tlsCrt` and `-tlsKey` command line options.

[^no_host_certs]: It does this by default, but you can add `trust_host_root_certs = true` to a client config file to tell it to use the host's root certificates instead of the internally compiled ones.

## Let's Encrypt ##

LetsEncrypt is a new, free service that attempts to take away all of the pain of creating and managing SSL certificates. It uses a custom command line tool to create, install, and manage certificates. LetsEncrypt appears to do everything local. This means that there are no web pages to log in to for managing certificates and it seems that their tools only work when run from the server for which the SSL certificate is being generated. So, you can't generate the certificate on another machine first.

Steps:

- Install letsencypt
	- `apt-get install git`
	- `git clone https://github.com/letsencrypt/letsencrypt`
	- `cd letsencrypt/`
	- `./letsencrypt-auto --help`
- Stop any current webservers
	- `killall ngrokd`
- Create certificates
	- `./letsencrypt-auto certonly --standalone -d tunnel.neocastnetworks.com`
- Restart servers
	- `(cd ~; ./server.sh)`

Files are left in `/etc/letsencrypt/live/tunnel.neocastnetworks.com/`

| file	| description	|  
| ------	| ------	|  
| privkey.pem	| server private key	|  
| cert.pem	| server certificate	|  
| chain.pem	| certificate chain for validation	|  
| fullchain.pem	| cert.pem + chain.pem	|  

To examine a certificate file:

`openssl x509 -text -noout -in FILE`

### Integrating with Ngrok ###

For ngrokd, use `fullchain.pem` and `privkey.pem` for the `-tlsCrt` and `-tlsKey` options respectively. Compile `cert.pem` into the client by replacing one of the files in `assets/client/tls`. The server.sh script used to start ngrokd looks for server.crt and server.key. Use these commands to create them:

```
ln -sf /etc/letsencrypt/live/tunnel.neocastnetworks.com/fullchain.pem server.crt
ln -sf /etc/letsencrypt/live/tunnel.neocastnetworks.com/privkey.pem server.key
```

## StartCom ##

StartCom is another slightly older free service for creating SSL certificates. It is not as easy to use as LetsEncrypt, but once you've used it once or twice, it's not hard to use and it keeps all of your files on their server for when you need them.

- Log in to startssl.com

	This requires you to create an account and validate your e-mail address. They will give you a digital identity certificate to install in your browser.

- Verify your domain

	You can use an e-mail address or you can place a file they generate in your servers web root directory. Choose the file. If you need a quick web server, run this in the same folder where you place the file: `python3 -m http.server 80`. This will run a temporary web server on port 80 that serves files in the current directory.

- Create a Certificate

	Once the domain is verified, use the Certificates Wizard to generate a certificate for a web server. Create a certificate request and paste it in the box they provide.

	- Creating a Certificate Request

		Using the technique at [http://stackoverflow.com/a/27931596/47078](), create a config file, `tunnel-neocastnetworks-com.conf` based on the one provided in that StackOverflow answer and only change the DNS.1-4 entries at the bottom. Use however many you need (only DNS.1 for tunnel.neocastnetworks.com) and comment out the rest. Now, run the following command to create the request.

	```
	openssl req -batch -config tunnel-neocastnetworks-com.conf \
		-new -sha256 -newkey rsa:2048 -nodes -days 1825 \
		-keyout tunnel-neocastnetworks-com.key.pem \
		-out tunnel-neocastnetworks-com.req.pem
	```

	__NOTE:__ the config file and command above are checked in as `tunnel-neocastnetworks-com.conf` and `gen_request.sh`. After running the command, you will have two new files:

	tunnel-neocastnetworks-com.req.pem
	: The certificate request to send to StartSSL

	tunnel-neocastnetworks-com.key.pem
	: The private key for your certificate and server

	To examine a certificate request file:

        openssl req -text -noout -in FILE

	Use contents of the file named `tunnel-neocastnetworks-com.req.pem` for the text box in the Certificate Wizard. The website will offer up a zip file named `tunnel.neocastnetworks.com.zip`. Inside, it includes the server certificates packaged several ways for Apache, Nginx, IIS, and Other. You will need the root certificate from the Apache zip file and the full, combined certificate from the Nginx zip file.

### Integrating with Ngrok ###

Integrating with ngrokd requires three files, a private key generated from the openssl command above, and two certificate files provided by StartSSL in a zip file at the end of the certificate process. The two certificate files are contained within zip files within the downloaded zip file. Here are commands to retrieve them.

```
# unzip tunnel.neocastnetworks.com.zip NginxServer.zip ApacheServer.zip
Archive:  tunnel.neocastnetworks.com.zip
  inflating: ApacheServer.zip
  inflating: NginxServer.zip
# unzip NginxServer.zip
Archive:  NginxServer.zip
  inflating: 1_tunnel.neocastnetworks.com_bundle.crt
# unzip ApacheServer.zip 1_root_bundle.crt
Archive:  ApacheServer.zip
  inflating: 1_root_bundle.crt
# rm NginxServer.zip ApacheServer.zip
```

Use `1_tunnel.neocastnetworks.com_bundle.crt` and `tunnel-neocastnetworks-com.key.pem` for the `-tlsCrt` and `-tlsKey` options respectively. Compile `1_root_bundle.crt` into the client by replacing one of the files in `assets/client/tls`.
