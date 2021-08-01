# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-ouraSelain

VERSION = 1.0.0

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

CONFIG += sailfishapp

QT += network sql

SOURCES += \
    src/harbour-ouraSelain.cpp \
    src/ouraapi.cpp

DISTFILES += \
    harbour-ouraSelain.desktop \
    qml/cover/CoverPage.qml \
    qml/harbour-ouraSelain.qml \
    qml/pages/FirstPage.qml \
    qml/components/BarChart.qml \
    qml/pages/Info.qml \
    rpm/harbour-ouraSelain.changes \
    rpm/harbour-ouraSelain.changes.run.in \
    rpm/harbour-ouraSelain.spec \
    rpm/harbour-ouraSelain.yaml \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-oura-de.ts

HEADERS += \
    src/ouraapi.h
