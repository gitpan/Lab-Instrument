#!/usr/bin/perl
#$Id: 7_Yokogawa7651.t 75 2005-11-09 23:24:29Z schroeer $

use strict;
use Test::More tests => 6;

BEGIN { use_ok('Lab::Instrument::Yokogawa7651') };
ok(my $yoko=new Lab::Instrument::Yokogawa7651({
	'GPIB_board'		=> 0,
	'GPIB_address'		=> 10}),'Open Yoko');

ok(my $status=$yoko->{vi}->Write('H1'),'Write H1');

ok(my $voltage=$yoko->get_voltage(),'get_voltage()');
diag "voltage: $voltage";

ok(my $range=$yoko->get_range(),'get_range()');
diag "range: $range";

ok($yoko->set_voltage(0.1),'set_voltage(0.1)');
