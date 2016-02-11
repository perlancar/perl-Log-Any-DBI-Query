package Log::Any::DBI::Query;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use DBI;
use Log::Any::For::Class qw(add_logging_to_class);

my $log_query  = $ENV{LOG_SQL_QUERY}  // 1;
my $log_result = $ENV{LOG_SQL_RESULT} // 0;

sub _precall_logger {
    my $args = shift;
    my $margs = $args->{args};

    my ($meth) = $args->{name} =~ /.+::(.+)/;
    return if $meth =~ /\Afetch.+\z/;
    $log->tracef("SQL query (%s): {{%s}}", $meth, $margs->[1]);
}

sub _postcall_logger {
    my $args = shift;

    #$log->tracef("D1: %s", $args->{name});

    my ($meth) = $args->{name} =~ /.+::(.+)/;
    return if $meth =~ /\Aprepare\z/;
    $log->tracef("SQL result (%s): %s", $meth, $args->{result});
}

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
                return 1 if $log_query && $meth =~
                    /\A(
                         DBI::db::(prepare|do|select.+)
                     )\z/x;
                return 1 if $log_result && $meth =~
                    /\A(
                         DBI::db::(do|select.+) |
                         DBI::st::(fetch.+)
                     )\z/x;
                0;
            },
        );
    };

    # DBI is used here to trigger loading of DBI::db
    $doit->("DBI", "DBI::db", "DBI::st");
}

1;
# ABSTRACT: Log DBI queries (and results)

=head1 SYNOPSIS

 use DBI;
 use Log::Any::DBI::Query;

 # now SQL queries will be logged
 my $dbh = DBI->connect("dbi:...", $user, $pass);
 $dbh->do("INSERT INTO table VALUES (...)");

From command-line:

 % TRACE=1 perl -MLog::Any::Adapter::Screen -MLog::Any::DBI::Query your-dbi-app.pl

To also log SQL results:

 % TRACE=1 LOG_SQL_RESULT=1 \
     perl -MLog::Any::Adapter::Screen -MLog::Any::DBI::Query your-dbi-app.pl

Sample log output:

 SQL query: {{INSERT INTO table VALUES (...)}


=head1 DESCRIPTION

This is a simple module you can do to log SQL queries for your L<DBI>-based
applications.

For queries, it logs calls to C<prepare()>, C<do()>, C<select*>.

For results, it logs calls to C<do()>, C<select*>, C<fetch*>.

Compared to L<Log::Any::For::DBI>, it produces a bit less noise if you are only
concerned with logging queries.


=head1 ENVIRONMENT

=head2 LOG_SQL_QUERY (bool, default 1)

=head2 LOG_SQL_RESULT (bool, default 1)


=head1 SEE ALSO

L<Log::Any::DBI::QueryResult>

L<Log::Any::For::DBI> which logs more methods, including C<connect()>, etc..

=cut
