package Email::Sender::Server::Controller::Status;
{
    $Email::Sender::Server::Controller::Status::VERSION = '0.50';
}

use Command::Do;

has abstract => 'display ess processing information';

=head1 NAME

ess-status - display ess processing information

=head1 SYNOPSIS

    ess status
    
This command reports the current state of the ESS datastore including the status
of the worker processes if the application is in run-mode.

=cut

sub run {

    my ($self) = @_;

    require Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    my $queued_count = @{$manager->message_filelist} || 0;

    print "ESS Qeueue has $queued_count Message(s)\n";

    sub count_files_in_directory {

        my ($directory) = @_;

        my @files = (glob "$directory/*.msg");

        my $count = scalar @files;

        my @sub_directories = grep {

            -d $_ && $_ !~ /\.+$/

        } glob "$directory/*";

        for my $directory (@sub_directories) {

            $count += count_files_in_directory($directory);

        }

        return $count;

    }

    opendir my $workspace_hdl, $manager->directory('worker');

    my @workers = grep { !/^\./ } readdir $workspace_hdl;

    if (@workers) {

        print "ESS Currently Employs " . @workers . " Worker(s)\n\n";

        foreach my $worker (@workers) {

            my $count = @{$manager->message_filelist('worker', $worker)} || 0;

            print "\tESS Worker $worker is Processing $count Message(s)\n";

        }

        print "\n";

    }

    my $passed_count = count_files_in_directory($manager->directory('passed'));

    my $failed_count = count_files_in_directory($manager->directory('failed'));

    print "ESS has successfully processed $passed_count Message(s)\n";
    print "ESS has failed to process $failed_count Message(s)\n";

    exit;

}

1;
