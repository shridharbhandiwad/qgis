TEMPLATE = app
TARGET = bangalore_map
CONFIG += c++17 release

QT += widgets gui network xml

SOURCES += \
    src/main.cpp \
    src/MainWindow.cpp

HEADERS += \
    src/MainWindow.h

INCLUDEPATH += src

# Try pkg-config for QGIS libs first
CONFIG += link_pkgconfig
PKGCONFIG += qgis_core qgis_gui qgis_analysis

# Fallback if pkg-config entries are missing
isEmpty(PKGCONFIG) {
    message("pkg-config for QGIS not found, using fallback include/lib paths")
    INCLUDEPATH += /usr/include/qgis
    LIBS += -lqgis_gui -lqgis_core -lqgis_analysis
}

# RPATH to common system lib directories (adjust if custom install)
QMAKE_RPATHDIR += /usr/lib /usr/lib/x86_64-linux-gnu

# Define this to reduce virtual overrides issues with older compilers
DEFINES += QT_NO_KEYWORDS

