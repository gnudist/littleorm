package ORM::Meta::Trait;

use Moose::Role;

has 'description' => ( is => 'rw',
		       isa => 'HashRef',
		       lazy => 1,
		       default => sub { {} } );

# has 'metadescription_classname' => (
#     is      => 'rw',
#     isa     => 'Str',
#     lazy    => 1,
#     default => sub {
#         'MooseX::MetaDescription::Description'
#     }
# );

# has 'metadescription' => (
#     is      => 'ro',
#     isa     => 'MooseX::MetaDescription::Description',
#     lazy    => 1,
#     default => sub {
#         my $self = shift;

#         my $metadesc_class = $self->metadescription_classname;
#         my $desc           = $self->description;

#         Class::MOP::load_class($metadesc_class);

#         if (my $traits = delete $desc->{traits}) {
#             my $meta = Moose::Meta::Class->create_anon_class(
#                 superclasses => [ $metadesc_class ],
#                 roles        => $self->prepare_traits_for_application($traits),
#             );
#             $meta->add_method('meta' => sub { $meta });
#             $metadesc_class = $meta->name;
#         }

#         return $metadesc_class->new(%$desc, descriptor => $self);
#     },
# );

#sub prepare_traits_for_application { $_[1] }

no Moose::Role;

1;

