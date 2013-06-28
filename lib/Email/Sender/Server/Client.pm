# ABSTRACT: Email Delivery Agent

package Email::Sender::Server::Client;

use Email::Sender::Server::Manager;

use Moo;
use utf8;
use Exporter 'import';

our $VERSION = '1.000000'; # VERSION

our @EXPORT_OK = qw(email);



sub email {
    my $input = pop;
    die "Error preparing email: please provide arguments as a hashref"
        unless 'HASH' eq ref $input;

    $ENV{ESS_DATA} = delete $input->{'path'} if $input->{'path'};

    my $manager = Email::Sender::Server::Manager->new;
    my $result = $manager->create_work(%{$input});

    return $result;
}

1;

__END__

=pod

=head1 NAME

Email::Sender::Server::Client - Email Delivery Agent

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

    # sending email is simple

    use Email::Sender::Server::Client 'email';

    my $msgfile = email { to => '...', subject => '...', body => '...' };

    # ... check on the status of $msgfile

    print "file has been queued" if -f $msgfile;
    print "file has been processed" if -f $msgfile;

or using an object-oriented approach ....

    use Email::Sender::Server::Client;

    my $client = Email::Sender::Server::Client->new;
    my $msgfile = $client->email({to => '...', subject => '...', body => '...'});

    print "file has been queued" if -f $msgfile;
    print "file has been processed" if -f $msgfile;

Please see the L<Email::Sender::Server::Message> class for attributes that can
be used as arguments to the mail() and send() methods.

Currently all ESS classes operate out of the current-working-directory which can
be sub-optimal, especially when used in other classes that can be utilized by
various different scripts.

The ESS_DATA environment variable can be set to change the path of the ess_data
(data) directory utilized by the ess program, otherwise you may use the path
parameter.

By default, a "ess_data" folder is created for you automatically in the
current directory however when changing the path to the ess_data directory, please
note that such a change will supercede the defaults and data will be stored at
the path you've specified. For continuity, try to use absolute paths only!!!

=head1 DESCRIPTION

Email::Sender::Server::Client provides an interface to the ESS non-blocking
email delivery system which queues emails for later delivery. This class is a
simple wrapper around the L<Email::Sender::Server::Manager> class, the manager
is responsible for queuing email messages and delegating tasks to the worker
processes.

=head1 EXPORTS

=head2 email

The email method is designed to provide a simple single method for sending
emails to the server. It accepts valid attributes accepted by
L<Email::Sender::Server::Message>. It returns a list of two elements, a client
object and the filepath of the queued message if the operation was successful.

    use Email::Sender::Server::Client 'email';

    email { to => '...', subject => '...', body => '...' }
        or die "Error sending message to ...";

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
