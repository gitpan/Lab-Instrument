#!/usr/bin/perl
#$Id: simple_knick.pl 85 2005-11-10 23:35:43Z schroeer $

use strict;
use Lab::Instrument::KnickS252;

my $knick=new Lab::Instrument::KnickS252({
	'GPIB_board'				=> 0,
	'GPIB_address'				=> 16,
	'gp_max_volt_per_second'	=> 0.021});
$knick->set_voltage(1);
my $voltage=$knick->get_voltage();
print "read $voltage\n";
