package Log::SimpleLog::CaptureLog;
use warnings;
use strict;
use IO::Capture::Stdout;
use IO::Capture::Stderr;
use POSIX qw(strftime);
our @ISA = qw(Log::SimpleLog);

use vars qw($VERSION);
$VERSION = '0.07';

sub new {
    my ( $class , $core_filepath , $ex_filepath , $exc_filepath ) = @_;
    my ( $std_err , $std_out );
    my @log_buffer = ( );
    
      # The first step is to generate the physical requested
      # object for the source of the call
    my $this = { };
    bless ( $this , $class );

      # Next, we will have to grab the streams to 
      # the STDOUT and STDERR in order to properly 
      # log the data
    $std_err = new IO::Capture::Stderr;
    $std_out = new IO::Capture::Stdout;
    $std_err->start ( );
    $std_out->start ( );
    
      # Encapsulate the pipe wrapper objects
    $this->{'_stdout'} = $std_out;
    $this->{'_stderr'} = $std_err;
    $this->{'_stdlog'} = \@log_buffer;
    $this->{'_buffer_limit'} = 1024;  # The default line limit for the log buffer
    

      # Prepare the internal object with the
      # proper log path locations
    $this->set_core_filepath ( $core_filepath ) if ( defined ( $core_filepath ) );
    $this->set_exfilepath ( $ex_filepath ) if ( defined ( $ex_filepath ) );
    $this->set_excfilepath ( $exc_filepath ) if ( defined ( $exc_filepath ) );
    
      # Return the instantiated object
    return $this;
}

sub open_stdout {
    my ( $this ) = @_;
    $this->{'_stdout'}->stop ( ) if ( defined ( $this->{'_stderr'} ) );
}

sub open_stderr {
    my ( $this ) = @_;
    $this->{'_stderr'}->stop ( ) if ( defined ( $this->{'_stderr'} ) );
}

sub set_core_filepath {
    my ( $this , $filepath ) = @_;
    $this->{'_core_path'} = $filepath;
}

sub set_exfilepath {
    my ( $this , $filepath ) = @_;
    $this->{'_ex_path'} = $filepath;
}

sub set_excfilepath {
    my ( $this , $filepath ) = @_;
    $this->{'_exc_path'} = $filepath;
}

sub get_buffer_limit {
    my ( $this ) = @_;
    return $this->{'_buffer_limit'};
}

sub set_buffer_limit {
    my ( $this , $buffer_limit ) = @_;
    $this->{'_buffer_limit'} = int ( $buffer_limit );
}

sub log_message {
    my ( $this , $log_message ) = @_;
    my ( $local_time );
    
      # First, we will judge the input parameters to 
      # determine if they are properly formatted
    return if ( ! defined ( $log_message ) );

      # Next, we can begin formatting the string 
      # to be inserted into the log file
    chomp ( $log_message );
    $local_time = $this->_get_current_time ( );
    $log_message = "[$local_time] MESSAGE: $log_message\n";
    push ( @{$this->{'_stdlog'}} , $log_message );

      # We will then determine if it is time to flush
      # the log.  If so, we will do so
    $this->_flush_log_buffer ( ) if ( scalar ( @{$this->{'_stdlog'}} ) >= $this->get_buffer_limit ( ) );
}

sub _flush_log_buffer {
    my ( $this ) = @_;
    my ( $std_log , $std_err , $std_out , $local_time );
    my ( @stdout , @stderr , @stdlog );
    
      # First step will be to prepare the objects
      # that will then be flushed to the appropriate
      # log files, after stopping the appropriate 
      # piped stream
    $local_time = $this->_get_current_time ( );
    $std_log = join ( '' , @{$this->{'_stdlog'}} );
    @stdlog = ( );
    $this->{'_stdlog'} = \@stdlog;
    
      # Prepare the STDERR
    $this->{'_stderr'}->stop ( );
    @stderr = $this->{'_stderr'}->read ( );
    map { $_ = "[$local_time] STDERR: $_\n" } @stderr;
    $std_err = join ( '' , @stderr );
    $this->{'_stderr'}->start ( );

      # Prepare the STDOUT
    $this->{'_stdout'}->stop ( );
    @stdout = $this->{'_stdout'}->read ( );
    map { $_ = "[$local_time] STDOUT: $_\n" } @stdout;
    $std_out = join ( '' , @stdout );
    $this->{'_stdout'}->start ( );

      # Determine the locations of the log files
      # and print the appropriate output to the 
      # files
    open CORE_FILE , ">>$this->{'_core_path'}";
    print CORE_FILE $std_log;
    print CORE_FILE $std_err if ( ! $this->{'_ex_path'} && ! $this->{'_exc_path' } );
    print CORE_FILE $std_out if ( ! $this->{'_ex_path'} && ! $this->{'_exc_path' } );
    close CORE_FILE;

      # Do the same for the ex_filepath
    if ( $this->{'_ex_path'} ) {
        open EX_PATH , ">>$this->{'_ex_path'}";
        print EX_PATH $std_out;
        print EX_PATH $std_err if ( ! $this->{'_exc_path'} );
        close EX_PATH;
    }

      # Then the same for the exc_filepath
    if ( $this->{'_exc_path'} ) {
        open EXC_PATH , ">>$this->{'_exc_path'}";
        print EXC_PATH $std_err;
        print EXC_PATH $std_out if ( ! $this->{'_ex_path'} );
        close EXC_PATH;
    }
}

sub _get_current_time {
    my ( $this ) = @_;
    return strftime ( "\%Y\%m\%d\%H\%M\%S" , localtime ( ) );
}

sub DESTROY {
    my ( $this ) = @_;
    $this->_flush_log_buffer ( );
    $this->{'_stdout'}->stop ( );
    $this->{'_stderr'}->stop ( );
}
1;

__END__

=head1 NAME

Log::SimpleLog::CaptureLog

=head1 SYNOPSYS

    my $l = new Log::SimpleLog::CaptureLog ( 
                $standard_log , 
                $std_out_log , # Optional
                $std_err_log , # Optional 
            );

    $l->log_message ( 'Standard log output' );
    print STDOUT 'STDOUT log output';
    print STDERR 'STDERR log output';

=head1 DESCRIPTION

This Perl module class is intended to be a very simple and 
light-weight logging device with the intent of capturing 
all the standard out and error messages that are thrown 
either by an application or by the Perl interpreter its
self.

There are methods listed in the documentation that will
allow for the changing of any of these rules.  For instance,
if standard logging with STDERR logging is to be captured,
but STDOUT should not, there are methods provided to do 
so.

=head1 CONSTRUCTOR

The constructor is passed a minimum of one and a maximum of 
three of the following arguments, which will provide the 
object with the location of the log file of which to pipe
specific output to.

The following parameters are intended for use:

=over 4

=item core_filepath

The core file path for the custom log messages.

Refer to the set_corefilepath method description

=item ex_filepath

This parameter is optional.

The location of the STDOUT file path.

Refer to the set_exfilepath method description.

=item exc_filepath

This parameter is optional.

The location of the STDERR file path.

Refer to the set_excfilepath method description.

=head1 METHODS

=head1 log_message

The standard input for log entries.

By default, the input message will be formatted into
the specified format within the parameters of the 
object.  

The output of this data will be to the location of 
the core_filepath location

head1 set_buffer_limit

The log it's self will be stored into memory until the 
'buffer limit' has been breached.  The default buffer
limit is 1024, which implies that there will have to
be 1024 log lines until the buffer is flushed to the 
output file.

This method will allow you to adjust this buffer limit
in order to utilize less memory than the default setting.

Upon destruction of the object, the log will be flushed, 
no matter the size of the buffer at the time when the 
object is removed from the heap.

=head1 get_buffer_limit

Will return the current buffer limit as set by the
set_buffer_limit method, or by the 
instantiation/construction of the object (1024)

=head1 set_core_filepath

Will set the location of the file of which the custom
log messages will be written to.

If no other arguments or set_*_filepath methods are called,
this file will also be the location of the STDOUT and
STDERR output unless otherwise directed.

=head1 set_exfilepath

Will set the location of the STDOUT file path.

By setting this option, the 'core filepath' will
only contain the custom log messages sent to the
logger.

If no other set_*_filepath method is called, then
both STDOUT and STDERR will be streamed to this 
log

=head1 set_excfilepath

Similar to the other two set_*_filepath methods,
this method, when used, will set the STDERR file 
location.

If no other set_*_filepath methods are called, then
both STDOUT and STDERR will be streamed to this log.

=head1 open_stdout

Will turn off the capturing of the STDOUT stream

=head1 open_stderr

Will turn off the capturing of the STDERR stream

=head1 AUTHOR

Trevor Hall <hallta@gmail.com>

=head1 DEPENDENCIES

Log::SimpleLog
IO::Capture::Stdout
IO::Capture::Stderr
POSIX

=head1 COPYRIGHT

Copyright (c) 2005 Trevor Hall. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.
