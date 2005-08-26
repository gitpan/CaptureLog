use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Log::SimpleLog::CaptureLog',
    'VERSION_FROM'  => 'lib/Log/SimpleLog/CaptureLog.pm', # finds $VERSION
    'PREREQ_PM'     => {}, # e.g., Module::Name => 1.1
    'ABSTRACT'      => 'CaptureLog - A very simple Perl logging class wrapper for capturing STDERR and STDOUT.  Will allow for a very simplistic method of logging messages throughout any Perl application',
    'AUTHOR'        => 'Trevor Hall',
);
