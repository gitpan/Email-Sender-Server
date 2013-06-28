requires "Class::Date" => "0";
requires "Data::Dumper" => "0";
requires "Emailesque" => "0";
requires "File::Basename" => "0";
requires "File::Copy" => "0";
requires "File::Path" => "0";
requires "File::Slurp" => "0";
requires "File::Spec" => "0";
requires "Hash::Merge" => "0";
requires "Moo" => "0";
requires "utf8" => "0";

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};
