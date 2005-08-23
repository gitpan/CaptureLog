package Log::SimpleLog;
use strict;
use warnings;
use POSIX qw(strftime);

$VERSION = '0.03';

=head1 new()
  
  Description:

    The core constructor for the logging object

  Input:

    $file_name: The absolute file path file source
                for the log file of which to be 
                written to.

=cut
sub new {
    my ( $class , $file_name ) = @_;
    my ( $log_handle );
    
      # Generate the hash of the object
    my $this = { };
    bless ( $this , $class );

      # Open the file handle to use for the log, add to the object
    my @log_mem = ( );
    $this->{'_log_data'} = \@log_mem;
    $this->{'_file_name'} = $file_name;

      # Return the object to the invoking object
    return $this;    
}

=head1 log_message()

  Description:

    Will use the passed string, append the current date and 
    write to the file

  Input:

    $log_string:  The un-formatted scalar value that will
                  be logged to the file defined through
                  the constructor.

                  Each line will have a date stamp of
                  the time of the log, as well as the 
                  message appended to the end of the 
                  log.

=cut
sub log_message {
    my ( $this , $log_string ) = @_;
    my ( $file_handle , $time_stamp );

      # Load the required objects into memory
    $file_handle = $this->{'_log_data'};
    $time_stamp = strftime ( "[%Y%m%d %H:%M:%S]", localtime ( time ) );

      # Dicate the message, append the data and log the value
    chomp $log_string;
    $log_string = "$time_stamp $log_string\n";
    push ( @$file_handle , $log_string );
}

sub _flush_log_buffer {
    my ( $this ) = @_;
    my $log_handle;
    
      # Locate the log hande and close the file
    my $arr = $this->{'_log_data'};    
    $|++;
    open FILE , ">>$this->{'_file_name'}";
    foreach my $line ( @$arr ) {
        print FILE $line;
    }
    close FILE;
}
1;

__END__

=head1 AUTHOR
    
    Name:   Trevor Hall 
    E-mail: hallta@gmail.com
    URL:    http://trevorhall.blucorral.com

=head1 NAME

    Log::SimpleLog

=head1 DESCRIPTION

    A simple log class that will allow for the
    general documentation of messages within 
    a external flat-file

=cut    
