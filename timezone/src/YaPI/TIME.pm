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

BEGIN{$TYPEINFO{GetZoneMap} = ["function",
    ["list",["map","string","string"]]];
}
sub GetZoneMap {
  my $ret = [];
  my $zones = Timezone->get_zonemap();
#code entries to one string for dbus limitation
  foreach my $zone (@$zones){
    my $finalstring = "";
    while  ( my ($key, $value) = each (%{$zone->{"entries"}})){
      $finalstring = "$finalstring;$key->$value";
    }
    $zone->{"entries"} = $finalstring;
  }
  return $zones;
}

BEGIN{$TYPEINFO{UTCStatus} = ["function",
    "string"];
}
sub UTCStatus {
  return "UTConly" if (Timezone->utc_only());
  return "UTC" if (Timezone->hwclock eq "-u");
  return "local";
}

BEGIN{$TYPEINFO{GetTime} = ["function",
    "string"];
}
sub GetTime {
  return Timezone->GetDateTime(YaST::YCP::Boolean(1),YaST::YCP::Boolean(0));
}


1;
