#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

#use Email::Sender::Server::Client;
#
#my $mailer = Email::Sender::Server::Client->new;
#
#print $mailer->message(
#    
#    to      => 'guy@abc.co',
#    from    => 'dude@ana.io',
#    subject => 'Hows it hangin?',
#    html    => 'Suspendisse sit amet orci nec purus varius pharetra.'
#    
#) for (1..10);

use Data::Dumper 'Dumper';

use Email::Sender::Server::Worker;

my $worker  = Email::Sender::Server::Worker->new;

while (my $message = $worker->next_message) {
    
    # $queue->deliver_message($message);
    
    print Dumper $message;
    
    sleep 5;
    
}

