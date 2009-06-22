package YaPI::TIME;

use strict;
use YaST::YCP qw(Boolean);
use YaPI;

textdomain("time");

# ------------------- imported modules
YaST::YCP::Import ("Timezone");
# -------------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES9');
our %TYPEINFO;

BEGIN{$TYPEINFO{Read} = ["function",
    ["map","string","any"],["map","string","string"]];
}
sub Read {
  my $self = shift;
  my $args = shift;
  my $ret = [];
  if ($args->{"zones"} eq "true")
  {
    $ret->{"zone"} = Timezone->get_zonemap();
  }
  if ($args->{"utcstatus"} eq "true"){
    if (Timezone->utc_only()){
      $ret->{"utcstatus"} = "UTConly";
    } elsif (Timezone->hwclock eq "-u") {
      $ret->{"utcstatus"} = "UTC";
    } else {
      $ret->{"utcstatus"} = "local";
    }
  }
  if ($args->{"currenttime"} eq "true"){
    $ret->{"time"} = Timezone->GetDateTime(YaST::YCP::Boolean(1),YaST::YCP::Boolean(0));
  }
  return $ret;
}

1;
