#!/usr/bin/perl
#############################################################################
# Copyright (c) 2012-2013, Harvard University IT Security - Ventz Petkov <ventz_petkov@harvard.edu>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#  
# 1.	Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# 
# 2.	Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# 3.	Neither the name of the Harvard University nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#############################################################################

############################################################################################
# By: Ventz Petkov (ventz_petkov@harvard.edu)
# License: BSD 3
# Date: 10-15-12
# Last: 01-31-13
# Comment: Pull network device configs from SVN, and push into algosec as though via GUI
# Assumptions:
#  Acess to the following linux binaries: perl (duh!), ssh/scp, svn, rsync, mkdir, rm
#  You have dropped public ssh key under $algosec_hostname:/root/.ssh/authorized_keys2
#  You have dropped public ssh key under $algosec_hostname:/home/afa/.ssh/authorized_keys2
############################################################################################
use Shell;

# START USER CONFIG
my $algosec_hostname = 'algosec01.domain.com';
my $algosec_dir = '/usr/local/algosec_svn';
my $priv_ssh_key = "$algosec_dir/algosec-id_dsa";
my $firewall_configs_dir = "$algosec_dir/firewall";
# NOTE: Checkout manually ONCE from SVN before this script and let SVN save the password
my $svn_url = 'http://svn01.domain.com/configs/trunk/firewall';
my $svn_user = 'svnuser';
# END USER CONFIG


##################################################################
# DO NOT TOUCH PAST HERE (UNLESS YOU WANT TO BECOME THE OWNER :) #
##################################################################

# Check out files from SVN - works like 'svn up' when they are already checked out
chdir($algosec_dir);
my @svnout = `svn co --username $svn_user $svn_url`;


# Sync over the configs first - most common scenario!
chdir($firewall_configs_dir);
`rsync -az -e 'ssh -i $priv_ssh_key' * afa\@$algosec_hostname:/home/afa/algosec/fwfiles/.`;
`ssh -i $priv_ssh_key root\@$algosec_hostname 'chown afa:afa /home/afa/algosec/fwfiles/*'`;


# Pull firewall analyzer config XML
chdir($algosec_dir);
`scp -i $priv_ssh_key afa\@$algosec_hostname:/home/afa/.fa/firewall_data.xml .`;

# For each Add or Delete from the SVN log, go through and make it "happen" on AlgoSec
for my $line (@svnout) {
	if($line =~ /A    firewall\/(.*)/) {
		my $d = $1;
		print "Adding Device: $d\n";
		`/usr/bin/perl -p -i -e 's/<\\/FIREWALLS>/<FW_FILE name=\"$d\" display_name=\"$d\" path_name=\"\\/home\\/afa\\/algosec\\/fwfiles\\/$d\" created_by=\"webgui\" monitoring=\"no\" defined=\"true\"\\/>\n<\\/FIREWALLS>/g' firewall_data.xml`;
		`ssh -i $priv_ssh_key root\@$algosec_hostname '[ -d /home/afa/algosec/monitor/$d ] || /bin/mkdir /home/afa/algosec/monitor/$d && chown afa:afa /home/afa/algosec/monitor/$d'`;
	}
	elsif($line =~ /D    firewall\/(.*)/) {
		my $d = $1;
		print "Removing Device: $d\n";
		`/usr/bin/perl -p -i -e 's/<FW_FILE name=\"$d\" display_name=\"$d\" path_name=\"\\/home\\/afa\\/algosec\\/fwfiles\\/$d\" created_by=\"webgui\" monitoring=\"no\" defined=\"true\"\\/>\n//g' firewall_data.xml`;
		`ssh -i $priv_ssh_key root\@$algosec_hostname '/bin/rm -Rf /home/afa/algosec/monitor/$d && /bin/rm -f /home/afa/algosec/fwfiles/$d'`;
	}
	elsif($line =~ /U    firewall\/(.*)/) {
		my $d = $1;
		print "Updating Device: $d\n";
		# Note - this is just for information purposes - rsync takes care of this
	}
}

# Push the Firewall Analyzer log back.
`scp -i $priv_ssh_key firewall_data.xml afa\@$algosec_hostname:/home/afa/.fa/.`;
`ssh -i $priv_ssh_key root\@$algosec_hostname 'chown afa:afa /home/afa/.fa/firewall_data.xml'`;
unlink 'firewall_data.xml';

1;
