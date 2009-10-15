package MooseX::FSM::State;

use Moose::Role;




=head1 NAME 
MooseX::FSM::State

=head1 SYNOPSIS
MooseX::FSM::State is a trait role that is applied to state attributes to define what addtional attributes can be attached to a State

=head1 ATTRIBUTES

=head2 enter
the enter attribute takes a coderef upon entering the defined state.  the coderef will be called.
=cut

has enter => (
	is		=> 'rw',
	isa		=> 'CodeRef',
	lazy	=> 1,
	default => sub {
			sub {
					my $self = shift; 
					$self->debug(2, "default enter called\n"); 
			}; 
		},
);

=head2 exit
the 'exit' attribute takes a coderef which will be called when the state it is defined on is transitioned into another state
=cut
has exit => (
	is		=> 'rw',
	isa		=> 'CodeRef',
	lazy	=> 1,
	default => sub { sub { my $self = shift; $self->debug( 2, "default exit called\n"); }; },
);

=head2 input
will install writters for listed attributes.  If a hashref is listed in the list the key will be used as the writter name and the value should be set to the desired attribute.
=cut

has inputs => (
	is		=> 'rw',
	isa		=> 'ArrayRef',
	lazy	=> 1,
	default	=> sub { []; },
);

=head2 output
will install accessors for listed attributes.  If a hashref is listed in the list the key will be uses as the accessor name for the attribute.
=cut

has outputs => (
	is		=> 'rw',
	isa		=> 'ArrayRef',
	lazy	=> 1,
	default	=> sub { []; },
);

=head2 methods
input takes either a hashref or an arrayref of input methods that will be aliased on the FSM to supplied coderefs.  
=cut
has methods => (
	is		=> 'rw',
	isa		=> 'HashRef',
	lazy	=> 1,
	default	=> sub { {}; },
);

=head2 transitions
transitions define how to move from one state to another.  Its composed of a hashref with the input function and the name of the state to transition to once that function has been called
=cut

has transitions => (
	is		 => 'ro',
	isa		 => 'HashRef',
	default  => sub { {}; },
	required => 1,
);
1;

package Moose::Meta::Attribute::Custom::Trait::State;
sub register_implementation {'MooseX::FSM::State'}

1;
