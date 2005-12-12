#!/usr/bin/perl
#$Id: 6_KnickS252.t 201 2005-11-19 00:21:02Z schroeer $

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Lab::Instrument::KnickS252') };

ok(my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 16,
	'gp_max_volt_per_second'	=> 0.021}),'Open any Knick');
ok(my $voltage=$knick->get_voltage(),'get_voltage()');
diag "read $voltage";
