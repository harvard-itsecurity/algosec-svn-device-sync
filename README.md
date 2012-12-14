What is it?
-----------
A way to create, remove, and keep in sync a whole bunch of network
devices (firewalls, routers, VPNs, etc...)and their configs in algosec.



How does it work?
-----------------
The idea is that you you push your device configs into SVN. Each
device config should be named accordingly. You may want to do
something like: 'devicename.zone'. Then you would cron the
"algosec_svn.pl" script and it will automatically add your devices and
sync their configs. As devices are removed, and as their configs
disapear from SVN, this script will automatically remove them and
their configs from algosec.



What is assumed?
----------------
1.) Acess to the following linux binaries: perl (duh!), ssh/scp, svn, rsync, mkdir, rm

2.) You have dropped public ssh key under: $algosec_hostname:/root/.ssh/authorized_keys2

You have dropped public ssh key under:$algosec_hostname:/home/afa/.ssh/authorized_keys2

3.) You will add your environment variables in the '# START USER CONFIG' section



Goals?
------
1.) If you modify this, please make sure you use the least amount of
non-included Perl modules (currently 0)

2.) The idea is that this will run on a cron.

3.) The goal was to make this as simple and as functional as possible.



Contact?
--------
If you need help setting this up or you find bugs, please feel free to
contact me: ventz_petkov@harvard.edu (or just fork a copy and fix the
issue :))
