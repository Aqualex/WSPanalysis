emailDetails:@[{.email.a:("SS";enlist"|")0:`:emailDetails.psv;(.email.a`var)!.email.a`val};`;0b];
.email.lib:@[value;`.email.lib;hsym`$"location of libcurl library"];

.email.url:@[value;`.email.url;emailDetails`url];
.email.user:@[value;`.email.user;emailDetails`user]; 
.email.password:@[value;`.email.password;emailDetails`password]; 
.email.from:@[value;`.email.from;emailDetails`from];
.email.usessl:@[value;`.email.usessl;"B"$($:)emailDetails`usessl];
.email.debug:@[value;`.email.debug;"I"$($:)emailDetails`debug];

.email.connect:@[{x 2:(`emailConnect;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
.email.disconnect:@[{x 2:(`emailDisconnect;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
.email.send:@[{x 2:(`emailSend;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
.email.create:@[{x 2:(`emailCreate;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
.email.g:@[{x 2:(`emailGet;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
.email.getSocket:@[{x 2:(`getSocket;1)};.email.lib;{-1"ERROR ",string[.email.lib]}];
