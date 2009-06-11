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

BEGIN{$TYPEINFO{GetLanguages} = ["function",
    ["list","string"]];
#    "string"];
}
sub GetLanguages {
  my $ret = [];
  my $languages = Language->GetLanguagesMap(0);
  while  ( my ($key, $value) = each (%$languages)){
    push @$ret, "$key---".$value->[0];
  }
  return $ret;
}

BEGIN{$TYPEINFO{GetCurrentLanguage} = ["function",
    "string"];
}
sub GetCurrentLanguage {
  return Language->language;
}

BEGIN{$TYPEINFO{SetCurrentLanguage} = ["function",
    "boolean","string"];
}
sub SetCurrentLanguage {
  my $self = shift;
  my $value = shift;
  Language->QuickSet($value);
  Language->Save();
  return 1;
}

BEGIN{$TYPEINFO{IsUTF8} = ["function",
    "boolean"];
}
sub IsUTF8 {
  return Language->GetExpertValues->{"use_utf8"};
}

BEGIN{$TYPEINFO{SetUTF8} = ["function",
    "boolean","boolean"];
}
sub SetUTF8 {
  my $self = shift;
  my $value = shift;
  my $arg = { "use_utf8" => YaST::YCP::Boolean($value) };
  Language->SetExpertValues($arg);
  Language->Save();
  return 1;
}

BEGIN{$TYPEINFO{GetRootLang} = ["function",
    "string"];
}
sub GetRootLang {
  return Language->GetExpertValues->{"rootlang"};
}

BEGIN{$TYPEINFO{SetRootLang} = ["function",
    "boolean","string"];
}
sub SetRootLang {
  my $self = shift;
  my $value = shift;
  my $arg = { "rootlang" => $value };
  Language->SetExpertValues($arg);
  Language->Save();
  return 1;
}

1;
