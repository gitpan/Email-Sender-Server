package Email::Sender::Server::Directives;
{
    $Email::Sender::Server::Directives::VERSION = '0.30';
}

use strict;
use warnings;

use Validation::Class;

use Data::Validate::Email;

our $VERSION = '0.30';    # VERSION

dir 'is_email' => sub {

    my ($dir, $value, $field, $self) = @_;

    my $validator = Data::Validate::Email->new;

    my @emails = $dir eq '1+' ? split /,(?:\s+)?/, $value : ($value);

    foreach my $email (@emails) {

        unless ($validator->is_email($email)) {

            my $handle = $field->{label} || $field->{name};

            my $error =
              $dir eq '+1'
              ? "$handle must have valid email addresses"
              : "$handle must be a valid email address";

            $self->error($field, $error);

            return 0;

        }

    }

    return 1;

};

1;
