#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

use Email::Sender::Server::Manager;

my $manager = Email::Sender::Server::Manager->new;

my @message = (
    to      => 'guy@abc.co',
    from    => 'dude@ana.io',
    subject => 'Hows it hangin?',
    html    => 'Suspendisse sit amet orci nec purus varius pharetra.'
);

for (1..25) {
    
    my $result = $manager->create_work(@message);
    
    print "new message ", $result, "\n";
    
}

$manager->process_workload;