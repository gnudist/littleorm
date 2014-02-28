#!/usr/bin/perl

# This script updates CPAN source tree using files from ORM/ directory
# above.

use strict;
use Cwd 'getcwd';
use Carp::Assert 'assert';
use File::Spec ();
use File::Temp 'tmpnam';
use Perl6::Slurp 'slurp';
use Data::Dumper 'Dumper';

&main();

################################################################################


sub main
{
	my $dir = '../ORM'; # no slash

	assert( -f File::Spec -> catfile( $dir, 'Model.pm' ),
		'im in the wrong location?' );

	my @files = &get_files_list( $dir );
#	push @files, '../ORM.pm';

	foreach my $file ( @files )
	{
		assert( -f $file );
		my $same_file_in_cpan_distro = &gen_file_name_in_cpan_distro( $file, $dir );

		assert( -f $same_file_in_cpan_distro, 
			"Missing in cpan: " . $same_file_in_cpan_distro );

		printf( "%s\n", $file );
		&patch_from_to( $file,
				$same_file_in_cpan_distro );
	}


}

sub gen_file_name_in_cpan_distro
{
	my ( $fn, $dir ) = @_;

	my $cpan_dir = 'LittleORM/lib/LittleORM';
	$fn =~ s/\Q$dir\E/$cpan_dir/;
	return $fn;
}

sub patch_from_to
{
	my ( $from, $to ) = @_;

	assert( -f $from );
	assert( -f $to );

	assert( my $from_data = slurp( $from ) );

	my $patched = &patch_file_data( $from_data );

	assert( open( my $fh, '>', $to ) );
	print $fh $patched;
	close( $fh );

}

sub patch_file_data
{
	my $data = shift;

	my %replaces = ( 'ORM::' => 'LittleORM::' );

	while( my ( $from, $to ) = each %replaces )
	{
		$data =~ s/\Q$from\E/$to/g;
	}

	return $data;
}

sub get_files_list
{
	my $dir = shift;

	my $find = '/usr/bin/find'; # thats so scrubby
	assert( ( -f $find ) and ( -x $find ) );
	my $tmpfile = tmpnam();
	my $cmd = sprintf( "%s %s -type f > %s",
			   $find,
			   $dir,
			   $tmpfile );

	{
		my $rc = system( $cmd );
		$rc = $rc >> 8;
		assert( $rc == 0 );
	}
	assert( -f $tmpfile );

	my $contents = slurp( $tmpfile );
	unlink( $tmpfile );

	my @files = split( /[\x0d\x0a]+/, $contents );

	return @files;
}
