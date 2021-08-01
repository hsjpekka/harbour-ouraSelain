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
TARGET = harbour-ouraselain

VERSION = 0.1.0

DEFINES += APP_VERSION=\\\"$$VERSION\\\"

CONFIG += sailfishapp

QT += network sql

SOURCES += \
    src/harbour-ouraselain.cpp \
    src/ouraapi.cpp

DISTFILES += \
    harbour-ouraselain.desktop \
    qml/harbour-ouraselain.qml \
    qml/components/BarChart.qml \
    qml/components/ModExpandingSection.qml \
    qml/cover/CoverPage.qml \
    qml/pages/activityPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/Info.qml \
    qml/pages/readinessPage.qml \
    qml/pages/Settings.qml \
    qml/pages/sleepPage.qml \
    rpm/harbour-ouraselain.changes \
    rpm/harbour-ouraselain.changes.run.in \
    rpm/harbour-ouraselain.spec \
    rpm/harbour-ouraselain.yaml \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-ouraselain-fi.ts

HEADERS += \
    src/ouraapi.h
