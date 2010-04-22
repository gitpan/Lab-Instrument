#!/usr/bin/perl
#$Id: Build.PL 646 2010-04-19 20:31:07Z schroeer $

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Lab::Instrument',
    dist_abstract     => 'Instrument drivers for Lab::VISA',
    dist_version_from => 'README',
    license           => 'perl',
    requires          => {
        'Lab::VISA'     => '2.03',
        'Time::HiRes'   => 0,
    },
    test_files        => [ 't/3_source.t', 't/4_dummysource.t' ],
    script_files      => [],
    create_readme     => 0,
    dist_author       => 'Daniel Schröer <schroeer@cpan.org>',
    meta_merge        => {
        resources       => {
            homepage      => 'http://labvisa.de',
            bugtracker    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lab-Instrument',
            MailingList   => 'https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users',
        }
    },
);
$build->create_build_script;
