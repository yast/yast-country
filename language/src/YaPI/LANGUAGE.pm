package YaPI::LANGUAGE;

use strict;
use YaST::YCP qw(Boolean);
use YaPI;

textdomain("language");

# ------------------- imported modules
YaST::YCP::Import ("Language");
# -------------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES9');
our %TYPEINFO;


BEGIN{$TYPEINFO{GetSettings} = ["function",
    ["map","string","any"]
,["map","string","string"]];
}
sub GetSettings {
  my $self = shift;
  my $values = shift;
  my $ret = {};
  if ($values->{"languages"} eq "true"){
    my $languages = Language->GetLanguagesMap(0);
  }
  if ($values->{"current"} eq "true"){
    $ret->{"current"} = Language->language;
  }
  my $expr = Language->GetExpertValues();
  if ($values->{"utf8"} eq "true"){
    $ret->{"utf8"} = $expr->{"use_utf8"}?"true":"false";
  }
  if ($values->{"rootlang"} eq "true"){
    $ret->{"rootlang"} = $expr->{"rootlang"};
  }
  return $ret;
}

BEGIN{$TYPEINFO{SetSettings} = ["function",
    "boolean",["map","string","string"]];
}
sub SetSettings {
  my $self = shift;
  my $values = shift;
  if ( defined $values->{"current"}){
    Language->QuickSet($values->{"current"});
  }
  my $expr = {};
  if (defined $values->{"utf8"}){
    $expr->{"use_utf8"} = YaST::YCP::Boolean($values->{"utf8"} eq "true");
  }
  if (defined $values->{"rootlang"}){
    $expr->{"rootlang"} = $values->{"rootlang"};
  }
  Language->SetExpertValues($expr);
  Language->Save();
  return 1;
}

1;
