#!/usr/bin/perl

# Copyright (c) 2013 Kirk Kimmel. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the 3-clause BSD license. See LICENSE.txt.
#
# The newest version of this file can be found at:
#   https://github.com/kimmel/ia-dirdiff

use v5.14;
use warnings;
use autodie qw( :all );
use utf8::all;

use HTTP::Tiny;
use JSON::XS qw( decode_json );

sub main {
    if ( @ARGV == 0 ) {
        say
            "usage: $0 item\nThis is an item -> http://archive.org/details/this_is_the_item_name";
        exit 1;
    }

    my $site = 'http://archive.org/details/' . $ARGV[0] . '/?output=json';

    my $response = HTTP::Tiny->new->get($site);
    die "Failed!\n" unless $response->{'success'};

    my $struct = decode_json( $response->{'content'} );

    opendir my $dh, q(.);
    my @files = readdir $dh;
    closedir $dh;

    foreach my $file ( sort keys $struct->{'files'} ) {

        # remove IA added files
        next if ( $file =~ m/_release_archive[.]torrent$/ixms );
        next if ( $file =~ m/_release_meta[.]xml$/ixms );
        next if ( $file =~ m/_release_files[.]xml$/ixms );
        next if ( $file =~ m/_meta[.]txt/ixms );

        my $lf = substr $file, 1;
        my ( undef, undef, undef, undef, undef, undef, undef, $size )
            = stat $lf;

        if ( !-e -s $lf ) {
            print "$lf not found\n";
            next;
        }
        print "$lf - ";

        if ( defined $size
            and ( $struct->{'files'}->{$file}->{'size'} == $size ) )
        {
            print "OK\n";
        }
        else {
            print "size mismatch\n";
        }

        @files = grep { !/^$lf$/xms } @files;
    }

    @files = grep { !/^[.]{1,2}$/xms } @files;
    @files = grep { !/metadata[.]csv/xms } @files;

    say "\nLocal only files:\n-----------------";
    for (@files) {
        say $_;
    }
    exit;
}

main() unless caller;

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

C<ia-dirdiff> - Diff the current working dir against an Internet Archive item

head1 USAGE

ia-dirdiff <item>

=head1 HOMEPAGE

https://github.com/kimmel/ia-dirdiff

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 < Kirk Kimmel >. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the 3-clause BSD license. The full text of this license can be found online at
< http://opensource.org/licenses/BSD-3-Clause >

=cut
