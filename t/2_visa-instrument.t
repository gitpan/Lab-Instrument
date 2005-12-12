#!/usr/bin/perl
#$Id: 2_visa-instrument.t 201 2005-11-19 00:21:02Z schroeer $

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Lab::Instrument') };

ok(my $vi=new Lab::Instrument(0,24),'Open any instrument');
ok(my $idn=$vi->Query('*IDN?'),'Query identification');
diag "Instrument $idn";
