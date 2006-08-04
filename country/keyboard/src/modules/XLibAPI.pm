#
# XLibAPI.pm
# wrapper for XLib.pm functions, accessing libsax
#

package XLibAPI;

use strict;
use YaST::YCP qw(:LOGGING Boolean sformat);;
use YaPI;
use Data::Dumper;

YaST::YCP::Import ("XLib");

our %TYPEINFO;

use strict;
use Errno qw(ENOENT);


# initialize libsax library
sub initialize {

    if (! XLib->isInitialized()) {
	XLib->loadApplication();
    }
}

# return current X Keyboard Layout
BEGIN{ $TYPEINFO{getXkbLayout} = ["function", "string"]; }
sub getXkbLayout {

    initialize ();
    return XLib->getXkbLayout ();
}

# set new X Keyboard Layout
BEGIN{ $TYPEINFO{setXkbLayout} = ["function", "void", "string"]; }
sub setXkbLayout {

    my ($self, $layout)	= @_;
    initialize ();
    XLib->setXkbLayout ($layout);
}

# set new Xkb model
BEGIN{ $TYPEINFO{setXkbModel} = ["function", "void", "string"]; }
sub setXkbModel {

    my ($self, $model)	= @_;
    initialize ();
    XLib->setXkbModel ($model);
}

# set new Xkb Variant
# parameters: layout, variant_for_layout
BEGIN{ $TYPEINFO{setXkbVariant} = ["function", "void", "string", "string"]; }
sub setXkbVariant {

    my ($self, $layout, $variant)	= @_;
    initialize ();
    XLib->setXkbVariant ($layout, $variant);
}

# set mapping for the special keys (Left/Right-Alt Scroll-Lock and Right Ctrl)
# parameter: map of type [ special_key_id : mapping_id ]
BEGIN{ $TYPEINFO{setXkbMappings} = ["function", "void", ["map", "string", "string"]]; }
sub setXkbMappings {

    my ($self, $mappings)	= @_;
    initialize ();
    XLib->setXkbMappings ($mappings);
}

# set Xkb options
# parameter: list of options
BEGIN{ $TYPEINFO{setXkbOptions} = ["function", "void", ["list", "string"]]; }
sub setXkbOptions {

    my ($self, $options)	= @_;
    initialize ();
    XLib->setXkbOptions ($options);
}

# write the changes, return true for success
BEGIN{ $TYPEINFO{Write} = ["function", "boolean"];}
sub Write {

    if (XLib->isInitialized()) {
	return XLib->writeConfiguration ();
    }
    else {
	return 0;
    }
}

42
