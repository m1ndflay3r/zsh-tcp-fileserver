This is a fun little hobby project I've taken on to start some webdev (and to get better with zshell cause like holy fuck coming to this from bash is like comparing apples to having your legs shot off) 

Feel free to use this however you want if you find it helpful 


basic use:

  Firstly, until I can be fucked to make this portable, all directories are hardcoded to /root/testing/servroot so thats where server has to reside unless you feel like changing the hardlinks.

  Run generatekey.zsh to create a public / private keypair. 

  As you've likely guessed, the public key goes to the client and private the server. Make sure the private key isnt contained in servroot or clients will be able to download it. 

  Edit the lines AuthKey and PrivateKey in the client and server respectively to point at your keypair. You should use an absolute path for this. 


  You get the point I'm sure. Basically the same concept as ssh keys, albiet far simpler. 


  Add any files you wish to serve to servroot, and append their names to the file index 


  You can now fire up the server and it will begin listening on port 333. Fire up the client and it'll prompt you twice, once for server ip and again for port. It should then authenticate, and give you a prompt to request files present in servroot. You can type index to see the file index. 


aaaaaand yeah. Pretty sure that covers it
