use utf8;

package Email::Sender::Server::Schema::Result::Message;
{
    $Email::Sender::Server::Schema::Result::Message::VERSION = '0.01_01';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Email::Sender::Server::Schema::Result::Message

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<message>

=cut

__PACKAGE__->table("message");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 worker

  data_type: 'integer'
  default_value: null
  is_nullable: 1

=head2 attempt

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 status

  data_type: 'text'
  default_value: 'queued'
  is_nullable: 1

=head2 to

  data_type: 'text'
  is_nullable: 0

=head2 reply_to

  data_type: 'text'
  is_nullable: 1

=head2 from

  data_type: 'text'
  is_nullable: 0

=head2 cc

  data_type: 'text'
  is_nullable: 1

=head2 bcc

  data_type: 'text'
  is_nullable: 1

=head2 subject

  data_type: 'text'
  is_nullable: 0

=head2 body_text

  data_type: 'text'
  is_nullable: 1

=head2 body_html

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'text'
  is_nullable: 1

=head2 updated

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    {data_type => "integer", is_auto_increment => 1, is_nullable => 0},
    "worker",
    {data_type => "integer", default_value => \"null", is_nullable => 1},
    "attempt",
    {data_type => "integer", default_value => 0, is_nullable => 1},
    "status",
    {data_type => "text", default_value => "queued", is_nullable => 1},
    "to",
    {data_type => "text", is_nullable => 0},
    "reply_to",
    {data_type => "text", is_nullable => 1},
    "from",
    {data_type => "text", is_nullable => 0},
    "cc",
    {data_type => "text", is_nullable => 1},
    "bcc",
    {data_type => "text", is_nullable => 1},
    "subject",
    {data_type => "text", is_nullable => 0},
    "body_text",
    {data_type => "text", is_nullable => 1},
    "body_html",
    {data_type => "text", is_nullable => 1},
    "created",
    {data_type => "text", is_nullable => 1},
    "updated",
    {data_type => "text", is_nullable => 1},
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 attachments

Type: has_many

Related object: L<Email::Sender::Server::Schema::Result::Attachment>

=cut

__PACKAGE__->has_many(
    "attachments",
    "Email::Sender::Server::Schema::Result::Attachment",
    {"foreign.message" => "self.id"},
    {cascade_copy      => 0, cascade_delete => 0},
);

=head2 headers

Type: has_many

Related object: L<Email::Sender::Server::Schema::Result::Header>

=cut

__PACKAGE__->has_many(
    "headers",
    "Email::Sender::Server::Schema::Result::Header",
    {"foreign.message" => "self.id"},
    {cascade_copy      => 0, cascade_delete => 0},
);

=head2 logs

Type: has_many

Related object: L<Email::Sender::Server::Schema::Result::Log>

=cut

__PACKAGE__->has_many(
    "logs",
    "Email::Sender::Server::Schema::Result::Log",
    {"foreign.message" => "self.id"},
    {cascade_copy      => 0, cascade_delete => 0},
);

=head2 tags

Type: has_many

Related object: L<Email::Sender::Server::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
    "tags",
    "Email::Sender::Server::Schema::Result::Tag",
    {"foreign.message" => "self.id"},
    {cascade_copy      => 0, cascade_delete => 0},
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-03-13 17:38:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LvNQDE2nzv7q7q5D5j7zXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
