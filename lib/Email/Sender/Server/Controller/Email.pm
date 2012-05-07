package Email::Sender::Server::Controller::Email;
{
    $Email::Sender::Server::Controller::Email::VERSION = '0.50';
}

use Command::Do;

has abstract => 'send an email from the command-line';

=head1 NAME

ess-email - send an email from the command-line

=head1 SYNOPSIS

    ess email [--to | -t] [--from | -f] [--subject | -s]
        [--format [ text | html]] <message>
    
This command allows you to fire off emails from the command-line, it is perfect
for sending one-off emails or for use with schedulers (crontab, etc). Email
messages default to being delivered as text messages. This command can also
accept message data from STDIN, e.g.

    cat file.txt | ess email -t root@localhost -f user@localhost -s "...testing"

=head1 OPTIONS

=head2 -t, --to

The email address of the recipient you wish to receive the constructed email
message.

=head2 -f, --from

The email address of the identity you wish to send the constructed email
message from.

=head2 -s, --subject

The subject of the email to be delivered.

=head2 --format [text|html]

The format which the constructed email message should be delivered in. This
option defaults to the text format.

=cut

fld to => {
    optspec  => 's',
    required => 1,
    filters  => ['trim'],
    alias    => ['t']
};

fld from => {
    optspec  => 's',
    required => 1,
    filters  => ['trim'],
    alias    => ['f']
};

fld subject => {
    optspec  => 's',
    required => 1,
    filters  => ['trim'],
    alias    => ['s']
};

fld format => {
    optspec  => 's',
    required => 1,
    filters  => ['trim', 'lowercase'],
    options  => 'text, html',
    default  => 'text'
};

fld message => {required => 1};

bld sub {

    my ($self) = @_;

    # capture message from stdin

    unless ($self->message) {

        if (!-t STDIN) {

            my @content = (<STDIN>);

            $self->message(join "", @content);

        }

        else {

            $self->message(shift @ARGV);

        }

    }

};

mth run => {

    input => [qw/to from subject message/],
    using => sub {

        my ($self) = @_;

        require Email::Sender::Server::Client;

        my $client = Email::Sender::Server::Client->new;

        my $id = $client->send(

            'to'          => $self->to,
            'from'        => $self->from,
            'subject'     => $self->subject,
            $self->format => $self->message

        );

        exit print "Submitted Email for Processing (msg: $id)\n";

      }

};

1;
