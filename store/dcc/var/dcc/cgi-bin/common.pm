#! /usr/bin/perl -wT -I/var/dcc/cgi-bin
# check this file by running it separately, and so keep the leading comment

# common functions for the DCC whitelist CGI scripts.

# Copyright (c) 2010 by Rhyolite Software, LLC
#
# This agreement is not applicable to any entity which sells anti-spam
# solutions to others or provides an anti-spam solution as part of a
# security solution sold to other entities, or to a private network
# which employs the DCC or uses data provided by operation of the DCC
# but does not provide corresponding data to other users.
#
# Permission to use, copy, modify, and distribute this software without
# changes for any purpose with or without fee is hereby granted, provided
# that the above copyright notice and this permission notice appear in all
# copies and any distributed versions or copies are either unchanged
# or not called anything similar to "DCC" or "Distributed Checksum
# Clearinghouse".
#
# Parties not eligible to receive a license under this agreement can
# obtain a commercial license to use DCC by contacting Rhyolite Software
# at sales@rhyolite.com.
#
# A commercial license would be for Distributed Checksum and Reputation
# Clearinghouse software.  That software includes additional features.  This
# free license for Distributed ChecksumClearinghouse Software does not in any
# way grant permision to use Distributed Checksum and Reputation Clearinghouse
# software
#
# THE SOFTWARE IS PROVIDED "AS IS" AND RHYOLITE SOFTWARE, LLC DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL RHYOLITE SOFTWARE, LLC
# BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
# ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Rhyolite Software DCC 1.3.138-1.18 $Revision$
# Generated automatically from common.pm.in by configure.

package common;

use strict;
use integer;
use 5.004;
use Fcntl qw(:DEFAULT :flock);
use POSIX qw(strftime);

BEGIN {
    use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    $VERSION = "1.3.138";

    @ISA = qw(Exporter);
    @EXPORT = qw(&html_head &html_footer &html_str_encode &html_whine &html_die
		 &punt2 &url_encode &common_buttons
		 &read_whiteclnt &read_whitedefs &undo_whiteclnt &edit-whiteclnt
		 &ck_new_white_entry &newest_whiteclnt_bak &parse_type_value
		 &chg_white_entry &parse_thold_value &write_whiteclnt
		 &parse_log_msg &msg2path &get_log_msgs
		 $cgibin $logdir $logout_tmpdir $user_dir
		 %query $user $hostname $main_whiteclnt $whiteclnt
		 $thold_cks $thold_cks_cmn
		 %conf_cks_tholds $list_log_url $list_log_link
		 $list_msg_link $edit_url $edit_link $passwd_url $passwd_link
		 $logoutID $url_ques $url_suffix $sub_white $form_hidden
		 $msg $msg_date $msg_helo $msg_ip $msg_client_name $msg_env_from
		 @msg_env_to $msg_mail_host $msg_from $msg_subject $msg_hdrs
		 $msg_body $msg_cksums $msg_result
		 %msgs_cache %msgs_date %msgs_result %msgs_from %msgs_subject
		 $msg_day_first $msg_day_last $msg_first $msg_last $msg_newer
		 $msg_part_num @msgs_num $sub_hdrs
		 $DCC_HOMEDIR
		 $DCCM_ENABLE $DCCM_ARGS
		 $DCCM_USERDIRS
		 $DCCM_REJECT_AT $DCCM_CKSUMS
		 $DCCIFD_ENABLE $DCCIFD_ARGS
		 $DCCIFD_REJECT_AT $DCCIFD_USERDIRS
		 $DCCIFD_CKSUMS
		 $GREY_CLIENT_ARGS $DNSBL_ARGS $REP_ARGS
		 $whiteclnt_version $whiteclnt_notify $whiteclnt_notify_pat
		 $whiteclnt_lock $whiteclnt_cur_key $whiteclnt_change_log);
    %EXPORT_TAGS = ();
    @EXPORT_OK = @EXPORT;
}
our @EXPORT_OK;

our ($cgibin, $logdir, $logout_tmpdir, $user_dir);

our (%query, $user, $hostname,
     $main_whiteclnt,
     $whiteclnt,			# path to the per-user whitelist file
     $thold_cks,			# checksums that can have thresholds
     $thold_cks_cmn,
     %conf_cks_tholds,
     $list_log_url, $list_log_link,
     $list_msg_link, $edit_url, $edit_link,
     $passwd_url, $passwd_link,
     $logoutID, $url_ques, $url_suffix,
     $form_hidden);


# quiet Perl taint checks with a path that should work everywhere for
#   the few commands these scripts use.
$ENV{PATH}="/var/dcc/libexec:/sbin:/bin:/usr/sbin:/usr/bin";

# check_user() must be called before html_head()
return check_user();



sub debug_time {
    my($label) = @_;
    my($str);

    return if (!$query{debug});

    my(@ts, $ts);
    require 'sys/syscall.ph';

    $ts = pack("LL", ());
    syscall(&SYS_gettimeofday, $ts, 0);
    @ts = unpack("LL", $ts);

    chomp($label);
    $str = sprintf "%30s", $label;
    $str .= strftime(" %X", localtime($ts[0]));
    $str .= sprintf ".%03d", $ts[1]/1000;
    $str .= sprintf " %5.3f", $_ foreach times;
    $str .= "\n";
    print STDERR $str;
}



sub debug_printf {
    my($label, $str) = @_;

    return if (!$query{debug});
    $str =~ s/\n/\\n/g;
    print STDERR "$label='$str'\n";
}


# emit HTTP/HTML header
sub html_head {
    my($title,			# title of the web page
       $refresh_url) = @_;	# next step in re-login sequence if not null
    my($header, $style);

    print <<EOF;
Content-type: text/html; charset=iso-8859-1
Expires: Thu, 01 Dec 1994 16:00:00 GMT
pragma: no-cache

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML>
<HEAD>
    <TITLE>$title</TITLE>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
    <META HTTP-EQUIV="Content-Style-Type" CONTENT="text/css">
    <META HTTP-EQUIV="x-dns-prefetch-control" CONTENT="off">
EOF

    print "<META HTTP-EQUIV=refresh content=\"1;url=$refresh_url\">\n"
	if ($refresh_url);

    # Use header if supplied
    #	it is mostly text for the start of the <BODY>,
    #	but it can also contain <LINK rel="stylesheet"...
    #	or <STYLE>...</STYLE>
    $header = "\n";
    if (open(HEADER, "$user_dir/header")
	|| open(HEADER, "/var/dcc/cgi-bin/header")) {
	my $line;

	$header .= $line while ($line = <HEADER>);
	close(HEADER);
    }

    # Use our style if the supplied header has none
    $style = "";
    $style .= $1
	if ($header =~ s/([ \t]*<link[^>]*rel=['"]?stylesheet[^>]*>\s*)//si);
    $style .= $1
	if ($header =~ s/([ \t]*<STYLE[^>]*>.*<\/STYLE>\s*)//si);
    $style = <<EOF if (!$style);
    <STYLE type="text/css">
	<!--
	BODY {background-color:white; color:black}
	.warn {color:red}
	.mono {font-family:monospace}
	.small {font-size:x-small}
	.stronger {font-weight:bolder}
	.nopad {margin:0; padding:0}
	INPUT.selected {font-size:smaller; font-weight:bolder; color:blue}
	TABLE {white-space:nowrap}
	TD.first {text-align:right; vertical-align:baseline}
	IMG.logo {width:6em; vertical-align:middle}
	ADDRESS {font-size:xx-small}
	-->
    </STYLE>
EOF

    print <<EOF;
$style
</HEAD>
<BODY>
<H2>$title</H2>
$header
EOF
}



sub html_footer {
    if (open(FOOTER, "$user_dir/footer")
	|| open(FOOTER, "/var/dcc/cgi-bin/footer")) {
	my $line;

	print $line while ($line = <FOOTER>);
	close(FOOTER);
    }
}



sub common_buttons {
    my($msg, $cur, $list_log, $edit, $passwd, $id);


    $msg = $query{msg} ? "${url_ques}msg=$query{msg}" : "";

    $cur = "$ENV{SCRIPT_NAME}$url_suffix";
    $list_log = ($cur ne $list_log_url
		 ? "$list_log_link$msg\">Log</A>"
		 : "List Log");
    $edit = ($cur ne $edit_url
	     ? "$edit_link\">Settings</A>"
	     : "Settings");
    $passwd = ($cur ne $passwd_url
	       ? "$passwd_link\">Password</A>"
	       : "Password");

    print <<EOF;
<TABLE>
<TR><TD>$list_log
    <TD>$edit
    <TD>$passwd
    <TD><A HREF="$cur${url_ques}logoutID=$logoutID">LogOut/In</A>
EOF
}



# give up, but not entirely, with an HTML whine
sub html_whine {
    my($msg) = @_;

    html_head("Internal Error");
    common_buttons();
    print <<EOF;
</TABLE>
<H1>Internal Error</H1>
<P class=warn>$msg
<P><HR>
$ENV{SERVER_SIGNATURE}
</BODY>
</HTML>
EOF
    exit;
}



# die with an HTML whine
sub html_die {
    my($msg) = @_;

    # put the message into the httpd error log
    print STDERR "DCC CGI script internal error: $msg\n";

    html_head("Internal Error");
    print <<EOF;
<P class=warn>$msg
<P><HR>
$ENV{SERVER_SIGNATURE}
</BODY>
</HTML>
EOF
    exit;
}


# punt to some other web page, perhaps after the logout/in kludge
#   this cannot be used after html_head()
sub punt2 {
    my($msg,				# message saying why
       $url) = @_;			# the other web page

    # don't punt a punt
    html_die($msg) if ($query{result});

    $url = ((($ENV{HTTPS} && $ENV{HTTPS} eq "on") ? "https://" : "http://")
	    . $ENV{SERVER_NAME}
	    . $url);
    $url .= $url_ques."result=".url_encode($msg) if ($msg);

    print "Status: 302 Moved Temporarily\nLocation: $url\n";
    html_head("redirect to $url");
    print "redirecting to $url\n</BODY>\n</HTML>\n";
    exit;
}


our ($DCC_HOMEDIR,
     $DCCM_ENABLE, $DCCM_ARGS,		# from dcc_conf file
     $DCCM_USERDIRS,
     $DCCM_REJECT_AT, $DCCM_CKSUMS,
     $DCCIFD_ENABLE, $DCCIFD_ARGS,
     $DCCIFD_REJECT_AT, $DCCIFD_USERDIRS,
     $DCCIFD_CKSUMS,
     $GREY_CLIENT_ARGS, $DNSBL_ARGS, $REP_ARGS,
     $sub_white,			# 'subsitute' headers from dcc_conf
     $sub_hdrs);			# pattern form of $sub_white

# Check authentication and gather system parameters.
#   Require a user name as well as one that can't be used as a sneaky path.
sub check_user {
    my($sub_args, $cks, $thold, $line, $var);

    if ($ENV{HTTP_NAME}) {
	$hostname = $ENV{HTTP_NAME};
    } elsif ($ENV{SERVER_NAME}){
	$hostname = $ENV{SERVER_NAME};
    } else {
	$hostname=`hostname`;
	chomp($hostname);
    }

    $user = $ENV{REMOTE_USER};
    if (!$user){
	$user = '';
	html_die("no user name")
    }
    # allow the user name to be a subdirectory
    html_die("user name $user is invalid")
	if ($user =~ /\.\./ || $user !~ /^([-\/.,#_%a-z0-9]+)$/i);
    $user = $1;				# stop Perl taint warnings

    # convert the user name to lower case because sendmail likes to
    $user =~ tr/A-Z/a-z/;

    # rely on the /var/dcc/dcc_conf configuration file for almost everything
    $DCC_HOMEDIR = "/var/dcc";		# unneeded except for compatibility
    $DCCM_USERDIRS = "userdirs";
    $DCCM_ENABLE = "on";
    $DCCIFD_ENABLE = "off";
    open(CONF, '/bin/sh -c \'. /var/dcc/dcc_conf;
		echo DCCM_ENABLE="$DCCM_ENABLE";
		echo DCCM_USERDIRS="$DCCM_USERDIRS";
		echo DCCM_ARGS="$DCCM_ARGS";
		echo DCCM_REJECT_AT="$DCCM_REJECT_AT";
		echo DCCM_CKSUMS="$DCCM_CKSUMS";
		echo DCCIFD_ENABLE="$DCCIFD_ENABLE";
		echo DCCIFD_USERDIRS="$DCCIFD_USERDIRS";
		echo DCCIFD_ARGS="$DCCIFD_ARGS";
		echo DCCIFD_REJECT_AT="$DCCIFD_REJECT_AT";
		echo DCCIFD_CKSUMS="$DCCIFD_CKSUMS";
		echo GREY_CLIENT_ARGS="$GREY_CLIENT_ARGS";
		echo DNSBL_ARGS="$DNSBL_ARGS";
		\'|')
	|| html_die("cannot get DCC configuration");
    while ($line = <CONF>) {
	chomp($line);
	if ($line !~ s/(^[A-Z_]+)=//) {
	    print STDERR "impossible dcc_conf line $line";
	    next;
	}
	$var = $1;
	if ($line =~ /^([-0-9,.\/a-z_]*)$/i) {
	    no strict 'refs';
	    ${$var} = $1;		# suppress taint warnings on safe paths
	} else {
	    no strict 'refs';
	    ${$var} = $line;
	}
    }
    close(CONF);

    $main_whiteclnt = "/var/dcc/whiteclnt";
    if ($DCCM_ENABLE eq "off" && $DCCIFD_ENABLE eq "on") {
	$sub_args = $DCCIFD_ARGS;
	$cks = $DCCIFD_CKSUMS;
	$thold = $DCCIFD_REJECT_AT;
	$logout_tmpdir = "$DCCIFD_USERDIRS/tmp";
	# Assume "name" per-user directory for simple dccifd user names.
	$user_dir = "$DCCIFD_USERDIRS/$user";
    } else {
	$sub_args = $DCCM_ARGS;
	$cks = $DCCM_CKSUMS;
	$thold = $DCCM_REJECT_AT;
	$logout_tmpdir = "$DCCM_USERDIRS/tmp";
	# Assume "local/name" per-user directory for simple dccm user names.
	$user_dir = ($user =~ /\//) ? $user : "local/$user";
	$user_dir = "$DCCM_USERDIRS/$user_dir";
    }
    $logout_tmpdir = "/var/dcc/$logout_tmpdir" if ($logout_tmpdir !~ /^\//);
    $user_dir = "/var/dcc/$user_dir" if ($user_dir !~ /^\//);
    html_die("no user directory $user_dir")
	if (! -d $user_dir) ;
    $logdir = "$user_dir/log";
    $whiteclnt = "$user_dir/whiteclnt";

    # Figure out which substitute headers are turned on
    #	This does not detect all possible SMTP field names, but it also
    #	won't get Perl confused with field names such as 'foo[bar]'.
    $sub_hdrs = "";
    $sub_hdrs .= "|$1"
	while ($sub_args && $sub_args =~ s/(?:-[VdbxANQW]*S\s*)
	       ((?i:[-a-z_0-9]+))
	       ($|\s+)
	       /$2/x);
    $sub_white = $sub_hdrs;
    # pattern matching optional or substitute SMTP headers
    $sub_hdrs =~ s/^\|+//;
    # pattern matching optional or substitute checksum types
    $sub_white =~ s/\|/)|(substitute\\s+/g;
    $sub_white =~ s/^[|)(]*/(/;
    $sub_white .= ')';

    # names of checksums whose thresholds can be set
    $thold_cks_cmn = 'Body,Fuz1,Fuz2';
    $thold_cks = $thold_cks_cmn;
    # all checksums including those not kept by (almost all) DCC servers
    #$thold_cks_all = 'IP,env_From,From,env_To,Message-ID,' . $thold_cks;

    # compute default checksum thresholds
    if ($thold) {
	$cks = $thold_cks_cmn if (!$cks);
	foreach my $ck (split(/,/,$cks)) {
	    my ($t,$v) = ($ck, $thold);
	    $conf_cks_tholds{$t} = "<STRONG>$v</STRONG> <SMALL>by default in /var/dcc/dcc_conf</SMALL>"
		if (parse_thold_value($t, $v));
	}
    }

    $cgibin = $ENV{SCRIPT_NAME};
    # trim the name of our script from the path
    $cgibin =~ s!/+[^/]+$!!;
    # trim extra leading /s that can mess up our generated links
    $cgibin =~ s!^/{2,}!/!;

    get_query();

    return 1;
}



# Get user's parameters
sub get_query {
    my($buffer, $name, $value, $tfile);

    if ($ENV{REQUEST_METHOD} && $ENV{REQUEST_METHOD} =~ /GET|HEAD/) {
	$buffer = $ENV{'QUERY_STRING'};
    } elsif (!$ENV{CONTENT_LENGTH}) {
	$buffer = '';
    } else {
	read(STDIN, $buffer, $ENV{CONTENT_LENGTH});
    }
    $buffer =~ tr/+/ /;
    foreach my $pair (split(/&/, $buffer)) {
	($name, $value) = split(/=/, $pair);
	$name =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
	if ($value) {
	    $value =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
	} else {
	    $value = "";
	}
	$query{$name} = $value;
    }

    if (!$query{debug} || $query{debug} !~ /^\d+$/) {
	$url_ques = "?";
	$url_suffix = "";
	$form_hidden = "";
    } else {
	if ($query{debug} > 1) {
	    debug_time("start $ENV{SCRIPT_NAME}");
	    print STDERR "  $_=\"$query{$_}\"\n" foreach (keys %query);
	    print STDERR "  AuthName=\"$ENV{AuthName}\"\n"
		if ($ENV{AuthName});
	    print STDERR "  SCRIPT_NAME=\"$ENV{SCRIPT_NAME}\"\n"
		if ($ENV{SCRIPT_NAME});
	}
	$url_suffix = "?debug=$query{debug}";
	$url_ques = '&amp;';
	$form_hidden = "\n    <INPUT type=hidden name=debug value=$query{debug}>";
    }

    $list_log_url = "$cgibin/list-log$url_suffix";
    $list_log_link = "<A HREF=\"$list_log_url";
    $list_msg_link = "<A HREF=\"$cgibin/list-msg$url_suffix";
    $edit_url = "$cgibin/edit-whiteclnt$url_suffix";
    $edit_link = "<A HREF=\"$edit_url";
    $passwd_url = "$cgibin/chgpasswd$url_suffix";
    $passwd_link = "<A HREF=\"$passwd_url${url_ques}goback=$ENV{SCRIPT_NAME}";

    $logoutID = $ENV{UNIQUE_ID};
    # do the best we can if Apache mod_unique_id is not present
    $logoutID = "$ENV{REMOTE_ADDR}-$ENV{REMOTE_PORT}-$$-" . time()
	if (!$logoutID);
    $logoutID = url_encode($logoutID);

    # kludge to handle "logout" button including recognizing that we have
    #   already handled it.  The usual tactic of requiring the user to
    #   specifying a new username and then using a cookie seems ugly.
    $tfile = $query{logoutID};
    if ($tfile && $tfile =~ /^([-.A-Za-z0-9@]+)$/) {
	$tfile = "$logout_tmpdir/logout.$1";

	# delete any old logout marker files
	my($old_tfiles) = `find $logout_tmpdir -name 'logout.*' -mtime +1`;
	if ($old_tfiles && $old_tfiles =~ /^(.+)\s*$/) {
	    $old_tfiles = $1;			# untaint
	    my @old_tfiles = split /\s/,$old_tfiles;
	    print "unlink($old_tfiles): $!\n"
		if ($#old_tfiles >= unlink @old_tfiles);
	}

	# Look for our logout marker file.
	if (-f $tfile) {
	    # If it exists, then we have been here before, so just delete it.
	    # and refresh
	    unlink $tfile;
	    punt2("", "$ENV{SCRIPT_NAME}$url_suffix");

	} else {
	    # If it does not exist, create it & force a cycle of authentication.
	    if (!open(TFILE, "> $tfile")) {
		print STDERR "open($tfile): $!\n";
		html_whine("open($tfile): $!", $edit_url);
	    }
	    while (($name,$value) = each %ENV) {
		print TFILE "$name=$value\n";
	    }

	    # Demand a new user name and password
	    my($AuthName) = $ENV{AuthName} ? $ENV{AuthName} : "DCC user";
	    print <<EOF;
WWW-authenticate: Basic realm="$AuthName"
Status: 401 Unauthorized
EOF
	    html_head("Access Failure");
	    print "<P class=warn>\nAccess Failure\n</BODY></HTML>\n";
	    exit;
	}
    }
}




##########################################################################

# %-encode text for a URL
sub url_encode {
    my($out) = @_;

    $out =~ s/([^-_.!*()0-9a-zA-Z])/sprintf("%%%02X",ord($1))/eg;
    return $out;
}



# encode text for ordinary HTML to avoid special HTML flags such as '<'
#   retain newlines
sub html_str_encode {
    my($out) = @_;

    $out =~ s/&/&amp;/g;
    $out =~ s/</&lt;/g;
    $out =~ s/>/&gt;/g;
    $out =~ s/([\00-\10\13-\17\42\47\177-\377])/sprintf("&#%d;",ord($1))/eg;
    return $out;
}



# encode text for HTML, and replace newlines with <BR>
sub html_text_encode {
    my($out) = html_str_encode(@_);
    $out =~ s/\n/<BR>\n/g;
    return $out;
}



# encode text for HTML, trimmed to at most 32 characters with the end replaced
#   by an ellipsis if too long
sub hdr_trim_encode {
    my($out) = @_;

    return "&nbsp;" if (!$out);

    return html_str_encode($out) if (length($out) <= 32);

    $out = substr($out, 0, 28)
	if ($out !~ s/(^.{20,28}[^<>.@\t ])[<>.@\t ].*/$1/);
    $out = html_str_encode($out);
    $out .=  "&nbsp;...";
    return $out;
}



##########################################################################
# Open and parse a log message
our ($msg_date,			# envelope
     $msg_helo,			# envelope
     $msg_ip,			# envelope
     $msg_client_name,		# envelope
     $msg_env_from,		# envelope
     @msg_env_to,		# envelope
     $msg_mail_host,		# envelope
     $msg_from,			# header
     $msg_subject,
     $msg_hdrs,
     $msg_body,
     $msg_cksums,
     $msg_result);

# message names in the cache of names, mtimes, and i-numbers are compressed
#   as the 6-byte suffix of the "msg.xxxxxx" name followed by 2, 3, or 4
#   characters encoding the DDD/, DDD/HH, or DDD/HH/MM directory.
#   $dir_encode_str and decode_dir_name() are used to encode and decode the
#   subdirectory names.
our (%msgs_cache,		# key=compressed name, [0]=mtime [1]=i-number
     $cache_line_len,
     $cache_pack,
     $cache_version,
     %msgs_cache_state);	# key=day, value=1 if good


sub parse_log_msg {
    my($msg, $no_body) = @_;
    my(@error, $path, $line, $num_hdrs, $cur_hdr, $hdr_type, $new_hdr,
       $misc_hdr, $seen_message_id, $ise_msg, $cksum_marker, $cksum_marker_p);

    undef $msg_date;
    undef $msg_helo;
    undef $msg_ip;
    undef $msg_client_name;
    undef $msg_env_from;
    undef @msg_env_to;
    undef $msg_mail_host;
    undef $msg_from;
    undef $msg_subject;
    $msg_hdrs = '';
    $msg_body = '';
    $msg_cksums = '';
    $msg_result = ': ';

    $num_hdrs = 0;

    $ise_msg = "Internal Server Error";
    $cksum_marker = "### end of message body ########################\n";
    $cksum_marker_p = qr/^### end of message body ########################\s*$/;

    $no_body = "" if ($no_body && $no_body ne "no body");
    $path = msg2path($msg);

    sysopen(MSG, $path, O_RDONLY, 0)
	|| return ($ise_msg, "open($path): $!");

    return ($ise_msg, "empty $path") if (!($msg_date = <MSG>));

    if ($msg_date !~ /^VERSION/) {
	close(MSG);
	return ($ise_msg, "format of $path unrecognized");
    }
    if (!($msg_date = <MSG>)) {
	close(MSG);
	return ($ise_msg, "$path truncated after VERSION line");
    }
    if (!($msg_date =~ s/^DATE: +(.*) +[^ ]+/$1/)) {
	close(MSG);
	return ($ise_msg, "unrecognized DATE line $msg_date in message $msg");
    }

    if (!($msg_ip = <MSG>)) {
	close(MSG);
	return ($ise_msg, "message $msg truncated after DATE line");
    }
    if ($msg_ip =~ /^IP: +([^ ]+) (::ffff:)?([:.0-9a-fA-F]*) *$/) {
	$msg_ip = $3;
	$msg_client_name = $1;
	$msg_client_name =~ s/^\[.*]$//;
	$msg_client_name = ' ' if ($msg_client_name eq '');
	if (!($msg_helo = <MSG>)) {
	    close(MSG);
	    return ($ise_msg, "message $msg truncated after IP address");
	}
    } else {
	# no IP line
	$msg_helo = $msg_ip;
	undef $msg_ip;
    }
    if ($msg_helo =~ s/^HELO:\s*([^\s].*)\s*$/$1/) {
	if (!($msg_env_from = <MSG>)) {
	    close(MSG);
	    return ($ise_msg, "message $msg truncated in envelope");
	}
    } else {
	# no HELO line
	$msg_env_from = $msg_helo;
	undef($msg_helo);
    }
    if ($msg_env_from =~ s/^env_From:\s*([^\s].*)\s*$/$1/) {
	$msg_mail_host = $msg_env_from;
	$msg_mail_host =~ s/.*mail_host=(.*)/$1/;
	$msg_env_from =~ s/<?([^\t> ]*).*/$1/;
	$line = <MSG>;
    } else {
	# no env_from line
	$line = $msg_env_from;
	undef($msg_env_from);
    }

    # Save the envelope env_To lines.
    for (;;) {
	if (!$line) {
	    close(MSG);
	    return ($ise_msg, "message $msg truncated in envelope");
	}
	last if ($line =~ /^[\r\n]*$/);
	if ($line eq "abort\n") {
	    close(MSG);
	    return ("aborted transaction", "");
	}
	push(@msg_env_to, $1) if ($line =~ /env_To:[\t ]*<?([^\t> ]+).*/);
	$line = <MSG>;
    }


    # Look for header lines that get checksums as we collect the whole message.
    $new_hdr = "";
    undef($hdr_type);
    for (;;) {
	if (!($line = <MSG>)) {
	    close(MSG);
	    return ($ise_msg, "message $msg truncated in headers");
	}

	# dccifd logs header lines with <CR><LF> but dccm uses <LF>
	$line =~ s/\r\n$/\n/;

	# deal with header continuation
	if ($line =~ /^[\t ]+/) {
	    $new_hdr .= $line;
	    $$cur_hdr .= $line if ($cur_hdr);
	    next;
	}

	if ($cur_hdr) {
	    # end a preceding interesting header
	    $$cur_hdr =~ s/[\t ]*\n[\r\s]*/ /g;
	    $$cur_hdr =~ s/^\s+//;
	    $$cur_hdr =~ s/\s+$//;
	    # emit a link
	    if (!$no_body) {
		if ($hdr_type) {
		    $msg_hdrs .= "$edit_link${url_ques}type=$hdr_type&amp;val=";
		    $msg_hdrs .= url_encode($$cur_hdr);
		    $msg_hdrs .= "&amp;msg=$msg&amp;auto=1#cur_key\">";
		    chomp($new_hdr);
		    $msg_hdrs .= html_str_encode($new_hdr);
		    $msg_hdrs .= "</A>\n";
		    undef($hdr_type);
		} else {
		    $msg_hdrs .= html_str_encode($new_hdr);
		}
	    }
	    undef $cur_hdr;
	} else {
	    # end preceding boring header
	    $msg_hdrs .= html_str_encode($new_hdr);
	}

	# stop after the headers
	last if ($line eq "\n");

	++$num_hdrs;

	$new_hdr = $line;

	# Start an interesting header

	if ($line =~ s/^from:\s*//i) {
	    $hdr_type = "from";
	    $msg_from = $line;
	    $cur_hdr = \$msg_from;
	    next;
	}
	if ($line =~ s/^(Message-ID):\s*//i) {
	    $hdr_type = "Message-ID";
	    $misc_hdr = $line;
	    $cur_hdr = \$misc_hdr;
	    $seen_message_id = 1;
	    next;
	}
	if ($line =~ s/^subject:\s*//i) {
	    $msg_subject = $line;
	    $cur_hdr = \$msg_subject;
	    # allow whitelisting by Subject if among -S args
	    $hdr_type = url_encode("substitute subject")
		if ('subject:' =~ /^($sub_hdrs):/i);
	    next;
	}

	if (!$no_body && $line =~ s/^($sub_hdrs):\s*//i) {
	    $hdr_type = $1;
	    $hdr_type =~ tr/A-Z/a-z/;
	    $hdr_type = url_encode("substitute $hdr_type");
	    $misc_hdr = $line;
	    $cur_hdr = \$misc_hdr;
	    next;
	}
    }

    # fake empty Message-ID if required
    if (!$seen_message_id && $num_hdrs) {
	$msg_hdrs .= "$edit_link${url_ques}type=";
	$msg_hdrs .= "Message-ID";
	$msg_hdrs .= "&amp;val=%3c%3e&amp;msg=$msg&amp;auto=1#cur_key\">missing Message-ID</A>\n";
    }

    # copy the body of the message
    for (;;) {
	if (!($line = <MSG>)) {
	    close(MSG);
	    return ($ise_msg, "message $msg truncated in body");
	}
	last if ($line =~ $cksum_marker_p);
	$line =~ s/[ \t\r]+$//mg;
	$msg_body .= html_text_encode($line) if (!$no_body);
    }


    # copy the checksums
    while ($line = <MSG>) {
	# notice quoted checksums that are part of the body
	if ($line =~ $cksum_marker_p) {
	    if (!$no_body) {
		$msg_body .= "<PRE class=mono>\n";
		$msg_body .= $cksum_marker;
		$msg_body .= $msg_cksums;
		$msg_body .= "</PRE>\n";
	    }
	    $msg_cksums = '';
	    $msg_result = ': ';
	    next;
	}

	$msg_cksums .= $line;

	# Build a string of all of the reasons why the message should
	#   have been accepted or rejected as we build the list of checksums.
	#   Use italics for disabled checks.
	$msg_result .= "MTA " if ($line =~ /\bMTA-->spam(\(first\))?/);
	$msg_result .= "MTA-OK " if ($line =~ /\bMTA-->OK(\(first\))?/);
	$msg_result .= "BL " if ($line =~ /\bwlist-->spam/);
	$msg_result .= "WL " if ($line =~ /\bwlist-->OK/);
	if ($line =~ /\bDCC-->spam(\(off\))?/) {
	    if ($1) {
		$msg_result .= "<I>DCC</I> ";
	    } else {
		$msg_result .= "DCC ";
	    }
	}
	if ($line =~ /\bDCC-->OK(\(off\))?/) {
	    if ($1) {
		$msg_result .= "<I>OK-DCC</I> ";
	    } else {
		$msg_result .= "OK-DCC ";
	    }
	}
	if ($line =~ /\bRep-->spam(\(off\))?/) {
	    if ($1) {
		$msg_result .= "<I>Rep</I> ";
	    } else {
		$msg_result .= "Rep ";
	    }
	}
	while ($line =~ s/\b(DNSBL\d?)-->spam(\(off\))?//) {
	    if ($2) {
		$msg_result .= "<I>$1</I> ";
	    } else {
		$msg_result .= "$1 ";
	    }
	}

	# Prefix the string of reasons with what was done.
	if ($line =~ /^result: temporary greylist embargo/) {
	    $msg_result = "Grey" . $msg_result;
	} elsif ($line =~ /^result: accept after greylist embargo/) {
	    $msg_result = "OK-Grey" . $msg_result;
	} elsif ($line =~ /^result: accept/) {
	    $msg_result = "OK" . $msg_result;
	} elsif ($line =~ /^result: reject temporarily/) {
	    $msg_result = "Delay" . $msg_result;
	} elsif ($line =~ /^result: reject/) {
	    $msg_result = "Reject" . $msg_result;
	} elsif ($line =~ /^result: discard/) {
	    $msg_result = "Discard" . $msg_result;
	} elsif ($line =~ /^result: .*abort/) {
	    $msg_result = "abort";
	}
    }
    $msg_result =~ s/^: //;
    $msg_cksums = html_str_encode($msg_cksums) if (!$no_body);


    close(MSG);
    return undef;
}



our (%msgs_date,
     %msgs_result,
     %msgs_from,
     %msgs_subject,
     $msg_day_first,
     $msg_day_last,
     $msg_first,
     $msg_last,
     $msg_newer,
     $msg_part_num,
     @msgs_num);		    # compressed names sorted by mtime

sub decode_dir_name {
    my($str) = @_;
    my($val, $i, $c);

    use integer;

    $val = 0;
    for ($i = 0; $i < length($str); ++$i) {
	$c = ord(substr($str, $i, 1));
	if ($c >= ord('a')) {
	    $c = $c - ord('a') + 10;
	} elsif ($c >= ord('A')) {
	    $c = $c - ord('A') + 10+26;
	} else {
	    $c -= ord('0');
	}
	$val = ($val * (10+26+26)) + $c;
    }
    return $val;
}



sub msg2path {
    my($msg, $path) = @_;

    $path = $logdir . '/' if (!defined $path);

    if (length($msg) >= 8) {
	$path .= sprintf("%03d/", decode_dir_name(substr($msg, 6, 2)));
	if (length($msg) >= 9) {
	    $path .= sprintf("%02d/", decode_dir_name(substr($msg, 8, 1)));
	    if (length($msg) >= 10) {
		$path .= sprintf("%02d/", decode_dir_name(substr($msg, 9, 1)));
	    }
	}
    }

    return $path . 'msg.' . substr($msg, 0, 6);
}



# flush one cache file
sub cache_write_file {
    my($buf, $cnum) = @_;
    my($tmp, $cfname, $date);

    $tmp = "msg.cache." . "new." . $$;
    if (!sysopen(CFILE, $tmp, O_WRONLY | O_CREAT, 0660)){
	print STDERR "open($tmp): $!\n";
	return undef;
    }
    if (syswrite(CFILE, $cache_version) != length($cache_version)
	|| syswrite(CFILE, $buf) != length($buf)) {
	print STDERR "syswrite $tmp: $!\n";
	close(CFILE);
	unlink($tmp);
	return undef;
    }

    close(CFILE);
    $cnum =~ /(\d+)/; $cnum = $1;	# suppress Perl taint warning
    $date = $cnum * (24*3600);
    if ($date <= time) {
	utime($date, $date, $tmp)
	    || print STDERR "utime($date, $date, $tmp): $!\n";
    }
    $cfname = "msg.cache." . $cnum;
    if (!rename($tmp, $cfname)) {
	print STDERR "rename($tmp, $cfname): $!\n";
	unlink($tmp);
	return undef;
    }

    $msgs_cache_state{$cnum} = 1;
    return 1;
}



# flush the cache files
sub cache_flush {
    my($cache_files, $log_files,
       $cnum, $cfname, $state, $new_cnum, $msg, $buf, $buf_start);

    if (! -w ".") {
	my $marker = "$logout_tmpdir/msg.$user-nocache";
	if (! -f $marker
	    || (stat(_))[9] < time()-(4*3600)) {
	    if (!open(CFILE,">>",$marker)){
		print STDERR "open($marker): $!\n";
	    } else {
		print CFILE "$logdir not writable for cache files\n";
		close CFILE;
	    }
	    print STDERR "$logdir not writable for cache files\n";
	}
	return;
    }

    $cache_files = 0;
    $log_files = 0;
    $buf_start = 0;

    $cnum = 0;
    foreach $msg (@msgs_num) {
	# There is one cache file per day, so pick the cache for this log file.
	#   The log file names are sorted by mtime in each cache file.
	$new_cnum = $msgs_cache{$msg}[0] / (24*3600);

	# skip this log file if its cache file is good
	next if ($msgs_cache_state{$new_cnum});

	# close the current cache file if we are dealing with a new day
	#	and so a new cache file
	if ($cnum != $new_cnum) {
	    if ($log_files - $buf_start > 10) {
		++$cache_files;
		return if (!cache_write_file($buf, $cnum));
		$buf_start = $log_files;
	    } else {
		# forget the cache file if it would be tiny
		$log_files= $buf_start;
	    }
	    undef $buf;
	    $cnum = $new_cnum;
	}

	$buf .= pack($cache_pack,
		     $msgs_cache{$msg}[0],
		     $msgs_cache{$msg}[1],
		     $msg);
	++$log_files;
    }
    if ($log_files - $buf_start > 10) {
	++$cache_files;
	cache_write_file($buf, $cnum);
    } else {
	$log_files= $buf_start;
    }

    # delete junk cache files
    while (($cnum, $state) = each %msgs_cache_state) {
	next if ($state);
	$cfname = "msg.cache." . $cnum;
	if (-f $cfname && !unlink($cfname)) {
	    print STDERR "unlink($cfname): $!\n";
	    return;
	}
    }

    debug_time("$cache_files cache flushed, $log_files msgs");
}



# get the list of messages
#   The first arg is the current file
#   Try to limit the size of the table to the second arg
#	divide days worth of files to fit the page size if it is <0

sub get_log_msgs {
    my($page_msg,			# target log message
       $page_size			# log files / web page
       ) = @_;
    my($msg_cache_len, %msg_cache_lens, $num_dated, $num_sorted,
       $need_flush, $cache_parse_limit,
       $dir_len, $line, $subdir, $msg, $entry, $buf, $days,
       $msg_tgt, $date_tgt, $date_cur, $date1, $msg_num, $msg_num_prev);

    $cache_parse_limit = 100;

    $cache_version = "DCC msg.cache version 3\n";
    $cache_pack = "LLA10";
    $cache_line_len = length(pack($cache_pack, 0));

    # Build a list of log file names and dates
    #	Use cache files of names and dates.  Validate the cache
    #	files by checking i-numbers.  Use the `ls` command because the
    #	the Perl readdir() function does not provide d_ino/d_fileno.

    chdir($logdir) || html_whine("chdir($logdir): $!");

    html_whine("ls -fiRC1 $logdir: $!")
	if (!open(DIR, "/bin/ls -fiRC1 |"));
    $dir_len = 0;
    $subdir = "";
    while ($line = <DIR>) {
	# log files are most common
	if ($line =~ /^(\d+)\s+msg\.([A-Za-z\d]{6})$/) {
	    next if (!defined $subdir);	# skip strange directories
	    $msgs_cache{$2  . $subdir}[1] = $1;
	    ++$dir_len;
	    next;
	}
	# Notice cache files
	if ($line =~ /^\s*\d+\s+(msg\.cache\.(\d{5}))\s*$/
	    && -f $1
	    && (((stat(_))[7] - length($cache_version))
		% $cache_line_len) == 0) {
	    next if (!defined $subdir);	# skip strange directories
	    $msgs_cache_state{$2} = 0;
	    next;
	}
	# Notice DDD, DDD/HH, and DDD/HH/MM subdirectories and ignore others
	# Compress and encode the subdirectory containing a file name as
	#   2, 3, or 4 characters appended to the last 6 characters of the name.
	if ($line =~ s/^\.\/(.*):$/$1/) {
	    $subdir = undef;
	    if ($line =~ /^(\d{3})(\/(\d{2}))?(\/(\d{2}))?$/) {
		next if ($1 > 366);	    # julian date must make sense
		my $dir_encode_str = ("0123456789"
				      . "abcdefghijklmnopqrstuvwxyz"
				      . "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
		my $new_subdir = (substr($dir_encode_str,
					 $1 / length($dir_encode_str), 1)
				  . substr($dir_encode_str,
					   $1 % length($dir_encode_str), 1));
		if (defined $3) {
		    next if ($3 >= 24);	    # hour must make sense
		    $new_subdir .= substr($dir_encode_str, $3, 1);
		    if (defined $5) {
			next if ($5 >= 60);	# demand a reasonable minute
			$new_subdir .= substr($dir_encode_str, $5, 1);
		    }
		}
		$subdir = $new_subdir;
	    }
	}
    }
    close(DIR);
    debug_time("$dir_len msgs found");

    # load the cache files
    #	    Because cache files are named with dates, are read in sorted
    #	    order, and have sorted contents, we do not need to sort
    #	    what we read from them.
    $msg_cache_len = 0;
    $need_flush = 0;
    foreach my $cnum (sort keys(%msgs_cache_state)) {
	my($total, $good, $date_lo, $date_hi);

	next if (!open(CFILE, "msg.cache." . $cnum));

	# ignore cache files with the right names but wrong magic
	if (!read(CFILE, $buf, length($cache_version))
	    || $buf ne $cache_version) {
	    close CFILE;
	    next;
	}

	# the log file names in a cache file are for a single day
	$date_lo = $cnum * 24*3600;
	$date_hi = $date_lo + 24*3600 - 1;
	$good = $total = 0;
	while (read(CFILE, $buf, $cache_line_len)) {
	    my($date, $ino, $msg) = unpack($cache_pack, $buf);
	    ++$total;

	    # a cache file is bogus if it contains bad dates
	    last if ($date < $date_lo || $date > $date_hi);

	    # skip deleted log files
	    next if (!exists($msgs_cache{$msg}));

	    # skip cached log file names that have been recycled
	    next if ($msgs_cache{$msg}[1] != $ino);

	    $msgs_cache{$msg}[0] = $date;
	    push @msgs_num, $msg;

	    ++$good;
	}
	close(CFILE);
	if ($good == 0 || $good+20 < $total) {
	    $need_flush = 1;
	} elsif ($good == $total) {
	    $msgs_cache_state{$cnum} = 1;
	}
	$msg_cache_len += $good;
	$msg_cache_lens{$cnum} = $good;
    }
    debug_time("$msg_cache_len     cached");

    # If there are any new log files,
    #	then we must get their dates and then sort the names by their mtimes
    if ($msg_cache_len != $dir_len) {
	# Save the cache if it contains enough to justify the cost of
	# flushing it. It is not worthwhile if there are only a few
	# new files and the total cache size is small enough that
	# sorting it for each request will not be slow.
	$need_flush = 1 if ($dir_len > $msg_cache_len+100 || $dir_len > 5000);

	# get mtimes for log files not in the cache files
	$date_tgt = time();
	$num_dated = 0;
	while (($msg, $entry) = each %msgs_cache) {
	    next if (@$entry[0]);	# this file is known from a cache file

	    my $date = (stat msg2path($msg))[9];
	    if (!$date) {
		# forget this file if we cannot stat() it
		delete $msgs_cache{$msg};
		next;
	    }
	    @$entry[0] = $date;
	    $msgs_cache_state{$date / (24*3600)} = 0;
	    ++$num_dated;
	    push @msgs_num, $msg;

	    # notice the oldest log file name not in the cache files
	    $date_tgt = $date if ($date_tgt > $date);
	}
	debug_time("$num_dated      dated");

	# We only need to sort the cache files that were incomplete.  That
	# will often be only the last cache file.
	# Start by finding the ordinal of the first name in the oldest
	# incomplete cache file.
	$date_tgt /= (24*3600);
	$num_sorted = 0;
	foreach my $cnum (sort keys(%msg_cache_lens)) {
	    last if ($cnum >= $date_tgt);
	    $num_sorted += $msg_cache_lens{$cnum};
	}

	if ($num_sorted < $#msgs_num) {
	    # This is obscure but much faster than using comparison functions
	    # that do hash lookups for each comparison of the sort
	    my @new_msgs_num = map {my @a = unpack("NA10",$_); $a[1]}
				    (sort map pack("NA10",
						   $msgs_cache{$_}[0],
						   $_),
				    @msgs_num[$num_sorted .. $#msgs_num]);
	    @msgs_num[$num_sorted .. $#msgs_num] = @new_msgs_num;
	} else {
	    # sort everything if necessary
	    $num_sorted = $#msgs_num+1;
	    @msgs_num = map {my @a = unpack("NA10",$_); $a[1]}
				(sort map pack("NA10",
					       $msgs_cache{$_}[0],
					       $_),
				 keys %msgs_cache);
	}

	debug_time($num_sorted . "     sorted");
    }

    # find the target message that must be listed
    $msg_tgt = ($#msgs_num >= 0) ? $#msgs_num : 0;
    if ($page_msg) {
	for ($msg_num = 0; $msg_num <= $#msgs_num; ++$msg_num) {
	    if ($msgs_num[$msg_num] eq $page_msg) {
		$msg_tgt = $msg_num;
		last;
	    }
	}
	debug_time("found #" . $msg_tgt);
    }

    # we are finished if the caller only wanted the list of files
    #   perhaps for URLs pointing to previous and next files
    if (!$page_size || $page_size < 1 || $#msgs_num < 0) {
	cache_flush() if ($need_flush);
	$msg_first = $msg_tgt;
	$msg_last = $#msgs_num;
	$msg_newer = $#msgs_num;
	$msg_part_num = 0;
	return;
    }

    # Get summary information from all of the files on the target day, the
    #	last file on the previous day, and on the first file on the next day.
    #
    # walk backward from the target to the first log file of the target day
    $date_tgt = $date_cur = (localtime $msgs_cache{$msgs_num[$msg_tgt]}[0])[7];
    for ($msg_day_first = $msg_tgt;
	 $msg_day_first > 0;
	 $msg_day_first = $msg_num) {
	$msg_num = $msg_day_first-1;
	$date_cur = (localtime $msgs_cache{$msgs_num[$msg_num]}[0])[7];
	last if ($date_cur != $date_tgt);
    }
    $msg_part_num = ($msg_tgt - $msg_day_first) / $page_size;
    $msg_first = $msg_day_first + ($msg_part_num * $page_size);

    # walk forward to the end of the day or $page_size files
    $days = 0;				# count space used by date headings
    $msg_last = $msg_first + $page_size-1;
    $msg_last = $#msgs_num if ($msg_last > $#msgs_num);
    $msg_newer = $msg_first + $page_size;
    $msg_newer = $#msgs_num if ($msg_newer > $#msgs_num);
    $msg_day_last = $#msgs_num;
    $date1 = $date_tgt;
    for ($msg_num = $msg_tgt+1; $msg_num <= $#msgs_num; ++$msg_num) {
	$date_cur = (localtime $msgs_cache{$msgs_num[$msg_num]}[0])[7];
	next if ($date_cur == $date1);

	++$days;

	if ($date1 == $date_tgt) {
	    $msg_day_last = $msg_num-1;

	    # the "newer" link goes to the first file of the next day if
	    #	the current day fits on the web page
	    $msg_newer = $msg_num if (!$msg_newer || $msg_num < $msg_newer);
	}

	last if ($msg_num > $msg_first + $page_size - $days);

	$msg_last = $msg_num-1 if ($#msgs_num > $msg_first+$page_size-$days);
	$date1 = $date_cur;
    }

    ++$msg_part_num if ($msg_part_num != 0
			|| $msg_first + $page_size <= $msg_day_last);
    # overlap the parts of a day by a line
    ++$msg_last if ($msg_part_num != 0 && $msg_last < $msg_day_last);

    # parse the log files to get the data
    for ($msg_num = $msg_first; $msg_num <= $msg_last; ++$msg_num) {
	$msg = $msgs_num[$msg_num];
	my(@error) = parse_log_msg($msg, "no body");
	if (defined $error[0]) {
	    $msgs_date{$msg} = strftime("%x %X",
					localtime($msgs_cache{$msg}[0]))
		if (!$msgs_date{$msg} && $msgs_cache{$msg}[0]);
	    $msgs_from{$msg} = "<STRONG class=warn>$error[0]</STRONG>";
	    $msgs_result{$msg} = '';
	    $msgs_subject{$msg} = "<STRONG class=warn>$error[1]</STRONG>";
	} else {
	    $msgs_date{$msg} = $msg_date;
	    $msgs_from{$msg} = hdr_trim_encode($msg_from
					       ? $msg_from
					       : $msg_env_from);
	    $msgs_result{$msg} = $msg_result ? $msg_result : "&nbsp;";
	    $msgs_subject{$msg} = hdr_trim_encode($msg_subject);
	}
    }
    debug_time(($msg_last - $msg_first + 1) . "     parsed");

    cache_flush() if ($need_flush);
}



##########################################################################
# whiteclnt file functions

# The file is represented as an array or list of references to 3-tuples.
#   The first of the three is the whitelist entry in a canonical form
#	as a key uniquely identifying the entry.
#   The second is a comment string of zero or more comment lines.
#   The third is the DCC whiteclnt entry.
#
#   The canonical form and the whiteclnt line of the first 3-tuple for a file
#   are null, because it contains the comments, if any, before the file's
#   preamble of dans when the file has been changed and flags.
#   The file[1] is an empty slot for adding option settings.
#   The last triple in a file may also lack a whitelist entry.

# There is a hash or dictionary of references to entries in the list


# lock, read, and parse the file
sub read_whiteclnt {
    my($file_ref, $dict_ref) = @_;
    my($entry, $prev_entry, $comment);

    @$file_ref = ();
    %$dict_ref = ();

    # Creating the file here is usually a waste of effort, because
    #	it must be writable by both the HTTP server and dccm or dccifd.
    #	They are probably not in any common group.
    # Let the /var/dcc/libexec/newwebuser script create the per-user
    #	directories and files.
    # Because whitelists might be a little sensitive, they should not be
    #	readable by "other"
    html_whine("open($whiteclnt): $!")
	if (!sysopen(WHITECLNT, $whiteclnt, O_RDWR | O_CREAT, 0660));
    chmod(0660, $whiteclnt);

    html_whine("flock($whiteclnt): $!")
	if (!flock(WHITECLNT, LOCK_EX | LOCK_NB));

    $comment = "";
    while ($entry = <WHITECLNT>) {
	# end the last line properly even if the file doesn't
	$entry .= "\n" if (substr($entry,-1) ne "\n");

	# collect lines until we get a non-comment
	if ($entry =~ /^\s*(#|$)/) {
	    $comment .= $entry;
	    next;
	}

	# use the previous count if the current value is missing,
	#	because that is what parse_whitefile.c does.
	$entry = "$1$entry"
	    if ($entry =~ /^[ \t]/
		&& $#$file_ref > 0
		&& ($prev_entry = ${${$file_ref}[$#$file_ref]}[2])
		&& $prev_entry =~ /^(\S+)/);

	add_white_entry($file_ref, $dict_ref, $comment, $entry);
	$comment = "";
    }

    # save a non-trivial trailing comment
    add_white_entry($file_ref, $dict_ref, $comment, "")
	if ($comment && $comment !~ /^\s*$/);
}



# read the main whiteclnt file to determine the default option settings
sub read_whitedefs {
    my($def_ref) = @_;
    my(@sb1, @sb2, $line, @parsed, $bydef);


    # these defaults for the defaults must match parse_whitefile.c
    #	or elsewhere in the DCC client source (e.g. for discardok)
    %$def_ref = ();
    $bydef = " <SMALL>by default</SMALL>";
    ${$def_ref}{dccenable} = "<STRONG>on</STRONG>$bydef";
    ${$def_ref}{greyfilter} = "<STRONG>on</STRONG>$bydef";
    ${$def_ref}{greylog} = "<STRONG>on</STRONG>$bydef";
    ${$def_ref}{mtafirst} = "<STRONG>last</STRONG>$bydef";
    ${$def_ref}{rep} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{dnsbl1} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{dnsbl2} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{dnsbl3} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{dnsbl4} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{logall} = "<STRONG>off</STRONG>$bydef";
    ${$def_ref}{discardok} = "<STRONG>delay mail</STRONG>$bydef";

    foreach my $ck (split(/,/,$thold_cks)) {
	my $nm = "thold-$ck";
	if (!$conf_cks_tholds{$ck}) {
	    ${$def_ref}{$nm} = "<STRONG>Never</STRONG>$bydef";
	} else {
	    ${$def_ref}{$nm} = $conf_cks_tholds{$ck};
	}
    }

    if (!sysopen(MAINWHITE, $main_whiteclnt, O_RDONLY, 0)) {
	print STDERR "open(${main_whiteclnt}: $!\n";
	return;
    }

    if (!(@sb1 = stat(MAINWHITE))) {
	print STDERR "stat(${main_whiteclnt}: $!\n";
    } elsif (!(@sb2 = stat(WHITECLNT))) {
	print STDERR "stat(${$whiteclnt}: $!\n";
    } elsif ($sb1[0] == $sb2[0] && $sb1[1] == $sb2[1]) {
	# ignore it if we are somehow working on the main file
    } else {
	while ($line = <MAINWHITE>) {
	    # skip everything except option settings
	    next if ($line !~ /^\s*option\s+/i);

	    @parsed = parse_white_entry($line, "option");
	    next if (!$parsed[1]);
	    ${$def_ref}{$parsed[0]} = "<STRONG>$parsed[2]</STRONG> <SMALL>by default in $main_whiteclnt</SMALL>";
	}
    }
    close(MAINWHITE);
}



# add an entry to our image of the file
our ($whiteclnt_version,	#webuser version ...
    $whiteclnt_notify,		#webuser mail-notify=X mailbox=Y
    $whiteclnt_notify_pat,	#regex for #webuser mail-notify=X mailbox=Y
    $whiteclnt_lock,		#webuser (un)locked
    $whiteclnt_cur_key,		#editing position in the file
    $whiteclnt_change_log);	#list of dates when file was changed


sub add_white_entry {
    my($file_ref, $dict_ref, $comment, $line) = @_;
    my(@parsed);

    # trim unneeded white space
    $line =~ s/\s+$//;
    $comment =~ s/[ \t]+$//mg;

    # deal with the preamble.
    #	The preamble consists of the comments that start the file.
    if (! @$file_ref) {
	my($preamble, @buf);

	# remove the change-history, version, and parameters from the preamble
	$whiteclnt_version = "#webuser version 1.0\n";
	while ($comment =~ s/^#webuser version ([0-9.]+)\n/ \n/m) {
	    # for now, insist on version 1.0
	    html_whine("unrecognized version $1 in $whiteclnt")
	       if ($1 ne "1.0");
	}

	$whiteclnt_notify_pat = '(#webuser mail-notify=)(on|off)( mailbox=)([-_a-z0-9]*)';
	$whiteclnt_notify = "#webuser mail-notify=off mailbox=\n";
	while ($comment =~ s/^$whiteclnt_notify_pat\n/ \n/im) {
	    $whiteclnt_notify = "$1$2$3$4\n";
	}

	$whiteclnt_lock = "#webuser unlocked\n";
	while ($comment =~ s/^#\s*webuser\s+unlocked\n/ \n/im) {
	}
	while ($comment =~ s/^#\s*webuser\s+locked\n/ \n/im) {
	    $whiteclnt_lock = "#webuser locked\n";
	}

	$whiteclnt_cur_key = "";
	while ($comment =~ s/^#\s*webuser\s+cur_key\s+(.*)\n/ \n/im) {
	    $whiteclnt_cur_key = $1;
	}

	$whiteclnt_change_log = "";
	while ($comment =~ s/^#\s*webuser created\s+(.+\n)/ \n/im) {
	    $whiteclnt_change_log = "#webuser created $1";
	}
	undef(@buf);
	while ($comment =~ s/^#webuser\s+changed\s+(.+\n)/ \n/im) {
	    push(@buf, "#webuser changed $1");
	}
	# keep only the last 20 dates of change
	if (@buf) {
	    my($start);
	    $start = $#buf-20;
	    $start = 0
		if ($start < 0);
	    $whiteclnt_change_log .= join('', @buf[$start .. $#buf]);
	}

	# We have removed the parameter lines from the first comment of the
	# file and replaced them with " \n"
	# Before starting we remove blanks from the ends of lines.
	# The first block of comments must now be divided between (1) comments
	# about the file and (2) comments about the first real line of the file.
	if ($comment =~ s/^(.* \n)//s) {
	    # Take the comment lines through the last marker if there were any.
	    # Add the first blank line after the markers if present.
	    $preamble = $1;
	    $preamble .= "\n" if ($comment =~ s/^\n//);
	    # remove the markers for detected parameter lines
	    $preamble =~ s/ \n//g;
	} else {
	    # without parameters, take lines through the first blank line as (1)
	    $preamble = ($comment =~ s/(.*?\n\n)//s
			 || $comment =~ s/(.*?\n[# \t]+\n)//s) ? $1 : "";
	}

	# start the memory copy of the file with the preamble
	#   and the spare slot for option changes
	@$file_ref = ([undef, $preamble, ""], ["", undef, undef]);

	# finished if the file has no entries,
	return if (!$line && !$comment);

	# or deal with the first entry
    }

    # If the line makes sense, remember where it will be.
    # Treat the line as a comment if it makes no sense
    @parsed = parse_white_entry($line, "");
    if (!$parsed[1]) {
	$comment .= $line;
	$comment .= "\n" if ($comment !~ /\n$/);
	push @$file_ref, [undef, $comment, ""];
    } else {
	my($cur_key, $entry, $i, $k);

	$cur_key = $parsed[0];
	$entry = [$cur_key, $comment, $parsed[1]];
	push @$file_ref, $entry;

	if (${$dict_ref}{$cur_key}) {
	    $i = 0;
	    # mark duplicate values for eventual deletion
	    #	keep the last setting in the file
	    while (${$dict_ref}{$k = "DUP-$i-$cur_key"}) {
		++$i;
	    }
	    ${$dict_ref}{$k} = ${$dict_ref}{$cur_key};
	}
	${$dict_ref}{$cur_key} = $entry;
    }
}


# check the syntax of IP addresses, ranges, and CIDR blocks
#   return undef if ok but an error string if not
sub check_ip {
    my($value) = @_;
    my($result, $hi, $lo);

    return "blank or missing IP address" if (!$value);

    $value =~ s/[\s`|>]/BAD/g;		# mere paranoia because of the quotes
    $value =~ /(.*)/;			# untaint
    $result = `/var/dcc/libexec/check_ip_range '$1' 2>&1`;
    chomp($result);
    if ($? == 0) {
	$value = $result;
	$result = undef;
    }

    return ("IP", $value, $result)
}



sub check_present {
    my($type, $value) = @_;

    # dcc_str2ck() via dcc_parse_ck() ignores outside quotes and <>,
    # whitespace, and upper/lower case, and trailing periods.  So our key must
    #	also.
    # The value for the line in the file need not be as clean.
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/^<\s*(.+)\s*>$/$1/
	if ($value !~ s/^"\s*(.+)\s*"$/$1/);
    $value =~ s/\.+$//;

    return ($type, $value) if ($value);
    return ($type, "<>", "blank or missing $type value");
}



sub check_hex {
    my($type, $value) = @_;

    return ($type, $value, "blank or missing $type value")
	if (!$value);

    return ($type, $value) if ($value =~ s/([0-9a-f]{8})\s+([0-9a-f]{8})
					\s+([0-9a-f]{8})\s+([0-9a-f]{8})$
					/$1 $2 $3 $4/ix);

    return ($type, $value, "\"$value\" is an invalid $type checksum");
}



# canonicalize a whitelist checksum "type value" string
#   return a (type, value) pair or (x, x, "error string") triple
sub parse_type_value {
    my $value = $_[0];

    # Check for type
    #	    Don't support received checksums.
    #	    Body checksums must be hex.
    $value =~ s/\s+$//;

    return check_ip($value)
	if ($value =~ s/^IP:?(\s*|$)//i);

    return check_present("env_From", $value)
	if ($value =~ s/^env[-_]from:?(\s+|$)//i);

    return check_present("env_To", $value)
	if ($value =~ s/^env[-_]To:?(\s+|$)//i);

    return check_present("From", $value)
	if ($value =~ s/^from:?(\s+|$)//i);

    return check_present("Message-ID", $value)
	if ($value =~ s/^message[-_]id:?(\s+|$)//i);

    # don't worry much about substitute types.
    return check_present("substitute $1", $value)
	if ($value =~ s/^substitute\s+([-a-z_0-9]+)+:?(\s+|$)//i);

    return check_hex("hex Body", $value)
	if ($value =~ s/^hex\s+body:?(\s+|$)//i);

    return check_hex("hex Fuz$1", $value)
	if ($value =~ s/^hex\s+fuz([12]):?(\s+|$)//i);

    return (undef, undef, "unrecognized whiteclnt value \"$value\"");
}



# canonicalize a threshold setting
sub parse_thold_value {
    my($pat, $type, $val);

    # check the name of the checksum by converting it into a pattern
    #	and matching it against the list of checksum types that can have
    #	per-user thresholds
    $pat = ",($_[0]),";
    $pat =~ s/[-_]/[-_]/g;
    $type = ',' . $thold_cks . ',';
    return 0 if ($type !~ /$pat/i);
    $type = $1;

    # check the threshold value
    if ($_[1] =~ /^Never$/i) {
	$val = 'Never';
    } elsif ($_[1] =~ /^many/i) {
	# reputation threshold is a % and reputation total is finite
	return 0 if ($type =~ /^rep/);
	$val = "many";
    } elsif ($_[1] =~ /^\d+$/) {
	$val = $_[1];
	if ($type =~ /^rep$/i) {
	    return 0 if ($val > 100);
	    $val .= '%';
	}
    } elsif ($_[1] =~ /^(\d+)%$/) {
	# reputation threshold is a %
	return 0 if ($1 > 100 || $type !~ /^rep$/i);
	$val = $_[1];
    } else {
	return 0;
    }


    $_[0] = $type;
    $_[1] = $val;
    return 1;
}



# See if a whiteclnt line makes sense
#   If so, return a list of key and canonicalized line.
#	If it is an option setting, return a third string that is the value
#	for the edit form.
#   If not, return only an error message.
sub parse_white_entry {
    my($line,					# line to parse
       $mode					# ''=accept from file,
						# 'option'=new option setting
						# 'strict'=new whitelist entry
       ) = @_;

    my($count, $key, $type, $value, $emsg);

    # recognize options
    if (!$mode || $mode eq "option") {
	return ("dccenable", "option dcc-$1\n", "$1")
	    if ($line =~ /^\s*option\s+DCC-(on|off)\s*$/i);

	return ("greyfilter", "option greylist-$1\n", "$1")
	    if ($line =~ /^\s*option\s+greylist-(on|off)\s*$/i);

	return ("greylog", "option greylist-log-$1\n", "$1")
	    if ($line =~ /^\s*option\s+greylist-log-(on|off)\s*$/i);

	return ("mtafirst", "option MTA-$1\n", "$1")
	    if ($line =~ /^\s*option\s+MTA-(first|last)\s*$/i);

	return ("rep", "option DCC-rep-$1\n", "$1")
	    if ($line =~ /^\s*option\s+DCC-reps?-(on|off)\s*$/i);

	return ("dnsbl1", "option dnsbl1-$1\n", "$1")
	    if ($line =~ /^\s*option\s+dnsbl-(on|off)\s*$/i);
	return ("dnsbl$1", "option dnsbl$1-$2\n", "$2")
	    if ($line =~ /^\s*option\s+dnsbl([1234])-(on|off)\s*$/i);

	return ("logall", "option log-all\n", "on")
	    if ($line =~ /^\s*option\s+log-all\s*$/i);
	return ("logall", "option log-normal\n", "off")
	    if ($line =~ /^\s*option\s+log-normal\s*$/i);

	return ("logsubdir", "option log-subdirectory-$1\n", "$1")
	   if ($line =~ /^\s*option\s+log-subdirectory-(day|hour|minute)\s*$/i);

	return ("discardok", "option forced-discard-ok\n", "discard spam")
	    if ($line =~ /^\s*option\s+forced-discard-ok\s*$/i);
	return ("discardok", "option no-forced-discard\n", "delay mail")
	    if ($line =~ /^\s*option\s+no-forced-discard\s*$/i
		|| $line =~ /^\s*option\s+forced-discard-nok\s*$/i); # obsolete

	if ($line =~ /^\s*option\s+threshold\s+(\S+),(\S+)\s*$/i) {
	    $type = $1;
	    $value = $2;
	    return ("thold-$type", "option threshold $type,$value\n", "$value")
		if (parse_thold_value($type, $value));
	}

	# recognize old logging options
	return ("greylog", "option greylist-log-on\n", "on")
	    if ($line =~ /^\s*log\s+all-grey\s*$/i);
	return ("greylog", "option greylist-log-off\n", "off")
	    if ($line =~ /^\s*log\s+no-grey\s*$/i);

	# we are finished if only parsing a new option line we know is ok
	return "unrecognized option line" if ($mode && $mode eq "option");
    }

    # must be "" with a bad option or "strict" when we should see an option
    return "unrecognized option line"
	if ($line =~/^log/i || $line =~ /^option/i);

    return "unrecognized line" if ($line !~ /^(\S+)\s+(.*)/);
    $count = $1;
    $value = $2;

    return "unrecognized count \"$count\"" if ($count !~ /many|ok|ok2/i);

    ($type, $value, $emsg) = parse_type_value($value);
    return $emsg if ($emsg);

    # build the whiteclnt line
    $line = "$count\t$type";
    $line .= (length($type) < 8) ? "\t" : ' ';
    $line .= "$value\n";

    $value =~ s/\s//g;
    $value =~ tr/A-Z/a-z/;
    $key = "$type $value";

    return ($key, $line);
}



# check a proposed entry
#   return an array of the error message if the proposed entry is bogus
#	or an array of (key, comment, line) if it make sense
sub ck_new_white_entry {
    my($comment, $count, $type, $value) = @_;
    my(@parsed, @entry);

    return "missing comment" if (!defined($comment));
    return "missing count" if (!$count);
    return "missing type" if (!$type);
    return "missing value" if (!$value);

    # trim trailing whitespace from the comment lines
    $comment =~ s/\s+\n/\n/g;
    # ensure comment lines start with '#'
    $comment =~ s/^([ \t]*[^# \t\n])/#$1/gm;
    # trim trailing blank lines from the comment
    $comment =~ s/\s+$//s;
    $comment .= "\n" if (length($comment) != 0);

    @parsed = parse_white_entry("$count $type $value", "strict");
    return ($parsed[0])	if (!defined($parsed[1]));

    $entry[0] = $parsed[0];
    $entry[2] = $parsed[1];
    $entry[1] = $comment;
    return @entry;
}



# add, change, or delete a whitelist entry
#   write our image of the file to disk, changing it as we go
#   then read the file
sub chg_white_entry {
    my($file_ref,			# the file in memory
       $dict_ref,			# dictionary for the file
       $cur_key,			# change or delete this entry
       $entry_ref,			# change this if not null
       $add_pos				# add before this if defined
       ) = @_;
    my($msg, $i, $k, @file);

    return "$whiteclnt locked" if ($whiteclnt_lock =~ /\blocked/);

    @file = @$file_ref;

    if (!${$dict_ref}{$cur_key}) {
	# it is a new entry if it exists
	if ($entry_ref) {
	    # add it to the list that will go to the disk
	    ${$dict_ref}{$cur_key} = @$entry_ref;
	    if (!$add_pos || $add_pos > $#file) {
		# append to the file without a good position
		push @file, $entry_ref;
	    } else {
		# insert at the right position
		@file = (@file[0 .. $add_pos-1],
			 $entry_ref,
			 @file[$add_pos .. $#file]);
	    }
	}

    } else {
	# changing or deleting existing entry, so delete duplicates
	$i = 0;
	while (${$dict_ref}{$k = "DUP-$i-$cur_key"}) {
	    ${$dict_ref}{$k}[1] = undef;
	    ++$i;
	}

	if (!$entry_ref) {
	    # delete an entry
	    ${$dict_ref}{$cur_key}[1] = undef;

	} else {
	    # change an entry
	    @{${$dict_ref}{$cur_key}} = @$entry_ref;
	}
    }

    # put the changes on the disk
    $msg = write_whiteclnt(@file);
    return $msg if ($msg);

    # set the web form that includes the response
    read_whiteclnt($file_ref, $dict_ref);
    return undef;
}



# write a new version of the file
sub write_whiteclnt {		# return undef or error message
    my(@file) = @_;
    local(*DIR, *BAK);
    my(@baks, $bak, $buf, $entry, $preamble);

    # delete old backup files and find the name of the next one
    # keep only the last few and fairly recent revisions
    opendir(DIR, "$user_dir") or html_whine("opendir($user_dir): $!");
    @baks = map("$user_dir/$_",
		sort grep {/^(whiteclnt\.bak\d+$)/ && -f "$user_dir/$1"}
			readdir(DIR));
    closedir(DIR);
    while ($#baks > 1 && ($baks[0] =~ /(.*\/whiteclnt\.bak\d+$)/)
	   && ((-M $1) >= 1 || $#baks >= 19)) {
	unlink $1;			# suppress taint warning
	shift(@baks);
    }
    if ($#baks >= 0) {
	$baks[$#baks] =~ /\/whiteclnt\.bak(\d+)$/;
	$bak = sprintf("%s/whiteclnt.bak%06d", $user_dir, $1+1);
    } else {
	$bak = "$whiteclnt.bak000000";
    }

    # create the undo file and copy the real file to it
    #	It could be smoother to rename the current file, but we might
    #	not have permission to create the new file with the correct owner.
    #	There are also dangers with symbolic links and rename().
    return "cannot create $bak: $!"
	if (!sysopen(BAK, $bak, O_WRONLY | O_CREAT | O_EXCL, 0660));
    return "seek($whiteclnt): $!"
	if (!seek(WHITECLNT, 0, 0));
    while (read(WHITECLNT, $buf, 8*1024)) {
	return "write($bak): $!"
	    if (!syswrite(BAK, $buf));
    }
    close(BAK);

    # rewrite the real file
    return "seek($whiteclnt): $!"
	if (!seek(WHITECLNT, 0, 0));
    return "truncate($whiteclnt): $!"
	if (!truncate(WHITECLNT, 0));

    $preamble = 0;
    foreach $entry (@file) {
	# skip deleted entries,
	next if (!defined($$entry[1]));

	# put the parameters in the preamble
	if (!$preamble) {
	    $preamble = $$entry[1];
	    $whiteclnt_change_log .= strftime("#webuser changed %x %X%n",
					      localtime);
	    $preamble =~ s/\n(\n?)$/\n/;
	    $whiteclnt_change_log .= $1;
	    print WHITECLNT $preamble;
	    print WHITECLNT $whiteclnt_version;
	    print WHITECLNT $whiteclnt_notify;
	    print WHITECLNT $whiteclnt_lock;
	    print WHITECLNT "#webuser cur_key $whiteclnt_cur_key\n"
		if ($whiteclnt_cur_key);
	    print WHITECLNT $whiteclnt_change_log;
	} else {
	    print WHITECLNT $$entry[1];
	    print WHITECLNT $$entry[2];
	}
    }

    return undef;
}



# undo the most recent operation by copying from the newest backup
sub undo_whiteclnt {
    my($bak, $buf);
    local(*BAK);

    return "$whiteclnt locked" if ($whiteclnt_lock =~ /\blocked/);

    $bak = newest_whiteclnt_bak();
    return "nothing undone"
	if (!$bak);

    return "open($bak): $!"
	if (!open(BAK, "< $bak"));

    return "seek($whiteclnt): $!"
	if (!seek(WHITECLNT, 0, 0));
    return "truncate($whiteclnt): $!"
	if (!truncate(WHITECLNT, 0));
    while (read(BAK, $buf, 8*1024)) {
	return "write($whiteclnt): $!"
	    if (!print(WHITECLNT $buf));
    }

    return "unlink($bak): $!"
	if (!unlink($bak));

    return undef;
}



# find the newest backup file
sub newest_whiteclnt_bak {
    local(*DIR);
    my(@baks, $bak);

    opendir(DIR, "$user_dir") || return undef;
    @baks = sort grep {/^whiteclnt\.bak\d+/ && -f "$user_dir/$_"}
		    readdir(DIR);
    closedir(DIR);

    return undef
	if ($#baks < 0);
    $bak = "$user_dir/$baks[$#baks]";
    return undef
	if (-M $bak >= 1);
    return undef				# suppress taint warning
	if ($bak !~ /(.*\/whiteclnt\.bak\d+$)/);
    return $1;
}
