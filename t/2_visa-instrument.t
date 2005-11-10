#!/usr/bin/perl
#$Id: 2_visa-instrument.t 75 2005-11-09 23:24:29Z schroeer $

use strict;
use Test::More tests => 3;

BEGIN { use_ok('Lab::Instrument') };

ok(my $vi=new Lab::Instrument(0,24),'Open any instrument');
ok(my $idn=$vi->Query('*IDN?'),'Query identification');
diag "Instrument $idn";
