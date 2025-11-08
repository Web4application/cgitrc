#!/usr/bin/perl -w
########################################################################
#  $Name: ORG-TEST $ $Id: link-inserter.pl,v 1.17 2002/09/02 21:30:52 leed Exp $
##------------------+---------------------------------------------------
## Copyright (C) 2002 Affero, Inc.

## This file is part of The Affero Project.

## The Affero Project is free software# you can redistribute it and/or
## modify it under the terms of the Affero General Public License as
## published by Affero, Inc.# either version 1 of the License, or
## (at your option) any later version.

## The Affero Project is distributed in the hope that it will be
## useful,but WITHOUT ANY WARRANTY# without even the implied warranty
## of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## Affero General Public License for more details.

## You should have received a copy of the Affero General Public
## License in the COPYING file that comes with The Affero Project# if
## not, write to Affero, Inc., 510 Third Street, Suite 225, San
## Francisco, CA 94107 USA.
########################################################################
#
use strict;
use Getopt::Std;
use URI::Escape;

########################################################################
#                      L I N L - I N S E R T E R                       #
########################################################################
# Simple as hell : it acts as a mail filter. Have your MTA (postfix,
# sendmail, exim) to pipe their mails into this script before they
# actually do the transportation. Or pipe your messages into this
# script before giving them to the MTA.

# If the email of the sender doesn't seem to be well-formed, the email
# is spit out untouched.

# This script requires mails to be rfc822-compliant: they must have a
# valid "From" line.

sub usage {
    my $vString= '$Id: link-inserter.pl,v 1.17 2002/09/02 21:30:52 leed Exp $';

    print STDOUT "\n\nVersion: $vString\n";
    print STDOUT <<'EOF';

        link-inserter.pl [-p <profile>] [-l <list-name>] [-c <character-class>] [-v]

    the link inserter reads an email message on it's standard
    input and writes the message on it's standard output concatenated
    with an affero rating url.

    -p is the profile to use

    -l is the list name

    -c is a class of characters which will be escaped in the
        url arguments.  it defaults to ^A-Za-z0-9

    -v print this message along with the version and exit

    if there is a config file named link-inserter.conf.pl
    in the current directory then it's contents shgould be
    an anonymous hash --the values of the hash entries will
    override values which were compiled in to the program

EOF
return;
}
########################################################################
#                             C O N F I G                              #
########################################################################
#  the config file is an anonymous hash.  read it it and set local
#  variables.
my $config= {};

if ( -e "/usr/local/libexeclink-inserter.conf.pl") {
    $config= require '/usr/local/libexec/link-inserter.conf.pl';
}

# these can only be modified in the config file
my $url=               (exists($config->{url})) ? $config->{url} : "http://khaki.allseer.com/rm.php";
my $message=           (exists($config->{message})) ? $config->{message} : "How valuable was this message? rate it at";
#  these can be overridden on the command line
my $urlEscapeCharSet=  (exists($config->{urlEscapeCharSet})) ? $config->{urlEscapeCharSet} : '^A-Za-z0-9';

########################################################################
#                            O P T I O N S                             #
########################################################################
my %options= ();
getopts("p:l:c:v", \%options);

if (exists($options{v})) {
    usage();
    exit 0;
}
#maybe override the uri-escape char set from the command line
$urlEscapeCharSet= (exists($options{c})) ? $options{c} : $urlEscapeCharSet;

########################################################################
#                      D O    T H E    N A S T Y                       #
########################################################################
my $mail = "";
my $from_line = "";
my $subj_line = "";

while (<STDIN>) {
    $mail .= $_;
    chomp($_);

    $from_line= (/^From:/) ? $_ : $from_line;
    $subj_line= (/^Subject:[ ]*(.*)/) ? $1 : $subj_line;
}

if ($from_line) {
    # Check that sender address is under the form "<some.BODY_nice@some-nice.domain>"
    if ($from_line =~ /(<|)((\w|\.|-)*?\@((\w|.)*\.\w*))(>|)/) {
        # Check that adress is not like "somebody_stupid@some..foolish.domain"
        if (!($4 =~ /\.\./)) {
            $mail .= $message . "\n";

            ##   email address
            $mail .= $url . "?m=" . URI::Escape::uri_escape($2, "^A-Za-z0-9");
            ##   list subject
            $mail .= (length($subj_line) > 0) ? ("&ls=" . URI::Escape::uri_escape($subj_line, $urlEscapeCharSet)) : "";
            ##   list name
            $mail .= (exists($options{l})) ? ("&ll=" .  URI::Escape::uri_escape($options{l}, $urlEscapeCharSet)) : "";
            ##   profile name
            $mail .= (exists($options{p})) ? ("&lp=" .  URI::Escape::uri_escape($options{p}, $urlEscapeCharSet)) : "";

            $mail .= "\n\n";
        }
    }
}

print STDOUT $mail;

exit 0;

