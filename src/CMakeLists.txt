# src/CMakeLists.txt build configuration
# Created: 5 Nov 2014 2:34:45 pm
#  Author: arobinson

# version (NOTE: these are auto-updated so DO NOT EDIT, not even spaces)
set (MYAPP_VERSION_MAJOR 0)
set (MYAPP_VERSION_MINOR 1)
set (MYAPP_VERSION_PATCH 0)
set (MYAPP_VERSION_LABEL "-beta3")
set (MYAPP_VERSION_DATE "2015-03-31")
# end autoupdates


# install files/targets
INSTALL(
	FILES 
		version.h
		
	DESTINATION 
		include
	)
