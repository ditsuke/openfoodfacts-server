﻿# This file is part of Product Opener.
# 
# Product Opener
# Copyright (C) 2011-2015 Association Open Food Facts
# Contact: contact@openfoodfacts.org
# Address: 21 rue des Iles, 94100 Saint-Maur des Fossés, France
# 
# Product Opener is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package Blogs::Mail;

BEGIN
{
	use vars       qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw();            # symbols to export by default
	@EXPORT_OK = qw(
					&send_email
					&send_email_to_admin
					&send_email_to_admin_from_user

					);	# symbols to export on request
	%EXPORT_TAGS = (all => [@EXPORT_OK]);
}

use vars @EXPORT_OK ;
use strict;
use utf8;

use Blogs::Store qw/:all/;
use Blogs::Config qw/:all/;
use Blogs::Lang qw/:all/;
use MIME::Lite;
use Encode;

sub send_email($$$)
{
	my $user_ref = shift;
	my $subject = shift;
	my $text = shift;
	
	my $email = $user_ref->{email};
	my $name = $user_ref->{name};
	
	$text =~ s/<NAME>/$name/g;

	my %msg = (
		'From' => encode("MIME-B", "\"" . lang("site_name") . "\" <$contact_email>"),
		'To' => encode("MIME-B", "\"$name\" <$email>"),
		'Encoding' => 'quoted-printable',
		'Subject' => encode("MIME-B", $subject),
		'Data' => encode("utf8", $text),
	);
	
	#$msg->attach(
	#Type => 'text/plain; charset=UTF-8',
	#Data => encode("utf8", $text),
	#);

		
	my $mime_email = MIME::Lite->new(%msg);
	$mime_email->attr('content-type.charset' => 'UTF-8');
	eval { $mime_email->send; };
    return $@ ? 1 : 0;
    
}

sub send_email_to_admin($$)
{
	my $subject = shift;
	my $text = shift;

	my %msg = (
		'From' => encode("MIME-B","\"" . lang("site_name") . "\" <$contact_email>"),
		'To' => encode("MIME-B","\"" . lang("site_name") . "\" <$admin_email>"),
		'Encoding' => 'quoted-printable',
		'Subject' => encode("MIME-B",$subject),
		'Data' =>  encode("utf8", $text),
	);
		
	my $mime_email = MIME::Lite->new(%msg);
	$mime_email->attr('content-type.charset' => 'UTF-8');
	eval { $mime_email->send; };
	
    if ( $@ ) {
	    print STDERR "WARNING no email sent to admin: \n" . $mime_email->as_string . "\n";
        return 1;
    } else {
	    print STDERR "sent email to admin: \n" . $mime_email->as_string . "\n";
        return 0;
    }
}

sub send_email_to_admin_from_user($$$) # useful so that the admin can do a reply to
{
	my $user_ref = shift;
	my $subject = shift;
	my $text = shift;
	
	my $email = $user_ref->{email};
	my $name = $user_ref->{name};
	
	$text =~ s/<NAME>/$name/g;

	my %msg = (
		'To' => encode("MIME-B","\"" . lang("site_name") . "\" <$contact_email>"),
		'From' => encode("MIME-B","\"$name\" <$email>"),
		'Reply-to' => encode("MIME-B","\"$name\" <$email>"),
		'Encoding' => 'quoted-printable',
		'Subject' => encode("MIME-B",$subject),
		'Data' => encode("utf8", $text),
	);
		
	my $mime_email = MIME::Lite->new(%msg);
	$mime_email->attr('content-type.charset' => 'UTF-8');
	eval { $mime_email->send; };
    return $@ ? 1 : 0;
}



1;
