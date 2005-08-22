package Log::SimpleLog::CaptureLog;
use warnings;
use strict;
use IO::Capture::Stdout;
use IO::Capture::Stderr;
use POSIX qw(strftime);
our @ISA = qw(Log::SimpleLog);

my $VERSION = '0.03';

=head1 new()

  Description:

    The core constructor for the IO::SimpleLog object.
    Will instantiate and return the log object, wrapped
    around the log files of the appropriate nature

  Input:

    $core_filepath: The directory location of the log file
                    which force inputs will be sent to.
                    
                    This is an optional parameter and can 
                    also be set through the set_filepath()
                    method.

                    By default, if this parameter is set
                    and any others are not, all 
                    STDERR and STDOUT output will also
                    be piped to this log location

    $ex_filepath:   An optional input that will direct the 
                    location of either the STDERR or STDOUT
                    log locations.

                    This is an optional parameter and can
                    also be set through the set_exfilepath()
                    method.

                    Given this parameter, while the exc_filepath
                    is empty, both STDERR and STDOUT output will
                    be piped to this log location and not the
                    core_filepath.  

    $exc_filepath   Much as the ex_filepath, will pipe the STDERR
                    output directly to this particular log location.

                    This is an optional parameter and can also be 
                    set through the set_excfilepath() method.

                    Given the existance of this, as well as the 
                    ex_filepath, all STDERR will be piped to this
                    directory while STDOUT will be piped to the
                    ex_filepath directory.

  Output:

    $this:          The instantiated log wrapper for the file
                    pipes

=cut                  
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

=head1 set_core_filepath()

  Description:

    Will set the core log file location to the 
    object.

  Input:
    
    $filepath:  The file path location of the log file

=cut
sub set_core_filepath {
    my ( $this , $filepath ) = @_;
    $this->{'_core_path'} = $filepath;
}

=head1 set_exfilepath()

  Description:

    Will set the log file location, relative to STDOUT 
    to the object.

    Without the existance of the excfilepath, STDERR 
    will also be written to this location.

  Input:
    
    $filepath:  The file path location of the log file

=cut
sub set_exfilepath {
    my ( $this , $filepath ) = @_;
    $this->{'_ex_path'} = $filepath;
}

=head1 set_excfilepath()

  Description:

    Will set the log file location, relative to STDERR
    to the object.

    Upon a buffer dump, will write STDERR and STDOUT 
    to this location without the existance of the
    exfilepath locale stored.
    
  Input:
    
    $filepath:  The file path location of the log file

=cut
sub set_excfilepath {
    my ( $this , $filepath ) = @_;
    $this->{'_exc_path'} = $filepath;
}

=head1 get_buffer_limit()

  Description:

    Will return the current buffer limit of the
    logging object

  Output:

    The current log buffer limit; an integer
    that represents the number of lines that will
    be stored in memory before dumping to a log file
    
=cut
sub get_buffer_limit {
    my ( $this ) = @_;
    return $this->{'_buffer_limit'};
}

=head1 set_buffer_limit()

  Description:

    Will set the new buffer limit to the log file

  Input:

    The new log buffer limit; an integer that
    represents the number of lines that will
    be stored in memory before dumping to a log
    file

=cut
sub set_buffer_limit {
    my ( $this , $buffer_limit ) = @_;
    $this->{'_buffer_limit'} = int ( $buffer_limit );
}

=head1 log_message()

  Description:

    The standard input for log entries.

    By default, the input message will be formatted into
    the specified format within the parameters of the 
    object.  

    The output of this data will be to the location of 
    the core_filepath location

  Input:

    $log_message:   A string formatted log message to 
                    be intended to write to the 
                    core_filepath location

=cut
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
}
1;

__END__
=head1 AUTHOR
    
    Name:   Trevor Hall 
    E-mail: hallta@gmail.com
    URL:    http://trevorhall.blucorral.com

=head1 NAME

=head1 DESCRIPTION

=cut
