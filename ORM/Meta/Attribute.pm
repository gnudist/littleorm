package ORM::Meta::Attribute;

use Moose;

extends 'Moose::Meta::Attribute';
with 'ORM::Meta::Trait';

no Moose; 

1;
