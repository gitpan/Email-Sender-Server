# ABSTRACT: Email Server Worker

package Email::Sender::Server::Worker;
{
    $Email::Sender::Server::Worker::VERSION = '0.50';
}

use strict;
use warnings;

use Validation::Class;

set {

    roles => ['Email::Sender::Server::Base']

};

use Carp 'confess';
use File::Path 'mkpath';
use File::Slurp 'write_file';
use File::Spec::Functions 'curdir', 'catdir', 'catfile', 'splitdir';

use Email::Sender::Server::Message;
use Class::Date;

our $VERSION = '0.50';    # VERSION


has id => $$;

has workspace => sub {

    my $self = shift;

    $self->directory('worker', $self->id);

};

bld sub {

    my ($self) = @_;

    my $workspace = $self->workspace;

    unless (-d $workspace && -w $workspace) {

        confess "Couldn't find or access (write-to) the worker's workspace "
          . $workspace;

    }

    return $self;

};

sub process_message {

    my ($self, $data) = @_;

    my $message = Email::Sender::Server::Message->new;

    if ($message->from_hash($data)) {

        $message->send;

        return ($message->error_count ? 0 : 1, $message);

    }

    else {

        return (0, $message);

    }

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Worker - Email Server Worker

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    # poll and process queued email messages
    
    use Email::Sender::Server::Worker;
    
    my $worker = Email::Sender::Server::Worker->new;
    
    my ($ok, $message) = $worker->process_message;

=head1 DESCRIPTION

Email::Sender::Server::Worker is the email processing agent which fetches messages
from the data directory and performs some action on them, e.g. processing an email
and delivering it to its recipient(s).

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

