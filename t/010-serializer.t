use strict;
use warnings;
use Test;

use SOAP::Lite;

my @types1999 = qw(
   anyURI 
   string float double decimal timeDuration recurringDuration uriReference 
   integer nonPositiveInteger negativeInteger long int short byte
   nonNegativeInteger unsignedLong unsignedInt unsignedShort unsignedByte
   positiveInteger timeInstant time timePeriod date month year century 
   recurringDate recurringDay language
);

my @types2001 = qw(
    anyType anyURI
    string float double decimal dateTime timePeriod gMonth gYearMonth gYear
    century gMonthDay gDay duration recurringDuration anyURI
    language integer nonPositiveInteger negativeInteger long int short byte
    nonNegativeInteger unsignedLong unsignedInt unsignedShort unsignedByte
    positiveInteger date time dateTime
);

plan tests => ( scalar(@types1999) + scalar(@types2001) ) * 3 + 14;

test_serializer('SOAP::XMLSchema1999::Serializer', @types1999);
test_serializer('SOAP::XMLSchema2001::Serializer', @types2001);

sub test_serializer {
    my $package = shift;
    my @types = @_;

    print "# $package\n";

    for my $type (@types) {
        my $method = "as_$type";
	print "#   $method\n";
	use Data::Dumper;
        my $result = $package->$method('', 'test', $type , {});
	ok $result->[0] eq 'test';
	ok $result->[1]->{ 'xsi:type' };
	ok $result->[2] eq '';
    }

}

# additional tests

ok (SOAP::XMLSchema1999::Serializer->anyTypeValue eq 'ur-type');
my $enc = SOAP::XMLSchema1999::Serializer->as_hex('AA', 'test', 'hex', {});
ok $enc->[2] eq '4141';

$enc = SOAP::XMLSchema1999::Serializer->as_dateTime('AA', 'test', 'FOO', {});
ok $enc->[1]->{'xsi:type'} eq 'xsd:dateTime';
ok $enc->[2] eq 'AA';

$enc = SOAP::XMLSchema1999::Serializer->as_boolean(1, 'test', 'boolean', {});
ok $enc->[2] eq 'true';
$enc = SOAP::XMLSchema1999::Serializer->as_boolean(0, 'test', 'boolean', {});
ok $enc->[2] eq 'false';

$enc = SOAP::XMLSchema1999::Serializer->as_undef(1, 'test', 'boolean', {});
ok $enc eq '1';

$enc = SOAP::XMLSchema1999::Serializer->as_undef(0, 'test', 'boolean', {});
ok $enc eq '0';

$enc = SOAP::XMLSchema1999::Serializer->as_base64(0, 'test', 'string', {});
ok ($enc->[2] eq 'MA==');

print "# encoding/decoding Euro symbol in base64\n";
if ($] < 5.008) {
    print "# Skippng unicode test on perl <5.8 ($])\n";
    ok(1);
} 
else {
    eval {
        # may fail on old perls
        my $str = chr(8364);
        utf8::encode($str);
        my $enc = SOAP::XMLSchema1999::Serializer->as_base64($str, 'test', 'string', {});
        my $enc2001 = SOAP::XMLSchema2001::Serializer->as_base64Binary($str, 'test', 'string', {});
        use MIME::Base64;
        for ($enc, $enc2001) {
            if ( decode_base64($_->[2]) eq $str ) {
                ok(1);
            }
            else {
                print "$str, ", decode_base64($enc->[2]), "\n";
                ok(0);
            }
        }
    }
}    



eval { SOAP::XMLSchema1999::Serializer->as_string([], 'test', 'string', {}) };
ok $@ =~m{ \A String \s value \s expected }xms;

eval { SOAP::XMLSchema1999::Serializer->as_anyURI([], 'test', 'string', {}) };
ok $@ =~m{ \A String \s value \s expected }xms;

ok ! SOAP::XMLSchema1999::Serializer->DESTROY();