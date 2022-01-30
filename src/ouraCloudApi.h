#ifndef OURACLOUDAPI_H
#define OURACLOUDAPI_H
#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
//#include "xhttprequest.h"

class ouraCloudApi : public QObject
{
    Q_OBJECT
public:
    ouraCloudApi(QObject *parent = NULL);
    Q_INVOKABLE int activity(int year=0, int month=0, int day=0);
    Q_INVOKABLE double average(QString type, QString key, int days=7, int year1=0, int month1=0, int day1=0);
    Q_INVOKABLE bool dateAvailable(QString summaryType, QDate date);
    Q_INVOKABLE QDate dateChange(int step = -1);
    Q_INVOKABLE void downloadOuraCloud(QString recordType="");
    Q_INVOKABLE int endHour(QString summaryType);
    Q_INVOKABLE int endHour(QString summaryType, QDate date);
    Q_INVOKABLE int endMinute(QString summaryType);
    Q_INVOKABLE int endMinute(QString summaryType, QDate date);
    Q_INVOKABLE QDate firstDate(QString summaryType, int first=0); // if first < 0 counts from the last
    Q_INVOKABLE QDate firstDate(int first=0); // if first < 0 counts from the last
    Q_INVOKABLE int fromDB(QString summaryType, QString jsonDb);
    Q_INVOKABLE bool isLoading(QString summaryType = ""); // is loading data from Oura Cloud
    Q_INVOKABLE QDate lastDate(int i=0); // usually only activity-data on the latest date
    Q_INVOKABLE QDate lastDate(QString summaryType, int i=0); // usually only activity-data on the latest date
    Q_INVOKABLE QString myName(QString defVal);
    Q_INVOKABLE int numberOfRecords(QString summaryType);
    Q_INVOKABLE int periodCount(QString content, QDate date);
    Q_INVOKABLE QString printActivity();
    Q_INVOKABLE QString printBedTimes();
    Q_INVOKABLE QString printInfo();
    Q_INVOKABLE QString printReadiness();
    Q_INVOKABLE QString printSleep();
    Q_INVOKABLE int readinessCount(QDate date);
    Q_INVOKABLE QJsonObject recordNr(QString summaryType, int i);
    Q_INVOKABLE QDate setDateConsidered(QDate date = QDate(0,0,0)); // if no date, lastDate()-1
    Q_INVOKABLE void setPersonalAccessToken(QString pat);
    Q_INVOKABLE QDate setStartDate(int year=0, int month=0, int day=0);
    Q_INVOKABLE QDate setEndDate(int year=0, int month=0, int day=0);
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
    Q_INVOKABLE int yyyymmddpp(QString dateStr, int period=0);
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
    bool isLoadingActivity = false, isLoadingBedTimes = false, isLoadingInfo = false,
        isLoadingReadiness = false, isLoadingSleep = false;
    //QNetworkRequest request;
    //QUrl url;

    int addRecord(ContentType content, QJsonObject newValue);
    int addRecord(ContentType content, QJsonValue newValue);
    int addRecordList(ContentType content, QJsonArray array);
    double averageSleep(QString key, QDate date);
    double averageReadiness(QString key, QDate date);
    QJsonValue checkValue(QJsonObject *object, QString key);
    QJsonObject convertToObject(QNetworkReply *reply);
    QDate dateAt(ContentType type, int i);
    void download(ContentType content);
    void downloadNext();
    QTime endTime(QString summaryType, QDate date);
    QDate firstDateIn(ContentType type, int first = 0);
    int iSummary(ContentType content, QDate searchDate, int i0=0);
    //int iSummary(QJsonArray *summary, QDate searchDate, int i0=0);
    double jsonToDouble(QJsonValue val);
    int periodCount(ContentType type, QDate date);
    QJsonObject processCloudResponse(QNetworkReply *reply, QString *strStorage);
    QString qValueToQString(QJsonValue value);
    QTime startTime(QString summaryType, QDate date);
    int storeRecords(QString summaryType, QString jsonString); // number of stored records
    QDate summaryDate(QJsonObject *obj);
    QJsonValue valueActivity(QString key, QDate date = QDate::currentDate());
    QJsonValue valueAtI(QJsonArray *list, int i, QString key);
    QJsonValue valueBedTimes(QString key, QDate date = QDate::currentDate());
    QJsonValue valueFinder(ContentType content, QString key, QDate date = QDate::currentDate(), int i0=0);
    QJsonValue valueReadiness(QString key, QDate date = QDate::currentDate(), int i0=0);
    QJsonValue valueSleep(QString key, QDate date = QDate::currentDate(), int i0=-1);
    ContentType valueType(QString summaryType);
    QJsonValue valueUser(QString key);
    //QString networkErrorTxt(QNetworkReply::NetworkError type);
};

#endif // OURACLOUDAPI_H
