package Email::Sender::Server::Base;
{
    $Email::Sender::Server::Base::VERSION = '0.01_01';
}

use strict;
use warnings;

use Validation::Class;

use Carp 'confess';
use File::ShareDir 'dist_file';
use FindBin;
use Cwd;

use Email::Sender::Server::Schema;

our $VERSION = '0.01_01';    # VERSION

has script => sub {

    shift->storage . ".sql"

};

has settings => sub {

    do shift->storage . ".pl"

};

has storage => sub {

    my $file;

    # look right in front of you

    $file = Cwd::getcwd . "/ess_queue.db";

    unless (-e $file) {

        # inspect system

        eval {

            $file = dist_file 'Email-Sender-Server', 'ess_queue.db'

        };

        # inspect local enviroment

        if ($@) {

            # try to find it locally (dev dist share folder)
            $file = $FindBin::Bin . "/../share/ess_queue.db";

            unless (-e $file) {

                $file = $FindBin::Bin . "/../ess_queue.db";

                unless (-e $file) {

                    $file = "./ess_queue.db";

                }

            }

        }

    }

    return $file;

};

bld sub {

    my ($self) = @_;

    confess "Error, cannot find the ESS database file, "
      . $self->storage
      . " does not exist"
      unless -e $self->storage;

    my @conn_string = (
        "dbi:SQLite:" . $self->storage,
        "", "",
        {   quote_char => '"',
            name_sep   => '.'
        }
    );

    my $database = Email::Sender::Server::Schema->connect(@conn_string);

    $self->stash(database => $database);

    return $self;

};


1;
