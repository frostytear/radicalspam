#
# Mail::SPF::Mech::PTR
# SPF record "ptr" mechanism class.
#
# (C) 2005-2008 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: PTR.pm 50 2008-08-17 21:28:15Z Julian Mehnle $
#
##############################################################################

package Mail::SPF::Mech::PTR;

=head1 NAME

Mail::SPF::Mech::PTR - SPF record C<ptr> mechanism class

=cut

use warnings;
use strict;

use base 'Mail::SPF::SenderIPAddrMech';

use Mail::SPF::Util;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant name           => 'ptr';
use constant name_pattern   => qr/${\name}/i;

=head1 DESCRIPTION

An object of class B<Mail::SPF::Mech::PTR> represents an SPF record mechanism
of type C<ptr>.

=head2 Constructors

The following constructors are provided:

=over

=item B<new(%options)>: returns I<Mail::SPF::Mech::PTR>

Creates a new SPF record C<ptr> mechanism object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<qualifier>

=item B<domain_spec>

See L<Mail::SPF::Mech/new>.

=back

=item B<new_from_string($text, %options)>: returns I<Mail::SPF::Mech::PTR>;
throws I<Mail::SPF::ENothingToParse>, I<Mail::SPF::EInvalidMech>

Creates a new SPF record C<ptr> mechanism object by parsing the string and
any options given.

=back

=head2 Class methods

The following class methods are provided:

=over

=item B<default_qualifier>

=item B<qualifier_pattern>

See L<Mail::SPF::Mech/Class methods>.

=item B<name>: returns I<string>

Returns B<'ptr'>.

=item B<name_pattern>: returns I<Regexp>

Returns a regular expression that matches a mechanism name of B<'ptr'>.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=cut

sub parse_params {
    my ($self) = @_;
    $self->parse_domain_spec();
    return;
}

=item B<text>

=item B<qualifier>

=item B<params>

=cut

sub params {
    my ($self) = @_;
    return defined($self->{domain_spec}) ? ':' . $self->{domain_spec} : undef;
}

=item B<stringify>

See L<Mail::SPF::Mech/Instance methods>.

=item B<domain_spec>: returns I<Mail::SPF::MacroString>

Returns the C<domain-spec> parameter of the mechanism.

=cut

# Make read-only accessor:
__PACKAGE__->make_accessor('domain_spec', TRUE);

=item B<match($server, $request)>: returns I<boolean>

Checks whether the mechanism's target domain name, or a sub-domain thereof, is
a "valid" domain name for the given request's IP address (see
L<Mail::SPF::Request/ip_address>), and returns B<true> if it does, or B<false>
otherwise.  See L<Mail::SPF::Util/valid_domain_for_ip_address> for how domains
are validated.  See RFC 4408, 5.5, for the description of an equivalent
algorithm.

=cut

sub match {
    my ($self, $server, $request) = @_;
    $server->count_dns_interactive_term($request);
    return
        Mail::SPF::Util->valid_domain_for_ip_address(
            $server, $request, $request->ip_address, $self->domain($server, $request))
        ? TRUE : FALSE;
}

=back

=head1 SEE ALSO

L<Mail::SPF>, L<Mail::SPF::Record>, L<Mail::SPF::Term>, L<Mail::SPF::Mech>

L<http://www.ietf.org/rfc/rfc4408.txt>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;
