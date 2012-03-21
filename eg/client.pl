#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

use Email::Sender::Server::Client 'mail';

my @message = (
    to      => 'guy@abc.co',
    from    => 'dude@ana.io',
    subject => 'Hows it hangin?',
    html    => 'Suspendisse sit amet orci nec purus varius pharetra.'
);

#my $result = mail @message;

#print $result, "\n";

my $mailer = Email::Sender::Server::Client->new(
    path => '/tmp/mailer'
);

print $mailer->send(@message), "\n";

# print $mailer->errors_to_string, "\n";
