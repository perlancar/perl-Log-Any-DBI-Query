package Log::Any::DBI::Query;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use DBI;
use Log::Any::For::Class qw(add_logging_to_class);

sub _precall_logger {
    my $args = shift;
    my $margs = $args->{args};

    $log->tracef("SQL query: {{%s}}", $margs->[1]);
}

sub _postcall_logger {}

sub import {
    my $class = shift;
    my @meths = @_;

    # I put it in $doit in case we need to add more classes from inside $logger,
    # e.g. DBD::*, etc.
    my $doit;
    $doit = sub {
        my @classes = @_;

        add_logging_to_class(
            classes => \@classes,
            precall_logger => \&_precall_logger,
            postcall_logger => \&_postcall_logger,
            filter_methods => sub {
                my $meth = shift;
                return unless $meth =~
                    /\A(
                         DBI::db::(prepare|do)
                     )\z/x;
                1;
            },
        );
    };

    # DBI is used here to trigger loading of DBI::db
    $doit->("DBI::db");
}

1;
# ABSTRACT: Log DBI queries

=head1 SYNOPSIS

 use DBI;
 use Log::Any::DBI::Query;

 # now SQL queries passed to prepare()'s and do()'s will be logged
 my $dbh = DBI->connect("dbi:...", $user, $pass);
 $dbh->do("INSERT INTO table VALUES (...)");

From command-line:

 % perl -MLog::Any::Adapter::ScreenColordLevel -MLog::Any::DBI::Query your-dbi-app.pl


=head1 DESCRIPTION

This is a simple module you can do to log SQL statements/queries for your
L<DBI>-based applications.


=head1 SEE ALSO

L<Log::Any::For::DBI>, which logs calls to C<prepare()>, C<do()>, as well as
other DBI methods.

=cut
