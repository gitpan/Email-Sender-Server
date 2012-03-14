use utf8;

package Email::Sender::Server::Schema::Result::Tag;
{
    $Email::Sender::Server::Schema::Result::Tag::VERSION = '0.01_01';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Email::Sender::Server::Schema::Result::Tag

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

=head1 TABLE: C<tag>

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 message

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {data_type => "integer", is_auto_increment => 1, is_nullable => 0},
    "message",
    {data_type => "integer", is_foreign_key => 1, is_nullable => 0},
    "value",
    {data_type => "text", is_nullable => 0},
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 message

Type: belongs_to

Related object: L<Email::Sender::Server::Schema::Result::Message>

=cut

__PACKAGE__->belongs_to(
    "message",
    "Email::Sender::Server::Schema::Result::Message",
    {id            => "message"},
    {is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE"},
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-03-13 17:38:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GfinjFGa86xU+hNzKSJGmg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
