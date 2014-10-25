#$Id: Instrument.pm 475 2006-08-10 22:06:46Z schroeer $

package Lab::Instrument;

use strict;
use Lab::VISA;

our $VERSION = sprintf("1.%04d", q$Revision: 475 $ =~ / (\d+) /);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    my @args=@_;
    
    my ($status,$res)=Lab::VISA::viOpenDefaultRM();
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot open resource manager: $status";}
    $self->{default_rm}=$res;

    my $resource_name;
    if ((ref $args[0]) eq 'HASH') {
        my $config=$args[0];
        if (defined ($config->{GPIB_address})) {
            @args=(
                (defined ($config->{GPIB_board})) ? $config->{GPIB_board} : 0,
                 $config->{GPIB_address});
        } else {
            die "scheiss argumente";
        }
    }
    if ($#args >0) { # GPIB
        $resource_name=sprintf("GPIB%u::%u::INSTR",$args[0],$args[1]);
    } elsif ($args[0] =~ /ASRL/) {  # serial
        $resource_name=$args[0]."::INSTR";
    } else {    #find
        ($status,my $listhandle,my $count,my $description)=Lab::VISA::viFindRsrc($self->{default_rm},'?*INSTR');
        if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot find resources: $status";}  
        my $found;
        while ($count-- > 0) {
            print STDERR  "Lab::Instrument: checking $description\n";
            ($status,my $instrument)=Lab::VISA::viOpen($self->{default_rm},$description,$Lab::VISA::VI_NULL,$Lab::VISA::VI_NULL);
            if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot open instrument $description. status: $status";}
            my $cmd='*IDN?';
            $self->{instr}=$instrument;
            my $result=$self->Query($cmd);
            $status=Lab::VISA::viClose($instrument);
            if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot close instrument $description. status: $status";}
            print STDERR  "Lab::Instrument: id $result\n";
            if ($result =~ $args[0]) {
                $resource_name=$description;
                $count=0;
            }
            if ($count) {
                ($status, $description)=Lab::VISA::viFindNext($listhandle);
                if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot find next instrument: $status";}
            }
        }
        $status=Lab::VISA::viClose($listhandle);
        if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot close find list: $status";}     
    }
    
    if ($resource_name) {
        ($status,my $instrument)=Lab::VISA::viOpen($self->{default_rm},$resource_name,$Lab::VISA::VI_NULL,$Lab::VISA::VI_NULL);
        if ($status != $Lab::VISA::VI_SUCCESS) { die "Cannot open instrument $resource_name. status: $status";}
        $self->{instr}=$instrument;
        
#       $status=Lab::VISA::viClear($self->{instr});
#       if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
        
        $status=Lab::VISA::viSetAttribute($self->{instr}, $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
        if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting timeout value: $status";}
    
        return $self;
    }
    return 0;
}

sub Clear {
    my $self=shift;
    
    my $status=Lab::VISA::viClear($self->{instr});
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while clearing instrument: $status";}
}

sub Write {
    my $self=shift;
    my $cmd=shift;
    my ($status, $write_cnt)=Lab::VISA::viWrite(
        $self->{instr},
        $cmd,
        length($cmd)
    );
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while writing: $status";}
    return $write_cnt;
}

sub Query {
    # contains a nice bomb: read_cnt is arbitrarly set to 300 bytes
    my $self=shift;
    my $cmd=shift;
    my ($status, $write_cnt)=Lab::VISA::viWrite(
        $self->{instr},
        $cmd,
        length($cmd)
    );
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while writing: $status";}
    
    ($status,my $result,my $read_cnt)=Lab::VISA::viRead($self->{instr},300);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while reading: $status";}
    return substr($result,0,$read_cnt);
}

sub Read {
    my $self=shift;
    my $length=shift;

    my ($status,$result,$read_cnt)=Lab::VISA::viRead($self->{instr},$length);
    if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while reading: $status";}
    return substr($result,0,$read_cnt);
}

sub Handle {
    my $self=shift;
    return $self->{instr};
}

sub DESTROY {
    my $self=shift;
    my $status=Lab::VISA::viClose($self->{instr});
    $status=Lab::VISA::viClose($self->{default_rm});
}

1;

=head1 NAME

Lab::Instrument - General VISA based instrument

=head1 SYNOPSIS

 use Lab::Instrument;
 
 my $hp22 =  new Lab::Instrument(0,22); # gpib board 0, address 22
 print $hp22->Query('*IDN?');

=head1 DESCRIPTION

C<Lab::Instrument> offers an abstract interface to an instrument, that is connected via
GPIB, serial bus or ethernet. It provides general C<Read>, C<Write> and C<Query> methods,
and more.

It can be used either directly by the laborant (programmer) to work with
an instrument that doesn't have its own perl class
(like L<Lab::Instrument::HP34401A|Lab::Instrument::HP34401A>). Or it can be used by such a specialized
perl instrument class (like C<Lab::Instrument::HP34401A>), to delegate the
actual visa work. (All the instruments in the default package do so.)

=head1 CONSTRUCTOR

=head2 new

 $instrument=new Lab::Instrument($board,$addr);
 $instrument2=new Lab::Instrument({GPIB_board => $board, GPIB_address => $addr});

Creates a new instrument object and open the instrument with GPIB address C<$addr>
connected to the GPIB board C<$board> (usually 0). All instrument classes that
internally use the C<Lab::Instrument> module (that's all instruments in the default
distribution) can use both forms of the constructor.

=head1 METHODS

=head2 Write

 $write_count=$instrument->Write($command);
 
Sends the command C<$command> to the instrument.

=head2 Read

 $result=$instrument->Read($length);

Reads a result of maximum length C<$length> from the instrument and returns it.

=head2 Query

 $result=$instrument->Query($command);

Sends the command C<$command> to the instrument and reads a result from the
instrument and returns it. The length of the read buffer is haphazardly
set to 300 bytes. This can be changed in the source code, hehe. Or you use
seperate C<Write> and C<Read> commands.

=head2 Clear

 $instrument->Clear();

Sends a clear command to the instrument.

=head2 Handle

 $instr_handle=$instrument->Handle();

Returns the VISA handle. You can use this handle with the L<Lab::VISA> module.

=head1 CAVEATS/BUGS

Probably many.

=head1 SEE ALSO

=over 4

=item L<Lab::VISA>

=item L<Lab::Instrument::HP34401A>

=item L<Lab::Instrument::HP34970A>

=item L<Lab::Instrument::Source>

=item L<Lab::Instrument::KnickS252>

=item L<Lab::Instrument::Yokogawa7651>

=item L<Lab::Instrument::SR780>

=item L<Lab::Instrument::IPS120_10>

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Instrument.pm 475 2006-08-10 22:06:46Z schroeer $

Copyright 2004-2006 Daniel Schr�er (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
