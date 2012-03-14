# ABSTRACT: ESS CLI Command Base-Class

package Email::Sender::Server::Command;
{
    $Email::Sender::Server::Command::VERSION = '0.01_01';
}

use strict;
use warnings;

our $VERSION = '0.01_01';    # VERSION

sub error {

    my ($self, @errors) = @_;

    push @{$self->{errors}}, @errors;

    return $self;

}

sub execute {

    my ($self, $action) = @_;

    my $actions = {$self->actions()};

    defined $actions->{$action}
      ? $actions->{$action}->($self, $self->options(@_))
      : $self->usage()

}

sub has_errors {

    my ($self) = @_;

    return $self->{errors} ? scalar @{$self->{errors}} : 0;

}

sub has_messages {

    my ($self) = @_;

    return $self->{messages} ? scalar @{$self->{messages}} : 0;

}

sub message {

    my ($self, @messages) = @_;

    push @{$self->{messages}}, @messages;

    return $self;

}

sub new {

    my $class = shift;

    bless {@_}, $class;

}

sub options {

    my ($self, @args) = @_;

    @args = @ARGV unless @args;

    my $options   = {};
    my $arguments = [];

    for (my $i = 0; $i < @args; $i++) {

        my $arg = $args[$i];

        if ($arg =~ /^:(.*)/) {

            $options->{$1} = 1;

        }

        elsif ($arg =~ /(.*):$/) {

            $options->{$1} = $args[++$i];

        }

        elsif ($arg =~ /([^:]+):(.*)$/) {

            $options->{$1} = $2;

        }

        else {

            push @{$arguments}, $arg;

        }

    }

    return ($options, $arguments);

}

sub run {

    my ($self, $action, @extras) = @_;

    if ($action) {

        my $results = $self->execute($action, @extras);

        return $results;

    }

    else {

        return $self->usage();

    }

}

sub usage {

    my ($self) = @_;

    my $class = ref $self || $self;

    while (my ($command, $props) = each(%{$self->{commands}})) {

        if ($props->{name} eq $class) {

            return system "perldoc", $props->{path};

        }

    }

}

sub actions { }    # no-op

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Command - ESS CLI Command Base-Class

=head1 VERSION

version 0.01_01

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

