#!/usr/bin/perl -w

# This file is part of Product Opener.
#
# Product Opener
# Copyright (C) 2011-2019 Association Open Food Facts
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use Modern::Perl '2017';
use utf8;

use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:cgi :form escapeHTML/;

use ProductOpener::Lang qw/:all/;
use ProductOpener::Display qw/:all/;
use ProductOpener::Food qw/:all/;

use CGI qw/:cgi :form escapeHTML/;
use JSON::PP;

ProductOpener::Display::init();

# Turn the flat nutriments table array into a nested array of nutrients
# The level of each nutrient is indicated by leading dashes before its id:
# nutrient
# -sub-nutrient
# --sub-sub-nutrient

my @table = ();
my $parent_level0;
my $parent_level1;

foreach (@{$nutriments_tables{$nutriment_table}}) {
	my $nid = $_;	# Copy instead of alias

	$nid =~/^#/ and next;
	my $important = ($nid =~ /^!/) ? JSON::PP::true : JSON::PP::false;
	$nid =~ s/!//g;
	my $default_edit_form = $nid =~ /-$/ ? JSON::PP::false : JSON::PP::true;
	$nid =~ s/-$//g;

	my $onid = $nid =~ s/^(\-+)//gr;

	my $current_ref = { id => $onid, important => $important, display_in_edit_form => $default_edit_form };
	my $name = get_nutrient_label($onid, $lc);
	if (defined $name) {
		$current_ref->{name} = $name;
	}

	my $prefix_length = 0;
	if ($nid =~ s/^--//g) {
		$prefix_length = 2;
	} elsif($nid =~ s/^-//g) {
		$prefix_length = 1;
	}

	if ($prefix_length == 0) {
		#  I'm on level 2, my parent is the latest level 1 parent
		push @table, $current_ref unless not defined $current_ref;
		$parent_level0 = $current_ref;
	}
	elsif ($prefix_length == 1) {
		# I'm on level 0, I have no parent, and I'm the latest level 0 parent
		@{$parent_level0->{nutrients}} = () unless defined $parent_level0->{nutrients};
		push @{$parent_level0->{nutrients}}, $current_ref unless not defined $current_ref;
		$parent_level1 = $current_ref;
	}
	elsif ($prefix_length == 2) {
		#  I'm on level 1, my parent is the latest level 0 parent, and I'm the latest level 1 parent
		@{$parent_level1->{nutrients}} = () unless defined $parent_level1->{nutrients};
		push @{$parent_level1->{nutrients}}, $current_ref unless not defined $current_ref;
	}
}

my %result = ( nutrients => \@table );
my $data = encode_json(\%result);
print header( -type => 'application/json', -content_language => $lc, -charset => 'utf-8', -access_control_allow_origin => '*', -cache_control => 'public, max-age: 86400' ) . $data;
