use strict;
use Test;

BEGIN { plan tests => 4 }
use Log::SimpleLog::CaptureLog;

my $test = new Log::SimpleLog::CaptureLog ( 'test' );
$test->set_buffer_limit ( 1 );

  # We must open the STDOUT stream because the 
  # Test module depends on capturing the stream
  # first
my $t = ( defined ( $test ) ) ? 1 : 0;

my @tests = ( 'test' , 'test2' );
map { $test->log_message ( $_ ); print STDERR $_; print STDOUT $_; } @tests;
$test->_flush_log_buffer();
$test = undef;
ok ( $t );

$t = ( -r 'test' ) ? 1 : 0;
ok ( $t );

my $ret = tester ( 'test' , @tests );
$t = ( defined ( $ret ) ) ? 1 : 0;
ok ( $t );
map { $t = $_; } @$ret;
ok ( $t );

unlink ( 'test' );

sub tester {
    my ( $file , @tests ) = @_;
    my @return = ( );
    
    open FILE , $file;
    while ( <FILE> ) {
        chomp;
        my $tez;
        my $line = $_;
        map { 
            my $reg = qr/$_/; 
            $tez = ( $line =~ /$reg/ ) ? 1 : ( defined ( $tez ) ) ? $tez : 0;
        } @tests;
        push ( @return , $tez );
    }
    close FILE;

    return \@return;
}
