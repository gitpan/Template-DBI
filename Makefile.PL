#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use warnings;

use lib qw( ./lib ../lib );
use Config;
use File::Spec::Functions qw( catfile );
use Template;
use ExtUtils::MakeMaker;
use Cwd;

select STDERR;
$| = 1;
select STDOUT;

our $CONFIG_DIR  = -d 't' ? 't' : '.';
our $CONFIG_FILE = 'dbi_test.cfg';
our $CONFIG_PATH = catfile($CONFIG_DIR, $CONFIG_FILE);
our $RUN_TESTS   = 'n';
our $TT_QUIET    = 0;
our $TT_ACCEPT   = 0;

dbi_config();

my %opts = (
    'NAME'	       => 'Template-DBI',
    'VERSION_FROM' => 'lib/Template/Plugin/DBI.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 
        'Template'    => 2.15,
        'DBI'         => 1.00,
    },
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
    'clean'        => {
        'FILES'        => 't/dbi_test.cfg',
    },
);


if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>';
    $opts{ ABSTRACT } = 'DBI plugin for the Template Toolkit',
}


WriteMakefile( %opts );


#------------------------------------------------------------------------
# dbi_config()
#
# Quiz the user for options related to running the DBI tests.
#------------------------------------------------------------------------

sub dbi_config {
    my ($dsn, $user, $pass) = ('') x 3;

    if (ttprompt("Do you want to run the DBI tests?\n" .
	       "It requires access to an existing test database.",
	       $RUN_TESTS) =~ /y/i) {

        $RUN_TESTS = 1;
        my ($driver, $dbname);
        require DBI;
        my @drivers = DBI->available_drivers();
        local $" = ', ';
        
        my $default = (grep(/m.?sql/i, @drivers))[0] 
            || $drivers[0] || '';
        
        message(<<EOF);

DBI Test Configuration
----------------------

Please enter the driver name for the test database.
The DBD drivers installed on your system are

    @drivers

EOF

        while (! $driver) {
            $driver = ttprompt("Enter driver name: ", $default);
            message("! No such DBD driver\n"), undef $driver
                unless grep(/^$driver$/, @drivers);
        }
        
        message(<<EOF);

Now enter the data source (DSN) for the test database.
Many DBD drivers require only a database name (e.g. 'test') while
others may require an alternate format or additional parameters
(e.g. 'dbname=test').  Please consult your DBD documentation for
further details.

EOF

    	my $dbname_eg = $driver eq 'Pg' ? 'dbname=test' : 'test';
        while (! $dbname) {
            $dbname = ttprompt('Database name: ', $dbname_eg);
        }
    
        $dsn = "dbi:$driver:$dbname";
    	$user = ttprompt('Enter user name : ', '');
    	$pass = ttprompt('Enter password  : ', '');
    	$user = '' unless defined $user;
        $pass = '' unless defined $pass;
    }
    else {
        $RUN_TESTS = 0;
    }

    message("\nwriting $CONFIG_PATH\n");
    open(CFGFILE, ">$CONFIG_PATH") || die "$CONFIG_PATH: $!\n";
    print CFGFILE <<EOF;
\$run  = $RUN_TESTS;
\$dsn  = '$dsn';
\$user = '$user';
\$pass = '$pass';
1;
EOF
    close(CFGFILE);
}





#------------------------------------------------------------------------
# message($text)
#
# Print message unless quiet mode.
#------------------------------------------------------------------------

sub message {
    return if $TT_QUIET;
    print @_;
}


#------------------------------------------------------------------------
# ttprompt($message, $default)
#------------------------------------------------------------------------

sub ttprompt {
    my ($msg, $def)=@_;
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ; # Pipe?
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans = '';
    local $|=1;
    print "$msg $dispdef" unless $TT_QUIET;
    if ($TT_ACCEPT || ! $ISA_TTY) {
        print "$def\n" unless $TT_QUIET;
    }
    else {
        chomp($ans = <STDIN>);
    }
    return ($ans ne '') ? $ans : $def;
}


#------------------------------------------------------------------------
# yep($text)
#------------------------------------------------------------------------

sub yep {
    return if $TT_QUIET;
    print '[X] ', shift, "\n";
}


#------------------------------------------------------------------------
# nope($text)
#------------------------------------------------------------------------
sub nope {
    return if $TT_QUIET;
    print '[ ] ', shift, "\n";
}
