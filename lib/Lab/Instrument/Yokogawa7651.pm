#$Id: Yokogawa7651.pm 613 2010-04-14 20:40:41Z schroeer $

package Lab::Instrument::Yokogawa7651;
use strict;
use Switch;
use Lab::Instrument;
use Lab::Instrument::Source;

our $VERSION = sprintf("0.%04d", q$Revision: 613 $ =~ / (\d+) /);

our @ISA=('Lab::Instrument::Source');

our $MAX_SWEEP_TIME=3600;
our $MIN_SWEEP_TIME=0.1;

my $default_config={
    gate_protect            => 1,
    gp_equal_level          => 1e-5,
    gp_max_volt_per_second  => 0.002,
    gp_max_volt_per_step    => 0.001,
    gp_max_step_per_second  => 2,
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

sub _set_voltage {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set_voltage_auto {
    my $self=shift;
    my $voltage=shift;
    $self->_set_auto($voltage);
}

sub set_current {
    my $self=shift;
    my $voltage=shift;
    $self->_set($voltage);
}

sub _set {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%e",$value);
    $self->{vi}->Write($cmd);
    $cmd="E";
    $self->{vi}->Write($cmd);
}

sub _set_auto {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("SA%e",$value);
    $self->{vi}->Write($cmd);
    $cmd="E";
    $self->{vi}->Write($cmd);
}

sub set_setpoint {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("S%+.4e",$value);
    $self->{vi}->Write($cmd);
}

sub set_time {
    my $self=shift;
    my $sweep_time=shift; #sec.
    my $interval_time=shift;
    if ($sweep_time<$MIN_SWEEP_TIME) {
        warn "Warning Sweep Time: $sweep_time smaller than $MIN_SWEEP_TIME sec!\n Sweep time set to $MIN_SWEEP_TIME sec";
        $sweep_time=$MIN_SWEEP_TIME}
    elsif ($sweep_time>$MAX_SWEEP_TIME) {
        warn "Warning Sweep Time: $sweep_time> $MAX_SWEEP_TIME sec!\n Sweep time set to $MAX_SWEEP_TIME sec";
        $sweep_time=$MAX_SWEEP_TIME
    };
    if ($interval_time<$MIN_SWEEP_TIME) {
        warn "Warning Interval Time: $interval_time smaller than $MIN_SWEEP_TIME sec!\n Interval time set to $MIN_SWEEP_TIME sec";
        $interval_time=$MIN_SWEEP_TIME}
    elsif ($interval_time>$MAX_SWEEP_TIME) {
        warn "Warning Interval Time: $interval_time> $MAX_SWEEP_TIME sec!\n Interval time set to $MAX_SWEEP_TIME sec";
        $interval_time=$MAX_SWEEP_TIME
    };
    my $cmd=sprintf("PI%.1f",$interval_time);
    $self->{vi}->Write($cmd);
    $cmd=sprintf("SW%.1f",$sweep_time);
    $self->{vi}->Write($cmd);
}

sub start_program {
    my $self=shift;
    my $cmd=sprintf("PRS");
    $self->{vi}->Write($cmd);
}

sub end_program {
    my $self=shift;
    my $cmd=sprintf("PRE");
    $self->{vi}->Write($cmd);
}
sub execute_program {
    # 0 HALT
    # 1 STEP
    # 2 RUN
    #3 Continue
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("RU%d",$value);
    $self->{vi}->Write($cmd);
    
}

sub sweep {
    my $self=shift;
    my $stop=shift;
    my $rate=shift;
    my $return_rate=$rate;
    $self->execute_program(0);
    my $output_now=$self->_get();
    #Test if $stop in range
    my $range=$self->get_range();
    #Start Programming-----
    $self->start_program();
    if ($stop>$range){
        $stop=$range;
    }
    elsif ($stop< -$range) {
        $stop=-$range;
    }
    $self->set_setpoint($stop);
    $self->end_program();

    my $time=abs($output_now -$stop)/$rate;
    if ($time<$MIN_SWEEP_TIME) {
        warn "Warning Sweep Time: $time smaller than $MIN_SWEEP_TIME sec!\n Sweep time set to $MIN_SWEEP_TIME sec";
        $time=$MIN_SWEEP_TIME;
        $return_rate=abs($output_now -$stop)/$time;
    }
    elsif ($time>$MAX_SWEEP_TIME) {
        warn "Warning Interval Time: $time> $MAX_SWEEP_TIME sec!\n Sweep time set to $MAX_SWEEP_TIME sec";
        $time=$MAX_SWEEP_TIME;
        $return_rate=abs($output_now -$stop)/$time;
    }
    $self->set_time($time,$time);
    $self->execute_program(2);
    return $return_rate;
}

sub _get_voltage {
    my $self=shift;
    return $self->_get();
}

sub get_current {
    my $self=shift;
    return $self->_get();
}

sub _get {
    my $self=shift;
    my $cmd="OD";
    my $result=$self->{vi}->Query($cmd);
    $result=~/....([\+\-\d\.E]*)/;
    return $1;
}

sub set_current_mode {
    my $self=shift;
    my $cmd="F5";
    $self->{vi}->Write($cmd);
}

sub set_voltage_mode {
    my $self=shift;
    my $cmd="F1";
    $self->{vi}->Write($cmd);
}

sub set_range {
    my $self=shift;
    my $range=shift;
    my $cmd="R$range";
      #fixed voltage mode
      # 2   10mV
      # 3   100mV
      # 4   1V
      # 5   10V
      # 6   30V
      #fixed current mode
      # 4   1mA
      # 5   10mA
      # 6   100mA
    $self->{vi}->Write($cmd);
}

sub get_info {
    my $self=shift;
    my $result=$self->{vi}->Query("OS");
    return $result;
}

sub get_OS {
    my $self=shift;
    $self->{vi}->Write("OS");
    my @info;
    for (my $i=0;$i<=10;$i++){
        my $line=$self->{vi}->BrutalRead(300);
        if ($line=~/END/){last};
        chomp $line;
        $line=~s/\r//;
        push(@info,sprintf($line));
    };
    return @info;
}

sub get_range{
    my $self=shift;
    my @info=$self->get_OS();
    my $result=$info[1];
    my $func_nr=0;
    my $range_nr=0;
    my $range=0;
    #printf "$result\n";
    if ($result=~/F(\d)R(\d)/){
    $func_nr=$1;
    #printf "funcnr=$func_nr\n";
    $range_nr=$2;
    #    printf "rangenr=$range_nr\n";
    }
    if ($func_nr==1){ # DC V
        switch ($range_nr) {
            case 2 {$range=10e-3} #10mV
            case 3 {$range=100e-3} #100mV
            case 4 {$range=1} #1V
            case 5 {$range=10} #10V
            case 6 {$range=30} #30V
            else {die "Range $range_nr not defined\n"}
        }
    }
    elsif ($func_nr==5){
        switch ($range_nr) {
            case 4 {$range=1e-3} #1mA
            case 5 {$range=10e-3} #10mA
            case 6 {$range=100e-3} #100mA
            else {die "Range $range_nr not defined\n"}
        }
    }
    else {die "Function not defined"}
    #printf "$range\n";
    return $range
    
}

sub set_run_mode {
    my $self=shift;
    my $value=shift;
    if ($value!=0 and $value!=1) {die "Run Mode $value not defined"}
    my $cmd=sprintf("M%u",$value);
    $self->{vi}->Write($cmd);
}

sub output_on {
    my $self=shift;
    $self->{vi}->Write('O1');
    $self->{vi}->Write('E');
}
    
sub output_off {
    my $self=shift;
    $self->{vi}->Write('O0');
    $self->{vi}->Write('E');
}

sub get_output {
    my $self=shift;
    my %res=$self->get_status();
    return $res{output};
}

sub initialize {
    my $self=shift;
    $self->{vi}->Write('RC');
}

sub set_voltage_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LV%e",$value);
    $self->{vi}->Write($cmd);
}

sub set_current_limit {
    my $self=shift;
    my $value=shift;
    my $cmd=sprintf("LA%e",$value);
    $self->{vi}->Write($cmd);
}

sub get_status {
    my $self=shift;
    my $status=$self->{vi}->Query('OC');
    
    $status=~/STS1=(\d*)/;
    $status=$1;
    my @flags=qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    error   execution   setting/;
    my %result;
    for (0..7) {
        $result{$flags[$_]}=$status&128;
        $status<<=1;
    }
    return %result;
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

=head1 INSTRUMENT SPECIFICATIONS

=head2 DC voltage

The stability (24h) is the value at 23 +- 1�C. The stability (90days),
accuracy (90days) and accuracy (1year) are values at 23 +- 5�C.
The temperature coefficient is the value at 5 to 18�C and 28 to 40�C.


 Range  Maximum     Resolution  Stability 24h   Stability 90d   
        Output                  +-(% of setting +-(% of setting  
                                +muV)           +muV)            
 ------------------------------------------------------------- 
 10mV   +-12.0000mV 100nV       0.002 + 3       0.014 + 4       
 100mV  +-120.000mV 1muV        0.003 + 3       0.014 + 5       
 1V     +-1.20000V  10muV       0.001 + 10      0.008 + 50      
 10V    +-12.0000V  100muV      0.001 + 20      0.008 + 100     
 30V    +-32.000V   1mV         0.001 + 50      0.008 + 200     



 Range  Accuracy 90d    Accuracy 1yr    Temperature
        +-(% of setting +-(% of setting Coefficient
        +muV)           +muV)           +-(% of setting
                                        +muV)/�C
 -----------------------------------------------------
 10mV   0.018 + 4       0.025 + 5       0.0018 + 0.7
 100mV  0.018 + 10      0.025 + 10      0.0018 + 0.7
 1V     0.01 + 100      0.016 + 120     0.0009 + 7
 10V    0.01 + 200      0.016 + 240     0.0008 + 10
 30V    0.01 + 500      0.016 + 600     0.0008 + 30



 Range   Maximum Output              Output Noise
         Output  Resistance          DC to 10Hz  DC to 10kHz
                                     (typical data)
 ----------------------------------------------------------
 10mV    -       approx. 2Ohm        3muVp-p      30muVp-p
 100mV   -       approx. 2Ohm        5muVp-p      30muVp-p
 1V      +-120mA less than 2mOhm     15muVp-p     60muVp-p
 10V     +-120mA less than 2mOhm     50muVp-p     100muVp-p
 30V     +-120mA less than 2mOhm     150muVp-p    200muVp-p


Common mode rejection:
120dB or more (DC, 50/60Hz). (However, it is 100dB or more in the
30V range.)

=head2 DC current

 Range   Maximum     Resolution  Stability (24 h)    Stability (90 days) 
         Output                  +-(% of setting     +-(% of setting      
                                 + muA)              + muA)               
 -----------------------------------------------------------------------
 1mA     +-1.20000mA 10nA        0.0015 + 0.03       0.016 + 0.1         
 10mA    +-12.0000mA 100nA       0.0015 + 0.3        0.016 + 0.5         
 100mA   +-120.000mA 1muA        0.004  + 3          0.016 + 5           


 Range   Accuracy (90 days)  Accuracy (1 year)   Temperature  
         +-(% of setting     +-(% of setting     Coefficient     
         + muA)              + muA)              +-(% of setting  
                                                 + muA)/�C        
 -----   ------------------------------------------------------  
 1mA     0.02 + 0.1          0.03 + 0.1          0.0015 + 0.01   
 10mA    0.02 + 0.5          0.03 + 0.5          0.0015 + 0.1    
 100mA   0.02 + 5            0.03 + 5            0.002  + 1


 Range  Maximum     Output                   Output Noise
        Output      Resistance          DC to 10Hz  DC to 10kHz
                                                    (typical data)
 -----------------------------------------------------------------
 1mA    +-30 V      more than 100MOhm   0.02muAp-p  0.1muAp-p
 10mA   +-30 V      more than 100MOhm   0.2muAp-p   0.3muAp-p
 100mA  +-30 V      more than 10MOhm    2muAp-p     3muAp-p

Common mode rejection: 100nA/V or more (DC, 50/60Hz).

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item Lab::VISA

The Yokogawa7651 class uses the Lab::VISA module (L<Lab::VISA>).

=item Lab::Instrument

The Yokogawa7651 class is a Lab::Instrument (L<Lab::Instrument>).

=item Lab::Instrument::Source

The Yokogawa7651 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: Yokogawa7651.pm 613 2010-04-14 20:40:41Z schroeer $

 (c) 2004-2006 Daniel Schr�er
 (c) 2007-2010 Daniel Schr�er, Daniela Taubert, Andreas H�ttel, and others

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
