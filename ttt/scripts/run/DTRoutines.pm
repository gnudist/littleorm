#!/usr/bin/perl

package DTRoutines;

use Carp::Assert 'assert';

use DateTime ();
use DateTime::Format::Strptime ();

sub timestamp_formatter
{
        return DateTime::Format::Strptime -> new( locale  => 'ru_RU',
                                                  pattern => '%F %T');
}

sub ts2dt
{
        my $time_stamp = shift;

        my $dt = &timestamp_formatter() -> parse_datetime( $time_stamp );

        assert( $dt, $time_stamp );

        return $dt;
}

sub dt2ts
{
        my $dt = shift;

        my $formatter = &timestamp_formatter();

        return $formatter -> format_datetime( $dt );
}

42;
