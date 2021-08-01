#ifndef OURAAPI_H
#define OURAAPI_H
#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
//#include "xhttprequest.h"

class ouraApi : public QObject
{
    Q_OBJECT
public:
    ouraApi(QObject *parent = NULL);
    Q_INVOKABLE int activity(int year=0, int month=0, int day=0);
    Q_INVOKABLE double average(QString type, QString key, int year1=0, int month1=0, int day1=0, int days=7);
    Q_INVOKABLE bool dateAvailable(QString summaryType, QDate date);
    Q_INVOKABLE QDate dateChange(int step = -1);
    Q_INVOKABLE int endHour(QString summaryType);
    Q_INVOKABLE int endHour(QString summaryType, QDate date);
    Q_INVOKABLE int endMinute(QString summaryType);
    Q_INVOKABLE int endMinute(QString summaryType, QDate date);
    Q_INVOKABLE QDate firstDate(int first=0); // if first < 0 counts from the last
    Q_INVOKABLE int fromDB(QString summaryType, QString jsonDb);
    Q_INVOKABLE QDate lastDate();
    Q_INVOKABLE QString myName(QString def = "");
    Q_INVOKABLE int periodCount(QString content, QDate date);
    Q_INVOKABLE QString printActivity();
    Q_INVOKABLE QString printBedTimes();
    Q_INVOKABLE QString printInfo();
    Q_INVOKABLE QString printReadiness();
    Q_INVOKABLE QString printSleep();
    Q_INVOKABLE int readinessCount(QDate date);
    Q_INVOKABLE void downloadOuraCloud();
    Q_INVOKABLE QDate setDateConsidered(QDate date);
    Q_INVOKABLE void setPersonalAccessToken(QString pat);
    Q_INVOKABLE void setStartDate(int year=0, int month=0, int day=0);
    Q_INVOKABLE void setEndDate(int year=0, int month=0, int day=0);
    Q_INVOKABLE int sleepCount(QDate date);
    //Q_INVOKABLE QString showResponseText();
    Q_INVOKABLE int startHour(QString summaryType);
    Q_INVOKABLE int startHour(QString summaryType, QDate date);
    Q_INVOKABLE int startMinute(QString summaryType);
    Q_INVOKABLE int startMinute(QString summaryType, QDate date);
    Q_INVOKABLE int storeOldRecords(QString summaryType, QString record);
    Q_INVOKABLE QString value(QString summaryType, QString key);
    Q_INVOKABLE QString value(QString summaryType, QString key, int i0);
    Q_INVOKABLE QString value(QString summaryType, QString key, QDate date, int i0=0);
    enum ContentType {Activity, BedTimes, Readiness, Sleep, User, TypeError};
    Q_ENUM(ContentType)
    QString getStatus(); // turha
    void    setStatus(const QString newStatus); // turha
    //QDateTime readTime(); // timeNow
    //void setTime(const QDateTime newNow);
    QString setAppAuthority(QString app, QString scrt);
    //int     setId(QString id);
signals:
    //void finishedDownloads();
    void finishedActivity();
    void finishedBedTimes();
    void finishedInfo();
    void finishedReadiness();
    void finishedSleep();
private slots:
    //void fromCloud(QNetworkReply *reply);
    void fromCloudActivity();
    void fromCloudBedTimes();
    void fromCloudReadiness();
    void fromCloudSleep();
    void fromCloudUserInfo();
private:
    QString appId, appSecret, userToken;
    QString scheme, server, path, urlAuth, pathActivity, pathBedTimes, pathReadiness, pathSleep, pathUser;
    QString keyActivity, keyError, keyIdealBedTimes, keySleep, keyReadiness, keySummaryDate, keyUser;
    QString dateFormat, jsonActivity, jsonBedTimes, jsonError, jsonInfo, jsonReadiness, jsonSleep;
    QString debug, queryResponse;
    QJsonObject errorInfo, userInfo;//, userActivity, userReadiness, userSleep, userBedTimes; // api response -> object
    QJsonArray userActivityList, userReadinessList, userSleepList, userBedTimesList; // api response -> object
    //int iDownloads;
    QDate dateConsidered, lastFullDate, queryEndDate, queryStartDate;
    //int iConsidered;
    QDateTime timeNow; // the reference time for ouraApi
    //XhttpRequest xhttp;
    QNetworkAccessManager netManager;
    QNetworkReply *activityReply, *bedTimesReply, *readinessReply, *sleepReply, *userReply;
    //QNetworkRequest request;
    //QUrl url;
    void download(ContentType content);
    void downloadNext();

    int addRecord(ContentType content, QJsonObject newValue);
    int addRecord(ContentType content, QJsonValue newValue);
    int addRecordList(ContentType content, QJsonArray array);
    double averageSleep(QString key, QDate date);
    double averageReadiness(QString key, QDate date);
    QJsonValue checkValue(QJsonObject *object, QString key, bool silent=false);
    QJsonObject convertToObject(QNetworkReply *reply);
    QDate dateAt(ContentType type, int i);
    QTime endTime(QString summaryType, QDate date);
    QDate firstDateIn(ContentType type, int first = 0);
    int iSummary(ContentType content, QDate searchDate, int i0=0);
    //int iSummary(QJsonArray *summary, QDate searchDate, int i0=0);
    double jsonToDouble(QJsonValue val);
    QString qValueToQString(QJsonValue value);
    QDate summaryDate(QJsonObject *obj);
    QTime startTime(QString summaryType, QDate date);
    int periodCount(ContentType type, QDate date);
    QJsonValue valueAtI(QJsonArray *list, int i, QString key);
    QJsonObject processCloudResponse(QNetworkReply *reply, QString *strStorage);
    int storeRecords(QString summaryType, QString jsonString); // number of stored records
    QJsonValue valueActivity(QString key, QDate date = QDate::currentDate());
    QJsonValue valueBedTimes(QString key, QDate date = QDate::currentDate());
    QJsonValue valueFinder(ContentType content, QString key, QDate date = QDate::currentDate(), int i0=0);
    QJsonValue valueReadiness(QString key, QDate date = QDate::currentDate(), int i0=0);
    QJsonValue valueSleep(QString key, QDate date = QDate::currentDate(), int i0=-1);
    ContentType valueType(QString summaryType);
    QJsonValue valueUser(QString key);
    int yyyymmddpp(QString dateStr, int period);
    //QString networkErrorTxt(QNetworkReply::NetworkError type);
};

#endif // OURAAPI_H
