#$Id: TMRC2.pm 613 2010-04-14 20:40:41Z schroeer $

package Lab::Instrument::TMRC2;
use strict;
use Lab::Instrument;
use Lab::Instrument::TemperatureControl;

our $VERSION = sprintf("0.%04d", q$Revision: 613 $ =~ / (\d+) /);

our @ISA=('Lab::Instrument::TemperatureControl');

my $default_config={
    min_temp                => 0.025,
    max_temp                => 1,
    temp_tolerance          => 5,
	control_file            => "buffin.txt",
	result_file             => "buffout.txt",
	control_path            => "C:\\Program Files\\Trmc2\\",
};

sub new {
    my $proto = shift;
    my @args=@_;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($default_config,@args);
    bless ($self, $class);

    $self->{vi}=new Lab::Instrument(@args);
    
    return $self
}

sub _write_command {

	my $command=shift;
	my $filename=$self->{config}->{control_path}.$self->{config}->{control_file};
	
	open BUFFIN, ">$filename";
	print BUFFIN "$command\n";
	close BUFFIN;

};

sub _read_command_reply {

	my $filename=$self->{config}->{control_path}.$self->{config}->{result_file};

	open BUFFOUT, "<$filename";
	my @text=<BUFFOUT>;
	close BUFFOUT;
	
	return @text;
};

sub _set_temp {
    my $self=shift;
    my $temp=shift;

	# somethign missing here
}


sub _get_temp {
    my $self=shift;
	
	# something missing here
}



sub initialize {
    my $self=shift;
    $self->{vi}->Write('RC');
}


1;

=head1 NAME

Lab::Instrument::Yokogawa7651 - Yokogawa 7651 DC source

=head1 SYNOPSIS

    use Lab::Instrument::Yokogawa7651;
    
    my $gate14=new Lab::Instrument::Yokogawa7651(0,11);
    $gate14->set_range(5);
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::Yokogawa7651 class implements an interface to the
7651 voltage and current source by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new($gpib_board,$gpib_addr)

=head1 METHODS

=head2 set_voltage($voltage)

=head2 get_voltage()

=head2 set_range($range)

    Fixed voltage mode
        2   10mV
        3   100mV
        4   1V
        5   10V
        6   30V

    Fixed current mode
        4   1mA
        5   10mA
        6   100mA

=head2 get_info()

Returns the information provided by the instrument's 'OS' command.

=head2 output_on()

Sets the output switch to on.

=head2 output_off()

Sets the output switch to off. The instrument outputs no voltage
or current then, no matter what voltage you set.

=head2 get_output()

Returns the status of the output switch (0 or 1).

=head2 initialize()

=head2 set_voltage_limit($limit)

=head2 set_current_limit($limit)

=head2 get_status()

Returns a hash with the following keys:

    CAL_switch
    memory_card
    calibration_mode
    output
    unstable
    error
    execution
    setting
    
The value for each key is either 0 or 1, indicating the status of the instrument.

=begin html

=head1 INSTRUMENT SPECIFICATIONS

=head2 DC voltage

The stability (24h) is the value at 23 � 1�C. The stability (90days),
accuracy (90days) and accuracy (1year) are values at 23 � 5�C.
The temperature coefficient is the value at 5 to 18�C and 28 to 40�C.

 Range  Maximum     Resolution  Stability 24h   Stability 90d   
        Output                  �(% of setting  �(% of setting  
                                +�V)            +�V)            
 ------------------------------------------------------------- 
 10mV   �12.0000mV  100nV       0.002 + 3       0.014 + 4       
 100mV  �120.000mV  1�V         0.003 + 3       0.014 + 5       
 1V     �1.20000V   10�V        0.001 + 10      0.008 + 50      
 10V    �12.0000V   100�V       0.001 + 20      0.008 + 100     
 30V    �32.000V    1mV         0.001 + 50      0.008 + 200     



 Range  Accuracy 90d    Accuracy 1yr    Temperature
        �(% of setting  �(% of setting  Coefficient
        +�V)            +�V)            �(% of setting
                                        +�V)/�C
 -----------------------------------------------------
 10mV   0.018 + 4       0.025 + 5       0.0018 + 0.7
 100mV  0.018 + 10      0.025 + 10      0.0018 + 0.7
 1V     0.01 + 100      0.016 + 120     0.0009 + 7
 10V    0.01 + 200      0.016 + 240     0.0008 + 10
 30V    0.01 + 500      0.016 + 600     0.0008 + 30
 

 
 Range   Maximum Output                   Output Noise
         Output  Resistance          DC to 10Hz  DC to 10kHz
                                                 (typical data)
 ----------------------------------------------------------
 10mV    -       approx. 2Ohm        3�Vp-p      30�Vp-p
 100mV   -       approx. 2Ohm        5�Vp-p      30�Vp-p
 1V      �120mA  less than 2mOhm     15�Vp-p     60�Vp-p
 10V     �120mA  less than 2mOhm     50�Vp-p     100�Vp-p
 30V     �120mA  less than 2mOhm     150�Vp-p    200�Vp-p


Common mode rejection:
120dB or more (DC, 50/60Hz). (However, it is 100dB or more in the
30V range.)

=head2 DC current

 Range   Maximum     Resolution  Stability (24 h)    Stability (90 days) 
         Output                  �(% of setting      �(% of setting      
                                 + �A)               + �A)               
 -----------------------------------------------------------------------
 1mA     �1.20000mA  10nA        0.0015 + 0.03       0.016 + 0.1         
 10mA    �12.0000mA  100nA       0.0015 + 0.3        0.016 + 0.5         
 100mA   �120.000mA  1�A         0.004  + 3          0.016 + 5           



 Range   Accuracy (90 days)  Accuracy (1 year)   Temperature  
         �(% of setting      �(% of setting      Coefficient     
         + �A)               + �A)               �(% of setting  
                                                 + �A)/�C        
 -----   ------------------------------------------------------  
 1mA     0.02 + 0.1          0.03 + 0.1          0.0015 + 0.01   
 10mA    0.02 + 0.5          0.03 + 0.5          0.0015 + 0.1    
 100mA   0.02 + 5            0.03 + 5            0.002  + 1



 Range  Maximum     Output                   Output Noise
        Output      Resistance          DC to 10Hz  DC to 10kHz
                                                    (typical data)
 -----------------------------------------------------------------
 1mA    �30 V       more than 100MOhm   0.02�Ap-p   0.1�Ap-p
 10mA   �30 V       more than 100MOhm   0.2�Ap-p    0.3�Ap-p
 100mA  �30 V       more than 10MOhm    2�Ap-p      3�Ap-p

Common mode rejection: 100nA/V or more (DC, 50/60Hz).

=end html

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item Lab::VISA

The Yokogawa7651 class uses the Lab::VISA module (L<Lab::VISA>).

=item Lab::Instrument

The Yokogawa7651 class is a Lab::Instrument (L<Lab::Instrument>).

=item SafeSource

The Yokogawa7651 class is a SafeSource (L<SafeSource>)

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: TMRC2.pm 613 2010-04-14 20:40:41Z schroeer $

Copyright 2004 Daniel Schr�er (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
