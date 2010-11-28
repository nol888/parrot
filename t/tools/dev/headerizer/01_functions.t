#! perl
# Copyright (C) 2010, Parrot Foundation.
# $Id$
# 01_functions.t

use strict;
use warnings;
use Test::More tests => 38;
use Carp;
use Cwd;
use File::Copy;
use File::Temp qw( tempdir );
use lib qw( lib );
use Parrot::Config;
use Parrot::Headerizer::Functions qw(
    process_argv
    read_file
    write_file
    qualify_sourcefile
    asserts_from_args
);

use IO::CaptureOutput qw| capture |;

my $cwd = cwd();

my @ofiles;
eval {
    @ofiles = process_argv();
};
like($@, qr/No files specified/,
    "Got expected error message for no files specified");

@ofiles = qw( alpha.o beta.o gamma.o alpha.o );
{
    my ($stdout, $stderr);
    capture(
        sub { @ofiles = process_argv(@ofiles); },
        \$stdout,
        \$stderr,
    );
    is(@ofiles, 3, "Got expected number of ofiles");
    like( $stdout,
        qr/alpha\.o is specified more than once/s,
        "Got expected message for an argument supplied more than once"
    );
}

@ofiles = qw( alpha.o beta.o gamma.o );
is(@ofiles, 3, "Got expected number of ofiles");

{
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir;
    my $file = "filename$$";
    my @lines_to_write = (
        "Goodbye\n",
        "cruel\n",
        "world\n",
    );
    my $text = join( '' => @lines_to_write );
    write_file($file, $text);
    ok(-f $file, "File was written");

    my $text_returned = read_file($file);
    ok($text_returned, "Got non-empty string back from read_file()");
    my @lines_read = split /\n/, $text_returned;
    is($lines_read[0], 'Goodbye', "Got first line");
    is($lines_read[1], 'cruel', "Got second line");
    is($lines_read[2], 'world', "Got third line");
    chdir $cwd or die "Unable to chdir: $!";
}
    
my $filename = 'foobar';
eval {
    read_file($filename);
};
like($@, qr/couldn't read '$filename'/, "Got expected error message for read_file()");

my ($ofile, $is_yacc);
my ($sourcefile, $source_code, $hfile);
$ofile = 'foobar.xyz';
eval {
    my ($sourcefile, $source_code, $hfile) =
        qualify_sourcefile( {
            ofile           => $ofile,
            PConfig         => \%PConfig,
            is_yacc         => 0,
        } );
};
like($@, qr/$ofile doesn't look like an object file/,
    "Got expected die message for non-object, non-yacc file" );
    
# Testing Needs We don't really need a .o file, we just need its name.
# However, we do need one .c file and one .pmc file.  In order to have the
# codingstd tests skip these, we should name them .in and then copy them into
# position with the extensions we need.  We need one file where there is no
# HEADERIZER HFILE directive within the file.  We need a case where the
# HEADERIZER HFILE directive contains 'none'.  We need a case where the header
# file exists and one where it does not.

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'lack_directive';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.c" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.o";
    my $expected_cfile = "$tdir/$stub.c";
    eval {
        my ($sourcefile, $source_code, $hfile) =
            qualify_sourcefile( {
                ofile           => $ofile,
                PConfig         => \%PConfig,
                is_yacc         => 0,
            } );
    };
    like($@, qr/can't find HEADERIZER HFILE directive in "$expected_cfile"/,
        "Got expected die message for file lacking HEADERIZER HFILE directive" );
}

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'none';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.c" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.o";
    my $expected_cfile = "$tdir/$stub.c";
    my ($sourcefile, $source_code, $hfile) =
        qualify_sourcefile( {
            ofile           => $ofile,
            PConfig         => \%PConfig,
            is_yacc         => 0,
        } );
    is( $sourcefile, $expected_cfile, "Got expected C source file" );
    like( $source_code, qr/This file has 'none'/, 
        "Got expected source code" );
    is( $hfile, 'none', "As expected, no header file" );
}

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'missingheaderfile';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.c" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.o";
    my $expected_cfile = "$tdir/$stub.c";
    eval {
        my ($sourcefile, $source_code, $hfile) =
            qualify_sourcefile( {
                ofile           => $ofile,
                PConfig         => \%PConfig,
                is_yacc         => 0,
            } );
    };
    like($@, qr/"$stub" not found \(referenced from "$expected_cfile"\)/,
        "Got expected error message for missing header file" );
}

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'validheader';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.c" or croak "Unable to copy file for testing";
    copy "$cwd/t/tools/dev/headerizer/testlib/h$stub.in" =>
         "$tdir/$stub.h" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.o";
    my $expected_cfile = "$tdir/$stub.c";
    chdir $tdir;
    my ($sourcefile, $source_code, $hfile) =
        qualify_sourcefile( {
            ofile           => $ofile,
            PConfig         => \%PConfig,
            is_yacc         => 0,
        } );
    chdir $cwd;
    is( $sourcefile, $expected_cfile, "Got expected C source file" );
    like( $source_code, qr/This file has a valid HEADERIZER HFILE/, 
        "Got expected source code" );
    is( $hfile, "$stub.h", "Got expected header file" );
}

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'validheader';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.pmc" or croak "Unable to copy file for testing";
    copy "$cwd/t/tools/dev/headerizer/testlib/h$stub.in" =>
         "$tdir/$stub.h" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.o";
    my $expected_cfile = "$tdir/$stub.pmc";
    chdir $tdir;
    my ($sourcefile, $source_code, $hfile) =
        qualify_sourcefile( {
            ofile           => $ofile,
            PConfig         => \%PConfig,
            is_yacc         => 0,
        } );
    chdir $cwd;
    is( $sourcefile, $expected_cfile, "Got expected PMC file" );
    like( $source_code, qr/This file has a valid HEADERIZER HFILE/, 
        "Got expected source code" );
    is( $hfile, "$stub.h", "Got expected header file" );
}

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $stub = 'imcc';
    copy "$cwd/t/tools/dev/headerizer/testlib/$stub.in" =>
         "$tdir/$stub.y" or croak "Unable to copy file for testing";
    $ofile = "$tdir/$stub.y";
    my $expected_cfile = $ofile;
    my ($sourcefile, $source_code, $hfile) =
        qualify_sourcefile( {
            ofile           => $ofile,
            PConfig         => \%PConfig,
            is_yacc         => 1,
        } );
    is( $sourcefile, $expected_cfile, "Got expected C source file" );
    like( $source_code, qr/HEADERIZER HFILE: none/, "Got expected source code" );
    is( $hfile, 'none', "As expected, no header file" );
}

my (@args, %asserts);
@args = (
    'SHIM_INTERP',
    'ARGIN(Linked_List *list)',
    'ARGIN(List_Item_Header *item)',
);
%asserts = map { $_ => 1 } asserts_from_args( @args );
is( keys %asserts, 2, "Got expected number of asserts" );
ok( exists $asserts{'PARROT_ASSERT_ARG(list)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(item)'}, "Got expected assert" );

@args = (
    'PARROT_INTERP',
    'ARGIN(Linked_List *list)',
    'ARGIN(List_Item_Header *item)',
    'SHIM_INTERP',
);
%asserts = map { $_ => 1 } asserts_from_args( @args );
is( keys %asserts, 3, "Got expected number of asserts" );
ok( exists $asserts{'PARROT_ASSERT_ARG(list)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(item)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(interp)'}, "Got expected assert" );

@args = (
    'ARGFREE_NOTNULL(( _abcDEF123 )())',
    'PARROT_INTERP',
    'ARGIN(Linked_List *list)',
    'ARGIN(List_Item_Header *item)',
    'SHIM_INTERP',
);
%asserts = map { $_ => 1 } asserts_from_args( @args );
is( keys %asserts, 4, "Got expected number of asserts" );
ok( exists $asserts{'PARROT_ASSERT_ARG(list)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(item)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(interp)'}, "Got expected assert" );
ok( exists $asserts{'PARROT_ASSERT_ARG(_abcDEF123)'}, "Got expected assert" );

pass("Completed all tests in $0");

################### DOCUMENTATION ###################

=head1 NAME

01_functions.t - Test functions in Parrot::Headerizer::Functions.

=head1 SYNOPSIS

    % prove t/tools/dev/headerizer/01_functions.t

=head1 DESCRIPTION

The files in this directory test the publicly callable subroutines found in 
F<lib/Parrot/Headerizer/Functions.pm>.  By doing so, they help test the functionality
of the F<tools/dev/headerizer.pl> utility.


=head1 AUTHOR

James E Keenan

=head1 SEE ALSO

F<tools/dev/headerizer.pl>; F<lib/Parrot/Headerizer/Functions.pm>.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4: