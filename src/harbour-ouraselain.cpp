#include <sailfishapp.h>
#include <QtQuick>
#include <QScopedPointer>
#include "ouraCloudApi.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/harbour-oura.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    // Set up qml engine.
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    ouraCloudApi ouraCloud;
    view->engine()->rootContext()->setContextProperty("ouraCloud", &ouraCloud);
    //engine.load(QUrl(QLatin1String(SailfishApp::pathTo("qml/harbour-oura.qml"))));//("qrc:/main.qml")));

    // If you wish to publish your app on the Jolla harbour, follow
    // https://harbour.jolla.com/faq#5.3.0 about naming own QML modules.
    //qmlRegisterType<DemoModel>("com.example", 1, 0, "DemoModel");
    app->setApplicationVersion(APP_VERSION);

    // Start the application.
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
    //return SailfishApp::main(argc, argv);
}
