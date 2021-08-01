#include "ouraapi.h"
#include <QJsonParseError>
#include <QJsonValue>
#include <QJsonArray>
#include <QDebug>
#include <QUrlQuery>
#include <QByteArray>
/*
 * reads user records from OuraCloud and from local storage
 * recordings are stored in QJsonArray, where each array item is a day or period summary
 * A - OuraCloud
 * 1. download() - reads OuraCloud
 * 2. processOuraCloud() - checks which summary records the file contains, and reads the array
 * 3. storeRecord() - stores OuraCloud array items and local storage items, removes duplicates
*/
ouraApi::ouraApi(QObject *parent) : QObject(parent)
{
    scheme = "https";
    server = "api.ouraring.com";
    path = "/v1";
    pathActivity = path + "/activity";
    pathBedTimes = path + "/bedtime";
    pathReadiness = path + "/readiness";
    pathSleep = path + "/sleep";
    pathUser = path + "/userinfo";

    keyActivity = "activity";
    keyError = "status";
    keyIdealBedTimes = "ideal_bedtimes";
    keySleep = "sleep";
    keyReadiness = "readiness";
    keySummaryDate = "summary_date";

    dateFormat ="yyyy-MM-dd";

    dateConsidered = QDate::currentDate().addDays(-1);
}

int ouraApi::activity(int year, int month, int day)
{
    QDate date;
    QJsonValue jValue;
    int iDate, result=0;

    if (year == 0 || month == 0 || day == 0) {
        date = QDate::currentDate();
    } else {
        date.setDate(year, month, day);
    }
    //qInfo() << "activity keys: " << userActivity.keys();
    iDate = iSummary(Activity, date);
    if (iDate >= 0) {
        jValue = valueAtI(&userActivityList, iDate, "cal_active");
        if (jValue.isDouble()) {
            result =jValue.toInt();
        }
    }

    return result;
}

int ouraApi::addRecord(ContentType content, QJsonObject newRec)
{
    QJsonValue newVal(newRec);
    if (content == User) {
        userInfo = newRec;
    }
    return addRecord(content, newVal);
}

int ouraApi::addRecord(ContentType content, QJsonValue newRec)
{
    QJsonArray *arr;
    QJsonValue oldRec, newVal, oldVal;
    QString dateNew, dateOld, dateKey, periodKey = "period_id";
    int i, newPeriod=0, oldPeriod=0, newYMDP=0, oldYMDP=0;
    if (content == Activity) {
        arr = &userActivityList;
    } else if (content == BedTimes) {
        arr = &userBedTimesList;
    } else if (content == Readiness) {
        arr = &userReadinessList;
    } else if (content == Sleep) {
        arr = &userSleepList;
    } else {
        return -1;
    }

    if (content == Activity || content == Readiness || content == Sleep) {
        dateKey = keySummaryDate;
    } else if (content == BedTimes) {
        dateKey = "date";
    }

    // calculate the index = date + period_id
    newVal = newRec.toObject().value(dateKey);
    if (newVal.isString()) {
        dateNew = newVal.toString();
    }
    if (content == Readiness || content == Sleep) {
        newVal = newRec.toObject().value(keySummaryDate);
        if (newVal.isDouble()) {
            newPeriod = newVal.toInt();
        }
    }
    newYMDP = yyyymmddpp(dateNew, newPeriod);
    oldYMDP = newYMDP + 1;

    // assume the stored records are from earlier dates than the new record
    i = arr->count();
    while (newYMDP < oldYMDP && i > 0) {
        i--;
        oldRec = arr->at(i);
        oldVal = oldRec.toObject().value(dateKey);
        if (oldVal.isString()) {
            dateOld = oldVal.toString();
        }
        // period_id
        if (content == Readiness || content == Sleep) {
            oldVal = oldRec.toObject().value(periodKey);
            if (oldVal.isDouble()) {
                oldPeriod = oldVal.toInt();
            }
        }
        oldYMDP = yyyymmddpp(dateOld, oldPeriod);
        //if (newYMDP > oldYMDP)
    }
    if (newYMDP > oldYMDP) {
        arr->insert(i + 1, newRec);
    } else if (newYMDP == oldYMDP) {
        // update
        arr->replace(i, newRec);
    } else {
        arr->insert(0, newRec);
    }

    return arr->count();
}

int ouraApi::addRecordList(ContentType content, QJsonArray array)
{
    int i = 0, iN = array.count(), result = 0;
    QJsonValue val;
    while (i < iN) {
        val = array.at(i);
        if (val.isObject()) {
            result += addRecord(content, val);
        } else {
            qInfo() << "Parsing error, array should contain only QObjects.";
        }
        i++;
    }
    return result;
}

double ouraApi::average(QString type, QString key, int year1, int month1, int day1, int days)
{
    // returns the average value of key in the last days - if days = 0, average = day1.key
    // defaults to the last week excluding today
    double result=0;
    QJsonValue jsonVal;
    QDate date(year1, month1, day1);
    ContentType cType;
    int i;

    //qInfo() << "alku average()" << key << day1;

    if (days == -1)
        return 0;

    if (!date.isValid()) { // year == 0
        date = QDate::currentDate().addDays(-1);
    }

    cType = valueType(type);

    for (i=0; i<days; i++) {
        if (cType == Sleep) {
            result += averageSleep(key, date.addDays(-i));
        } else if (cType == Readiness) {
            result += averageReadiness(key, date.addDays(-i));
        } else {
            jsonVal = valueFinder(cType, key, date.addDays(-i));
            result += jsonToDouble(jsonVal);
        }
    }

    //qInfo() << "loppu average()" << key << day1 << result;

    return result/(days + 1);
}

double ouraApi::averageReadiness(QString key, QDate date)
{
    int i, N;
    double result=0;
    QJsonValue jsonVal;

    N = readinessCount(date);
    //qInfo() << "alku averageReadiness()" << key << date << N;

    for (i=iSummary(Readiness, date, 0); i<N; i++) {
        jsonVal = valueReadiness(key, date, i);
        result += jsonToDouble(jsonVal);
    }

    if (N == 0) {
        N = 1;
    }

    //qInfo() << "loppu averageReadiness()" << key << date << result;

    return result/N;
}

double ouraApi::averageSleep(QString key, QDate date)
{
    int i, N;
    double result=0, periodTime, totalTime=0;
    QJsonValue jsonVal;

    //qInfo() << "alku averageSleep()" << key << date;

    N = sleepCount(date);
    for (i=iSummary(Sleep, date, 0); i<N; i++) {
        jsonVal = valueSleep("duration", date, i);
        periodTime = jsonToDouble(jsonVal);
        totalTime += periodTime;
        jsonVal = valueSleep(key, date, i);
        result += jsonToDouble(jsonVal)*periodTime;
    }

    if (totalTime == 0) {
        totalTime = 1;
        if (N > 0) {
            result = result/N;
        } else {
            result = 0;
        }
    }

    //qInfo() << "loppu averageSleep()" << key << date << result;

    return result/totalTime;
}

QJsonValue ouraApi::checkValue(QJsonObject *object, QString key, bool silent)
{
    QJsonValue result = object->value(key);
    if (object->contains(key)) {
        result = object->value(key);
        //qInfo() << "löytyy " << key;
    } else if (!silent){
        qInfo() << "not found" << key << " - " << object->keys();
    }
    return result;
}

/*
QJsonObject ouraApi::convertToObject(QNetworkReply *reply)
{
    QByteArray data;
    QJsonParseError parseError;
    QJsonDocument document;
    QJsonObject result;
    QJsonValue value;
    //qInfo() << "vastaus tullut " << qUtf8Printable(reply->errorString());
    if (reply->error() == QNetworkReply::NoError) {
        data = reply->readAll();
        queryResponse.clear();
        queryResponse.append(data);
        //qInfo() << data;// << " -- " << data.at(0) << " " << data.at(1) << " " << data.at(2) << " " << data.at(3);
        document = QJsonDocument::fromJson(data, &parseError);
        if (parseError.error == QJsonParseError::NoError) {
            result = document.object();
            debug.append("parsing json done");
        } else {
            qInfo() << "parse error:" << parseError.error;
        }
    } else {
        qInfo() << reply->errorString();
        queryResponse.clear();
        queryResponse.append(reply->errorString());
    }
    reply->deleteLater();
    return result;
}
// */

QDate ouraApi::dateAt(ContentType type, int i)
{
    QJsonArray *table;
    QJsonObject daySummary, object;
    QJsonValue result, jValue;
    QString dateString, keyDate;
    QDate dayAtI(0,0,0);

    if (type == Activity) {
        table = &userActivityList;
        keyDate = keySummaryDate;
    } else if (type == Readiness) {
        table = &userReadinessList;
        keyDate = keySummaryDate;
    } else if (type == Sleep) {
        table = &userSleepList;
        keyDate = keySummaryDate;
    } else if (type == BedTimes) {
        table = &userBedTimesList;
        keyDate = "date";
    } else {
        qInfo() << "dateAt() doesn't recognize the summary type" << type;
        return dayAtI;
    }

    if (i >= table->count()) {
        qInfo() << "i" << i << "out of bounds" << table->count() - 1;
        return dayAtI;
    }

    jValue = valueAtI(table, i, keyDate);
    if (jValue.isString()) {
        dateString = jValue.toString();
        dayAtI = QDate::fromString(dateString, dateFormat);
    }

    return dayAtI;
}

bool ouraApi::dateAvailable(QString summaryType, QDate date)
{
    bool result = false;
    if (value(summaryType, keySummaryDate, date) != "-")
        result = true;
    return result;
}

QDate ouraApi::dateChange(int step)
{
    dateConsidered = dateConsidered.addDays(step);
    return dateConsidered;
}

void ouraApi::download(ContentType content)
{
    /*
     * QNetworkRequest request;
     * request.setUrl(QUrl("http://qt-project.org"));
     * request.setRawHeader("User-Agent", "MyOwnBrowser 1.0");
     *
     * QNetworkReply *reply = manager->get(request);
     * connect(reply, SIGNAL(readyRead()), this, SLOT(slotReadyRead()));
     * connect(reply, SIGNAL(error(QNetworkReply::NetworkError)),
     *         this, SLOT(slotError(QNetworkReply::NetworkError)));
     * connect(reply, SIGNAL(sslErrors(QList<QSslError>)),
     *         this, SLOT(slotSslErrors(QList<QSslError>)));
    // */
    QUrl url;
    QUrlQuery query;
    QNetworkRequest request;
    //QNetworkReply *reply;
    QString path;
    url.setScheme(scheme);
    url.setHost(server);
    if (content == Activity) {
        path = pathActivity;
    } else if (content == Readiness) {
        path = pathReadiness;
    } else if (content == Sleep) {
        path = pathSleep;
    } else if (content == User) {
        path = pathUser;
    } else if (content == BedTimes) {
        path = pathBedTimes;
    } else {
        return;
    }
    url.setPath(path);
    if (queryStartDate.year() > 2012 && queryStartDate.isValid()) {
        query.addQueryItem("start", queryStartDate.toString(dateFormat));
    }
    if (queryEndDate.year() > 2012 && queryEndDate.isValid()) {
        query.addQueryItem("end", queryEndDate.toString(dateFormat));
    }
    query.addQueryItem("access_token", userToken);
    url.setQuery(query);
    request.setUrl(url);
    //reply = netManager.get(request);
    //qInfo() << url.path() << query.query();
    /*
    if (content == Activity) {
        netManager.disconnect();
        connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloudActivity(QNetworkReply*)));
    } else if (content == BedTimes) {
        netManager.disconnect();
        connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloudBedTimes(QNetworkReply*)));
    } else if (content == Readiness) {
        netManager.disconnect();
        connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloudReadiness(QNetworkReply*)));
    } else if (content == Sleep) {
        netManager.disconnect();
        connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloudSleep(QNetworkReply*)));
    } else if (content == User) {
        netManager.disconnect();
        connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloudUserInfo(QNetworkReply*)));
    }
    // */
    //netManager.disconnect();
    if (content == Activity) {
        activityReply = netManager.get(request);
        connect(activityReply, SIGNAL(finished()), this, SLOT(fromCloudActivity()));
    } else if (content == Readiness) {
        readinessReply = netManager.get(request);
        connect(readinessReply, SIGNAL(finished()), this, SLOT(fromCloudReadiness()));
    } else if (content == Sleep) {
        sleepReply = netManager.get(request);
        connect(sleepReply, SIGNAL(finished()), this, SLOT(fromCloudSleep()));
    } else if (content == User) {
        userReply = netManager.get(request);
        connect(userReply, SIGNAL(finished()), this, SLOT(fromCloudUserInfo()));
    } else if (content == BedTimes) {
        bedTimesReply = netManager.get(request);
        connect(bedTimesReply, SIGNAL(finished()), this, SLOT(fromCloudBedTimes()));
    }

    // connect(reply, SIGNAL(error(QNetworkReply::NetworkError)),..)
    // connect(reply, SIGNAL(sslErrors(QList<QSslError>)),..)
    //connect(&netManager, SIGNAL(finished(QNetworkReply*)), this, SLOT(fromCloud(QNetworkReply*)));
    //netManager.get(request);
    return;
}

/*
void ouraApi::downloadNext()
{
    if (iDownloads == 0) {
        download(User);
    } else if (iDownloads == 1) {
        download(Activity);
    } else if (iDownloads == 2) {
        download(Readiness);
    } else if (iDownloads == 3) {
        download(Sleep);
    } else if (iDownloads == 4) {
        download(BedTimes);
    }
    iDownloads++;
    return;
}
// */

void ouraApi::downloadOuraCloud()
{
    //iDownloads = 0;
    //downloadNext();
    download(User);
    //download(Activity);
    //download(Readiness);
    //download(Sleep);
    //download(BedTimes);
    return;
}

/*
void ouraApi::downloadMyActivity()
{
    download(Activity);
    return;
}

void ouraApi::downloadMyInfo()
{
    download(User);
    return;
}

void ouraApi::downloadMyReadiness()
{
    download(Readiness);
    return;
}

void ouraApi::downloadMySleep()
{
    download(User);
    return;
} // */

int ouraApi::endHour(QString summaryType)
{
    return endHour(summaryType, dateConsidered);
}

int ouraApi::endHour(QString summaryType, QDate date)
{
    QTime time;
    time = endTime(summaryType, date);
    return time.hour();
}

int ouraApi::endMinute(QString summaryType)
{
    return endMinute(summaryType, dateConsidered);
}

int ouraApi::endMinute(QString summaryType, QDate date)
{
    QTime time;
    time = endTime(summaryType, date);
    return time.minute();
}

QTime ouraApi::endTime(QString summaryType, QDate date)
{
    QString key;
    QDateTime time;
    if (summaryType == keyActivity)
        key.append("day_end");
    else if (summaryType == keySleep)
        key.append("bedtime_end");
    time = QDateTime::fromString(value(summaryType, key, date), Qt::ISODate);
    return time.time();
}

QDate ouraApi::firstDate(int first) // the first or last date in the latest summary reply
{
    QDate date1, date2;
    QJsonValue locVal;
    QJsonArray locArray;
    QJsonObject locObject;
    QString str = "first date from: ";
    /*
    //qInfo() << "a." << userActivity.keys() << "s." << userSleep.keys() << "r." << userReadiness.keys();
    //qInfo() << "a s r " << userActivity.contains(keyActivity) << userSleep.contains(keySleep) << userReadiness.contains(keyReadiness);
    if (userActivityList.count() > 0) {
        if (first < 0) {
            i = locArray.count() + first;
        }
        //qInfo() << "löytyy " + keyActivity;
        locVal = userActivityList.at(i);
        if (locVal.isObject()) {
            locObject = locVal.toObject();
            if (locObject.contains(keySummaryDate)) {
                locVal = locObject.value(keySummaryDate);
                if (locVal.isString()) {
                    date1 = QDate::fromString(locVal.toString(), dateFormat).addDays(-1); // last activity-record is not for a full day
                }
            }
        }
    }
    i = 0;
    if (userSleep.contains(keySleep)) {
        //qInfo() << "löytyy " + keySleep;
        locVal = userSleep.value(keySleep);
        if (locVal.isArray()) {
            locArray = locVal.toArray();
            if (first < 0) {
                i = locArray.count() - 1;
            }
            locVal = locArray[i];
        }
        if (locVal.isObject()) {
            locObject = locVal.toObject();
        }
        if (locObject.contains(keySummaryDate)) {
            locVal = locObject.value(keySummaryDate);
            if (locVal.isString()) {
                date2 = QDate::fromString(locVal.toString(), dateFormat);
                if (date1.daysTo(date2) < 0) {
                    date1 = date2;
                }
            }
        }
    }
    i = 0;
    if (userReadiness.contains(keyReadiness)) {
        //qInfo() << "löytyy " + keyReadiness;
        locVal = userReadiness.value(keyReadiness);
        if (locVal.isArray()) {
            locArray = locVal.toArray();
            if (first < 0) {
                i = locArray.count() - 1;
            }
            locVal = locArray[i];
        }
        if (locVal.isObject()) {
            locObject = locVal.toObject();
        }
        if (locObject.contains(keySummaryDate)) {
            locVal = locObject.value(keySummaryDate);
            if (locVal.isString()) {
                date2 = QDate::fromString(locVal.toString(), dateFormat);
                if (date1.daysTo(date2) < 0) {
                    date1 = date2;
                }
            }
        }
    }
    //qInfo() << date1.toString() << date2.toString();
    // */
    date1 = firstDateIn(Activity, first);
    date2 = firstDateIn(BedTimes, first);
    if (date1.isValid()) {
        str.append("activity ");
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            str.append("bedTimes ");
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Readiness, first);
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            str.append("readiness ");
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Sleep, first);
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            str.append("sleep");
            date1 = date2;
        }
    } else {
        str.append("sleep");
        date1 = date2;
    }
    qInfo() << str << date1.toString(dateFormat);
    return date1;
}

QDate ouraApi::firstDateIn(ContentType type, int first) // the first or last date in the latest summary reply
{
    QDate date1(0,0,0);
    int i, iN;
    QString key;
    QJsonArray *list;
    QJsonObject locObj;
    QJsonValue locVal;

    if (type == Activity) {
        list = &userActivityList;
    } else if (type == Readiness) {
        list = &userReadinessList;
    } else if (type == Sleep) {
        list = &userSleepList;
    } else if (type == BedTimes) {
        list = &userBedTimesList;
    } else {
        qInfo() << "type not recognized in firstDateIn()" << type ;
        return date1;
    }

    iN = list->count();

    if (iN < 1) {
        return date1;
    }

    if (first >= 0) {
        i = first;
        if (i >= iN) i = iN - 1;
    } else {
        i = iN + first;
        if (i < 0) i = 0;
    }
    //qInfo() << "löytyy " + keyActivity;
    date1 = dateAt(type, i);

    return date1;
}

void ouraApi::fromCloudActivity()
{
    QJsonObject cloudJson;
    QJsonValue cloudValue;
    //QJsonArray cloudArray;
    qInfo() << "fromCloudActivity: \n";
    //userActivity = convertToObject(activityReply);
    jsonActivity.clear();
    cloudJson = processCloudResponse(activityReply, &jsonActivity);
    //jsonActivity.append(queryResponse);
    cloudValue = cloudJson.value(keyActivity);
    if ( !cloudValue.isUndefined())
        dateConsidered = lastDate();
    if (cloudValue.isArray()) {
        addRecordList(Activity, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Activity, cloudValue);
    }

    emit finishedActivity();
    //downloadNext();
    download(Readiness);
    return;
}

void ouraApi::fromCloudBedTimes()
{
    QJsonObject cloudJson;
    QJsonValue cloudValue;
    //QJsonArray cloudArray;
    qInfo() << "fromCloudBedTimes: \n";
    //userActivity = convertToObject(activityReply);
    jsonBedTimes.clear();
    cloudJson = processCloudResponse(bedTimesReply, &jsonBedTimes);
    //jsonBedTimes.append(queryResponse);
    cloudValue = cloudJson.value(keyIdealBedTimes);
    if ( !cloudValue.isUndefined())
        dateConsidered = lastDate();
    if (cloudValue.isArray()) {
        addRecordList(BedTimes, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(BedTimes, cloudValue.toObject());
    }
    emit finishedBedTimes();
    //downloadNext();
    return;
}

void ouraApi::fromCloudReadiness()
{
    QJsonObject cloudJson;
    QJsonValue cloudValue;
    QJsonArray cloudArray;
    qInfo() << "fromCloudReadiness: \n";
    //userActivity = convertToObject(activityReply);
    jsonReadiness.clear();
    cloudJson = processCloudResponse(readinessReply, &jsonReadiness);
    //jsonReadiness.append(queryResponse);
    cloudValue = cloudJson.value(keyReadiness);
    if ( !cloudValue.isUndefined())
        dateConsidered = lastDate();
    if (cloudValue.isArray()) {
        addRecordList(Readiness, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Readiness, cloudValue.toObject());
    }
    // read relevant data
    emit finishedReadiness();
    //downloadNext();
    download(Sleep);
    return;
}

void ouraApi::fromCloudSleep()
{
    QJsonObject cloudJson;
    QJsonValue cloudValue;
    QJsonArray cloudArray;
    qInfo() << "fromCloudSleep: \n";
    //userActivity = convertToObject(activityReply);
    jsonSleep.clear();
    cloudJson = processCloudResponse(sleepReply, &jsonSleep);
    //jsonSleep.append(queryResponse);
    cloudValue = cloudJson.value(keySleep);
    if ( !cloudValue.isUndefined())
        dateConsidered = lastDate();
    if (cloudValue.isArray()) {
        addRecordList(Sleep, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Sleep, cloudValue.toObject());
    }
    emit finishedSleep();
    //downloadNext();
    download(BedTimes);
    return;
}

void ouraApi::fromCloudUserInfo()
{
    QJsonObject cloudJson;
    QJsonArray cloudArray;
    qInfo() << "fromCloudUserInfo: \n";
    //userActivity = convertToObject(activityReply);
    jsonInfo.clear();
    cloudJson = processCloudResponse(userReply, &jsonInfo);
    //jsonInfo.append(queryResponse);
    if (!cloudJson.contains(keyError)) {
        addRecord(User, cloudJson);
    }
    emit finishedInfo();
    //downloadNext();
    download(Activity);
    return;
}

/*
void ouraApi::fromCloud(QNetworkReply *reply)
{
    QJsonObject cloudJson;
    QJsonValue cloudValue;
    QJsonArray cloudArray;
    ContentType content;
    // save the *reply, ask for more, convert *reply to jsonDocument,
    // check if it's an error message, check the summary type,
    //qInfo() << "fromCloudActivity: \n";
    //userActivity = convertToObject(reply);
    cloudJson = processCloudResponse(reply);
    if (cloudJson.contains(keyActivity)) {
        content = Activity;
        jsonActivity.clear(); // clear old activity respond file
        jsonActivity.append(queryResponse); // store the new file
        cloudValue = cloudJson.value(keyActivity);
    } else if (cloudJson.contains(keyIdealBedTimes)) {
        content = BedTimes;
        jsonBedTimes.clear(); // clear old activity respond file
        jsonBedTimes.append(queryResponse); // store the new file
        cloudValue = cloudJson.value(keyIdealBedTimes);
    } else if (cloudJson.contains(keyReadiness)) {
        content = Readiness;
        jsonReadiness.clear(); // clear old activity respond file
        jsonReadiness.append(queryResponse); // store the new file
        cloudValue = cloudJson.value(keyReadiness);
    } else if (cloudJson.contains(keySleep)) {
        content = Sleep;
        jsonSleep.clear(); // clear old activity respond file
        jsonSleep.append(queryResponse); // store the new file
        cloudValue = cloudJson.value(keySleep);
    } else if (cloudJson.contains(keyError)) {
        jsonError.clear(); // clear old activity respond file
        jsonError.append(queryResponse); // store the new file
        if (cloudJson.contains("status")) {
            qInfo() << cloudJson.value("status") << ":";
            if (cloudJson.contains("title"))
                qInfo() << cloudJson.value("title");
            if (cloudJson.contains("detail"))
                qInfo() << "\n" << cloudJson.value("detail") << "\n";
        }
    } else {
        content = User;
        jsonInfo.clear(); // clear old activity respond file
        jsonInfo.append(queryResponse); // store the new file
        //cloudValue = cloudJson.value(keyUser);
    }

    dateConsidered = lastDate();
    if (cloudValue.isArray()) {
        addRecordList(content, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(content, cloudValue.toObject());
    }

    if (content == Activity) {
        emit finishedActivity();
    } else if (content == BedTimes) {
        emit finishedBedTimes();
    } else if (content == Readiness) {
        emit finishedReadiness();
    } else if (content == Sleep) {
        emit finishedSleep();
    } else if (content == User) {
        emit finishedInfo();
    }
    downloadNext();
    // read relevant data
    return;
}

void ouraApi::fromCloudReadiness(QNetworkReply *reply)
{
    //qInfo() << "fromCloudReadiness: \n";
    userReadiness = convertToObject(reply);
    jsonReadiness.clear();
    jsonReadiness.append(queryResponse);
    dateConsidered = lastDate();
    // read relevant data
    emit finishedReadiness();
    downloadNext();
    return;
}

void ouraApi::fromCloudSleep(QNetworkReply *reply)
{
    //QJsonValue days;
    //qInfo() << "fromCloudSleep: \n";
    userSleep = convertToObject(reply);
    jsonSleep.clear();
    jsonSleep.append(queryResponse);
    dateConsidered = lastDate();
    // read relevant data
    emit finishedSleep();
    downloadNext();
    return;
}

void ouraApi::fromCloudBedTimes(QNetworkReply *reply)
{
    //qInfo() << "fromCloudBedTimes: \n";
    userBedTimes = convertToObject(reply);
    emit finishedBedTimes();
    downloadNext();
    return;
}

void ouraApi::fromCloudUserInfo(QNetworkReply *reply)
{
    //qInfo() << "fromCloudInfo: \n";
    userInfo = convertToObject(reply);
    jsonInfo.clear();
    jsonInfo.append(queryResponse);
    emit finishedInfo();
    downloadNext();
    return;
}
// */

int ouraApi::fromDB(QString summaryType, QString jsonDb)
{
    QJsonDocument document;
    QJsonParseError parseError;
    int result = -1;

    document = QJsonDocument::fromJson(jsonDb.toLatin1(), &parseError);
    if (parseError.error == QJsonParseError::NoError) {
        if (document.isObject()) {
            result = addRecord(valueType(summaryType), document.object());
        } else if (document.isArray()) {
            result = addRecordList(valueType(summaryType), document.array());
        }
    } else {
        qInfo() << "parse error:" << parseError.error;
    }

    return result;
}

QString ouraApi::getStatus()
{
    //QString result(" " + debug);
    return debug;
}

int ouraApi::iSummary(ContentType type, QDate searchDate, int i0)
{
    // returns the index of the first list item where summary_date == searchDate
    // if i0 == -1, checks that is_longest == 1 also
    // if i0 >= 0, starts at i0
    // *summary - https://cloud.ouraring.com/docs/daily-summaries
    QJsonArray *table;
    QJsonObject daySummary, object;
    QJsonValue result, jValue;
    QString dateString, str(""), keyDate;
    QDate dayAtI;
    int i = 0, iN, iResult = -1, isLongest=-1, daysTo;

    if (type == Activity) {
        table = &userActivityList;
        keyDate = keySummaryDate;
    } else if (type == Readiness) {
        table = &userReadinessList;
        keyDate = keySummaryDate;
    } else if (type == Sleep) {
        table = &userSleepList;
        keyDate = keySummaryDate;
    } else if (type == BedTimes) {
        table = &userBedTimesList;
        keyDate = "date";
    } else {
        return iResult;
    }

    qInfo() << "tyyppi" << type;
    iN = table->count();
    if (iN < 1)
        return iResult;


    if (i0 >= iN) {
        return -i0;
    } else if (i0 > 0) {
        i = i0;
    } else { // estimate the location based on the first and last records
        // one record per day is expected
        dayAtI = dateAt(type, i);
        i = dayAtI.daysTo(searchDate);
        str.append("eka ");
        str.append(dayAtI.toString(dateFormat));
        str.append(" ero ");
        str.append(QString::number(i));

        if (i >= iN) {
            dayAtI = dateAt(type, iN - 1);
            i = iN - searchDate.daysTo(dayAtI);
            str.append(" vika ");
            str.append(dayAtI.toString(dateFormat));
            str.append(" ero ");
            str.append(QString::number(i));
        }

        if (i < 0) {
            i = 0;
        } else if (i >= iN) {
            i = iN -1;
        }

        qInfo() << "haku" << searchDate.toString(dateFormat) << str;
        // go to the last day before the search day
        // dayAtI = summary->at(iN-1) when entering the loop
        dayAtI = dateAt(type, i);
        while (dayAtI.daysTo(searchDate) <= 0 && i > 0) {
            i--;
            dayAtI = dateAt(type, i);
        }

        // go to the first incidence of the search day
        while (dayAtI.daysTo(searchDate) > 0 && i < iN - 1) {
            i++;
            dayAtI = dateAt(type, i);
        }
        qInfo() << "i" << i << iN << dayAtI.toString(dateFormat);
    }

    if (i >= iN) {
        i = iN - 1;
    }

    while (i < iN) {
        // continue loop if daysTo < 0
        qInfo() << "jäsen" << i;
        dayAtI = dateAt(type, i);
        if (type == Readiness || type == Sleep) {
            jValue = valueAtI(table, i, "is_longest");
            if (jValue.isDouble()) {
                isLongest = jValue.toInt();
            } else {
                qInfo() << "is_longest is not a number";
            }
        }

        qInfo() << dayAtI.toString(dateFormat) << "-" << searchDate.toString(dateFormat) << "=" << daysTo << "i0" << i0;
        daysTo = searchDate.daysTo(dayAtI);
        if (daysTo == 0) {
            if (i0 >= 0) {
                iResult = i;
                i = iN + 1;
            } else if (i0 == -1 && isLongest == 1) {
                iResult = i;
                i = iN + 1;
            }
        } else if (daysTo > 0) {
            if (i == 0) {
                iResult = -1;
            } else {
                iResult = -i;
            }
            i = iN + 1;
        }
        i++;
    }

    if (iResult < 0 && (i0 <= 0)) {
        if (i0 == -1) {
            str.append("with is_longest=1");
        }
        qInfo() << searchDate << str << "not found!!" << iN;
    }

    return iResult;
}

/*
int ouraApi::iSummary(QJsonArray *summary, QDate searchDate, int i0)
{
    // returns the index of the first list item where summary_date == searchDate, < 0 if not found
    // if i0 == -1, checks that is_longest == 1 also
    // if i0 >= 0, starts at i0, if i0 >= count returns -i0
    // *summary - https://cloud.ouraring.com/docs/daily-summaries
    int i, iN, iResult = -1, isLongest=-1, daysTo;
    //bool iSet = false;
    QString dateString, str("");
    QJsonValue jValue;
    QJsonObject daySummary;
    QDate dayAtI;

    iN = summary->count();
    if (iN < 1)
        return iResult;


    if (i0 >= iN) {
        return -i0;
    } else if (i0 > 0) {
        i = i0;
    } else {
        // check date of the first and the last record
        // one record per day is expected
        jValue = summary->at(0);
        if (jValue.isObject()) {
            daySummary = jValue.toObject();
            jValue = checkValue(&daySummary, keySummaryDate);
            if (jValue.isString()) {
                dateString = jValue.toString();
                dayAtI = QDate::fromString(dateString, dateFormat);
            }
        }
        i = dayAtI.daysTo(searchDate);
        str.append("eka ");
        str.append(dayAtI.toString(dateFormat));
        str.append(" ero ");
        str.append(QString::number(i));

        if (i >= iN) {
            jValue = summary->at(iN - 1);
            if (jValue.isObject()) {
                daySummary = jValue.toObject();
                jValue = checkValue(&daySummary, keySummaryDate);
                if (jValue.isString()) {
                    dateString = jValue.toString();
                    dayAtI = QDate::fromString(dateString, dateFormat);
                }
            }
            i = iN - searchDate.daysTo(dayAtI);
            str.append(" vika ");
            str.append(dayAtI.toString(dateFormat));
            str.append(" ero ");
            str.append(QString::number(i));
        }

        if (i < 0) {
            i = 0;
        } else if (i >= iN) {
            i = iN -1;
        }

        qInfo() << "haku" << searchDate.toString(dateFormat) << str;
        // go to the last day before the search day
        // dayAtI = summary->at(iN-1) when entering the loop
        while (dayAtI.daysTo(searchDate) <= 0 && i > 0) {
            i--;
            jValue = summary->at(i);
            if (jValue.isObject()) {
                daySummary = jValue.toObject();
                jValue = checkValue(&daySummary, keySummaryDate);
                if (jValue.isString()) {
                    dateString = jValue.toString();
                    dayAtI = QDate::fromString(dateString, dateFormat);
                }
            }
        }

        // go to the first incidence of the search day
        while (dayAtI.daysTo(searchDate) > 0 && i < iN - 1) {
            i++;
            jValue = summary->at(i);
            if (jValue.isObject()) {
                daySummary = jValue.toObject();
                jValue = checkValue(&daySummary, keySummaryDate);
                if (jValue.isString()) {
                    dateString = jValue.toString();
                    dayAtI = QDate::fromString(dateString, dateFormat);
                }
            }
        }
        qInfo() << "i" << i << iN << dayAtI.toString(dateFormat);
    }

    if (i >= iN) {
        i = iN - 1;
    }

    while (i < iN) {
        // continue loop if daysTo < 0
        jValue = summary->at(i);
        if (jValue.isObject()) {
            qInfo() << "jäsen" << i;
            daySummary = jValue.toObject();
            jValue = checkValue(&daySummary, keySummaryDate, false);
            if (jValue.isString()) {
                dateString = jValue.toString();
                //qInfo() << "summary from date" << dateString << ", searching for" << searchDate
                //        << ", diff " << searchDate.daysTo(QDate::fromString(dateString, dateFormat));
                daysTo = searchDate.daysTo(QDate::fromString(dateString, dateFormat));
                qInfo() << dateString << "-" << searchDate.toString(dateFormat) << "=" << daysTo << "i0" << i0;
                if (daysTo == 0) {
                    if (i0 >= 0) {
                        iResult = i;
                        i = iN + 1;
                    } else if (i0 == -1) {
                        jValue = checkValue(&daySummary, "is_longest", false);
                        if (jValue.isDouble()) {
                            isLongest = jValue.toDouble();
                            if (isLongest == 1) {
                                iResult = i;
                                i = iN + 1;
                            }
                        } else if (!jValue.isNull()) {
                            qInfo() << "is_longest not number!!" << dateString;
                        }
                    }
                } else if (daysTo > 0) {
                    if (i == 0) {
                        iResult = -1;
                    } else {
                        iResult = -i;
                    }
                    i = iN + 1;
                }
            } else {
                qInfo() << keySummaryDate << "not string!!";
            }
        } else {
            qInfo() << "summary->at(" << i << ") not object!!";
        }
        i++;
    }

    if (iResult < 0 && (i0 <= 0)) {
        if (i0 == -1) {
            str.append("with is_longest=1");
        }
        qInfo() << searchDate << str << "not found!!" << iN;
    }

    return iResult;
}
// */

double ouraApi::jsonToDouble(QJsonValue val)
{
    double result = 0;
    QString str;

    if (val.isBool()) {
        if (val.toBool())
            result += 1;
    } else if (val.isDouble()) {
        result += val.toDouble();
    } else if (val.isNull()) {
        result += 0;
    } else {
        qInfo() << "cannot convert to double" << qValueToQString(val);
    }

    return result;
}

QDate ouraApi::lastDate()
{
    return firstDate(-1);
}

QString ouraApi::myName(QString def)
{
    QString name(def);
    QJsonValue jValue;
    if (name == "") {
        name.append("name unknown");
    }
    jValue = valueUser("name");
    if (jValue.isNull())
        jValue = valueUser("email");
    if (jValue.isString())
        name = jValue.toString();
    /*
    if (userInfo.contains("name")) {
        jValue = userInfo.value("name");
        if (jValue.isString()) {
            name = jValue.toString();
        }
    } else if (userInfo.contains("email")) {
        jValue = userInfo.value("email");
        if (jValue.isString()) {
            name = jValue.toString();
        }
    } // */
    return name;
}

int ouraApi::periodCount(QString content, QDate date)
{
    ContentType type = User;
    if (content == keySleep)
        type = Sleep;
    else if (content == keyReadiness)
        type = Readiness;
    qInfo() << "periodCount:" << type << content;
    return periodCount(type, date);
}

int ouraApi::periodCount(ContentType type, QDate date)
{
    // returns the number of sleeping periods during the day
    QJsonArray *list; //arr, ;
    QJsonValue val;
    QJsonObject obj;
    QDate itemDate;
    QString str;
    int result = 0, i=0, length = -1;

    if (type == Sleep) {
        list = &userSleepList;
        //val = checkValue(&userSleep, keySleep);
        str.append("Sleep");
    } else if (type == Readiness) {
        list = &userReadinessList;
        //val = checkValue(&userReadiness, keyReadiness);
        str.append("Readiness");
    } else {
        qInfo() << "periodCount: wrong summary type" << type;
        return -1;
    }

    length = list->count(); //records in total
    while (i < length) {
        val = list->at(i);
        if (val.isObject()) {
            obj = val.toObject();
            itemDate = summaryDate(&obj);
            if (itemDate.isValid() && itemDate.daysTo(date) == 0) {
                qInfo() << "found correct date" << date << itemDate << i;
                result++; //sleep records during the day
            }
        }
        if (i == 0) {
            qInfo() << "periodCount:" << itemDate << date;
        }
        i++;
    }
    /*
    if (val.isArray()) {
        arr = val.toArray();
        length = arr.count(); //records in total
        for (i=0; i<length; i++){
            val = arr[i];
            if (val.isObject()) {
                obj = val.toObject();
                itemDate = summaryDate(&obj);
                if (itemDate.isValid() && itemDate.daysTo(date) == 0) {
                    qInfo() << "found correct date" << date << itemDate << i;
                    result++; //sleep records during the day
                }
            }
        }
    } else if (val.isObject()) {
        obj = val.toObject();
        itemDate = summaryDate(&obj);
        if (itemDate.daysTo(date) == 0) {
            result++;
        }
    }
    // */

    if (result == 0)
        qInfo() << str << "no records from" << date.toString(dateFormat) << "records" << length;

    //qInfo() << str << "löytyi" << result << "period_Id:tä" << date.toString(dateFormat);
    return result;
}

QString ouraApi::printActivity()
{
    return jsonActivity;
}

QString ouraApi::printBedTimes()
{
    return jsonBedTimes;
}

QString ouraApi::printInfo()
{
    return jsonInfo;
}

QString ouraApi::printReadiness()
{
    return jsonReadiness;
}

QString ouraApi::printSleep()
{
    return jsonSleep;
}

QJsonObject ouraApi::processCloudResponse(QNetworkReply *reply, QString *jsonStorage)
{
    QByteArray data;
    QJsonParseError parseError;
    QJsonDocument document;
    QJsonObject result;

    if (reply->error() == QNetworkReply::NoError) {
        data = reply->readAll();
        jsonStorage->append(data);
        //queryResponse.clear();
        //queryResponse.append(data);
        //qInfo() << data;// << " -- " << data.at(0) << " " << data.at(1) << " " << data.at(2) << " " << data.at(3);
        document = QJsonDocument::fromJson(data, &parseError);
        if (parseError.error == QJsonParseError::NoError) {
            result = document.object();
            if (result.contains("status")) {
                qInfo() << result.value("status") << ":";
                if (result.contains("title"))
                    qInfo() << result.value("title");
                if (result.contains("detail"))
                    qInfo() << "\n" << result.value("detail") << "\n";
            }
            //debug.clear();
        } else {
            qInfo() << "parse error:" << parseError.errorString() << data;
        }
    } else {
        qInfo() << reply->errorString();
        jsonStorage->append(reply->errorString());
        //queryResponse.clear();
        //queryResponse.append(reply->errorString());
    }
    reply->deleteLater();

    return result;
}

QString ouraApi::qValueToQString(QJsonValue jValue)
{
    QString result("");
    if (jValue.isBool()) {
        if (jValue.toBool()) {
            result.append("true");
        } else {
            result.append("false");
        }
    } else if (jValue.isDouble()) {
        result.setNum(jValue.toDouble());
    } else if (jValue.isString()) {
        result.append(jValue.toString());
    } else if (jValue.isNull()) {
        result.append("null");
    } else if (jValue.isArray()) {
        result.append("array");
    } else if (jValue.isObject()) {
        result.append("object");
    } else {
        result.append("ei mikään");
    }
    return result;
}

int ouraApi::readinessCount(QDate date) {
    return periodCount(Readiness, date);
}

QString ouraApi::setAppAuthority(QString app, QString scrt)
{
    appId = app;
    appSecret = scrt;
    return appId + " " + appSecret;
}

QDate ouraApi::setDateConsidered(QDate date)
{
    dateConsidered = date;
    return dateConsidered;
}

void ouraApi::setEndDate(int year, int month, int day)
{
    queryEndDate.setDate(year, month, day);
}

void ouraApi::setPersonalAccessToken(QString pat)
{
    userToken = pat;
    //qInfo() << "setting token >>" << userToken << "<<";

    return;
}

void ouraApi::setStatus(const QString newStatus)
{
    debug = newStatus;
    return;
}

void ouraApi::setStartDate(int year, int month, int day)
{
    queryStartDate.setDate(year, month, day);
}

/*
QString ouraApi::showResponseText()
{
    return queryResponse;
}
// */

int ouraApi::sleepCount(QDate date) {
    return periodCount(Sleep, date);
}

int ouraApi::startHour(QString summaryType)
{
    return startHour(summaryType, dateConsidered);
}

int ouraApi::startHour(QString summaryType, QDate date)
{
    QTime time;
    time = startTime(summaryType, date);
    return time.hour();
}

int ouraApi::startMinute(QString summaryType)
{
    return startMinute(summaryType, dateConsidered);
}

int ouraApi::startMinute(QString summaryType, QDate date)
{
    QTime time;
    time = startTime(summaryType, date);
    return time.minute();
}

QTime ouraApi::startTime(QString summaryType, QDate date)
{
    QString key;
    QDateTime start;
    if (summaryType == keyActivity)
        key.append("day_start");
    else if (summaryType == keySleep)
        key.append("bedtime_start");
    start = QDateTime::fromString(value(summaryType, key, date), Qt::ISODate);
    return start.time();
}

int ouraApi::storeOldRecords(QString summaryType, QString recordStr)
{
    ContentType ct;
    QJsonDocument jsonDoc;
    int result = -1;

    ct = valueType(summaryType);

    jsonDoc = QJsonDocument::fromJson(recordStr.toUtf8());
    if (jsonDoc.isObject()) {
        result = addRecord(ct, jsonDoc.object());
    } else if (jsonDoc.isArray()) {
        result = addRecordList(ct, jsonDoc.array());
    }

    return result;
}

int ouraApi::storeRecords(QString summaryType, QString jsonString)
{
    // checks whether jsonString is a respond from Oura (has keyword for the summary type)
    // or a local single stored record
    int result = 0;
    ContentType type;
    QJsonArray array;
    QJsonParseError parseError;
    QJsonDocument document;
    QJsonObject object;
    QJsonValue val;
    document = QJsonDocument::fromJson(jsonString.toLatin1(), &parseError);
    if (parseError.error == QJsonParseError::NoError) {
        if (document.isObject()) {
            object = document.object();
            if (object.contains("status")) { // respond from Oura is an error message
                qInfo() << object.value("status") << ":";
                if (object.contains("title"))
                    qInfo() << object.value("title");
                if (object.contains("detail"))
                    qInfo() << "\n" << object.value("detail") << "\n";
            } else {
                if (object.contains(keyActivity)) {
                    type = Activity;
                    val = object.value(keyActivity);
                } else if (object.contains(keyReadiness)) {
                    type = Readiness;
                    val = object.value(keyReadiness);
                } else if (object.contains(keySleep)) {
                    type = Sleep;
                    val = object.value(keySleep);
                } else if (object.contains(keyIdealBedTimes)) {
                    type = BedTimes;
                    val = object.value(keyIdealBedTimes);
                } else {
                    type = valueType(summaryType);
                    val = QJsonValue::fromVariant(object.toVariantMap());
                }
                if (val.isArray()) {
                    result = addRecordList(type, val.toArray());
                } else if (val.isObject()) {
                    result = addRecord(type, val);
                }
            }
        } else
            return -1;
        debug.clear();
    } else {
        qInfo() << "parse error:" << parseError.error;
    }

    return result;
}

QDate ouraApi::summaryDate(QJsonObject *obj) {
    QJsonValue val;
    QDate result(0,0,0);
    val = checkValue(obj, "summary_date");
    if (val.isString()) {
        result.fromString(val.toString(), dateFormat);
    }
    if (!result.isValid())
        qInfo() << "invalid date" << val.toString();
    //else
    //    qInfo() << result.toString(dateFormat);
    return result;
}

QString ouraApi::value(QString summaryType, QString key)
{
    return value(summaryType, key, dateConsidered);
}

QString ouraApi::value(QString summaryType, QString key, int i0)
{
    return value(summaryType, key, dateConsidered, i0);
}

QString ouraApi::value(QString summaryType, QString key, QDate date, int i0)
{
    // i0 start point of search,
    // if i0 = -1, returns the value corresponding to is_longest=1
    // if i0 = -2, returns the sum of the values fullfilling the criteria
    QJsonValue result;
    double dbl = 0;
    bool isTrue = false, doLoop = true;
    int i, count = 0, ind = i0;
    QJsonArray arr;
    QString str("");
    ContentType sType;

    qInfo() << summaryType << key << date.toString(dateFormat) << "i0" << i0;
    sType = valueType(summaryType);
    if (i0 == -2) {
        ind = iSummary(sType, date, 0);
    }
    while (doLoop) { // check for multiple summaries for the same date if i0 = -2
        result = valueFinder(sType, key, date, ind);
        ind++;
        if (result.isBool() && result.toBool()) {
            isTrue = true;
        } else if (result.isDouble()) {
            dbl += result.toDouble();
            str.clear();
            str.append(QString("%1").arg(dbl));
        } else if (result.isString()) {
            if (str.size() > 0)
                str.append(";");
            str.append(result.toString());
        } else if (result.isArray()) {
            arr = result.toArray();
            if (str.size() > 0)
                str.append(",");
            str.append("[");
            for (i = 0; i < arr.size(); i++) {
                result = arr[i];
                if (result.isDouble()) {
                    dbl = result.toDouble();
                    str.append(QString("%1").arg(dbl));
                } else if (result.isString()) {
                    str.append(result.toString());
                } else if (result.isBool()) {
                    if (result.toBool())
                        str.append("true");
                    else
                        str.append("false");
                }
                if (i < arr.size() - 1) {
                    str.append(", ");
                }
            }
            str.append("]");
        }
        if (result.isNull() || result.isUndefined() || i0 > -2 || count++ > 30) {
            doLoop = false;
        }
    }
    if (isTrue) // true if in any of the date summaries the value is true
        str.append("true");
    if (str.size() == 0)
        str.append("-");
    if (count > 30) {
        qInfo() << "oura.value() finds" << sType << key << date.toString(dateFormat) << "more than" << count-1 << "times";
    }
    //qInfo() << "palautuu" << str;
    return str;
}

QJsonValue ouraApi::valueActivity(QString key, QDate date)
{
    return valueFinder(Activity, key, date);
}

QJsonValue ouraApi::valueAtI(QJsonArray *list, int i, QString key)
{
    QJsonValue jValue, result;
    QJsonObject jObject;
    jValue = list->at(i);
    if (jValue.isObject()) {
        jObject = jValue.toObject();
        result = checkValue(&jObject, key);
    } else {
        qInfo() << "arrayList->at(" << i << ") not object!!";
    }
    return result;
}

QJsonValue ouraApi::valueBedTimes(QString key, QDate date)
{
    return valueFinder(BedTimes, key, date);
}

QJsonValue ouraApi::valueFinder(ContentType content, QString key, QDate date, int i0)
{
    // i0 start point of search,
    // if i0 = -1, returns the value corresponding to is_longest=1
    QJsonArray *list;
    //QJsonObject object;
    QJsonValue result;//, jValue;
    //QString type;
    int ind;
    //qInfo() << "aluksi" << content << key << date.toString(dateFormat) << i0;
    if (content == User) {
        result = checkValue(&userInfo, key);
    } else {
        if (content == Activity) {
            list = &userActivityList;
            //type = keyActivity;
        } else if (content == Readiness) {
            list = &userReadinessList;
            //type = keyReadiness;
        } else if (content == Sleep) {
            list = &userSleepList;
            //type = keySleep;
        } else if (content == BedTimes) {
            list = &userBedTimesList;
            //type = keyIdealBedTimes;
        } else {
            return result;
        }

        ind = iSummary(content, date, i0);
        if (ind >= 0) {
            result = valueAtI(list, ind, key);
        }
        //qInfo() << "rivi a " << jValue.type() << key << date.toString(dateFormat) << type;
        //if (jValue.isArray()) {
        //    array = jValue.toArray();
        //    ind = iSummary(list, date, i0);
        //    if (ind >= 0) {
        //        jValue = array[ind];
        //    }
        //}
        //qInfo() << "rivi b " << i << jValue.type() << jValue.isDouble() << jValue.isString() << jValue.isArray() << jValue.isObject();
        //if (jValue.isObject()) {
        //    object = jValue.toObject();
        //    result = checkValue(&object, key); // check date!!
        //}
    }
    //qInfo() << "lopuksi" << content << key << result;
    return result;
}

QJsonValue ouraApi::valueReadiness(QString key, QDate date, int i0)
{
    return valueFinder(Readiness, key, date, i0);
}

QJsonValue ouraApi::valueSleep(QString key, QDate date, int i0)
{
    return valueFinder(Sleep, key, date, i0);
}

ouraApi::ContentType ouraApi::valueType(QString summaryType)
{
    ContentType result;
    if (summaryType.toLower() == "activity") {
        result = Activity;
    } else if (summaryType.toLower() == "readiness") {
        result = Readiness;
    } else if (summaryType.toLower() == "sleep") {
        result = Sleep;
    } else if (summaryType.toLower() == "userinfo") {
        result = User;
    } else if (summaryType.toLower() == "ideal_bedtimes") {
        result = BedTimes;
    } else {
        qInfo() << "unknown datatype:" << summaryType;
        result = TypeError;
    }
    return result;
}

QJsonValue ouraApi::valueUser(QString key)
{
    return valueFinder(User, key);
}

int ouraApi::yyyymmddpp(QString dateStr, int period)
{
    int dd=0, mm=0, yyyy=0, result = 0;
    bool ok;
    yyyy = dateStr.left(4).toInt(&ok);
    if (ok) {
        mm = dateStr.mid(5,2).toInt(&ok,10);
        if (ok) {
            dd = dateStr.mid(8,2).toInt(&ok,10);
        }
    }
    if (ok)
        result = ((yyyy*100 + mm)*100 + dd)*10 + period;
    return result;
}

/*
QString ouraApi::networkErrorTxt(QNetworkReply::NetworkError type)
{
    QString result;
    if (type == QNetworkReply::NetworkError::NoError) {
        result += "no error";
    } else if (type == QNetworkReply::NetworkError::TimeoutError) {
        result += "timeout error";
    } else if (type == QNetworkReply::NetworkError::ProtocolFailure) {
        result += "protocol failure";
    } else if (type == QNetworkReply::NetworkError::ContentGoneError) {
        result += "content gone error";
    } else if (type == QNetworkReply::NetworkError::HostNotFoundError) {
        result += "host not found";
    } else if (type == QNetworkReply::NetworkError::ProxyTimeoutError) {
        result += "proxy timeout error";
    } else if (type == QNetworkReply::NetworkError::UnknownProxyError) {
        result += "unknown proxy error";
    } else if (type == QNetworkReply::NetworkError::ContentReSendError) {
        result += "content resend error";
    } else if (type == QNetworkReply::NetworkError::ProxyNotFoundError) {
        result += "proxy not found";
    } else if (type == QNetworkReply::NetworkError::UnknownServerError) {
        result += "unknown server";
    } else if (type == QNetworkReply::NetworkError::ContentAccessDenied) {
        result += "Content Access Denied";
    } else if (type == QNetworkReply::NetworkError::InternalServerError) {
        result += "Internal Server Error";
    } else if (type == QNetworkReply::NetworkError::UnknownContentError) {
        result += "Unknown Content Error";
    } else if (type == QNetworkReply::NetworkError::UnknownNetworkError) {
        result += "Unknown Network Error";
    } else if (type == QNetworkReply::NetworkError::ContentConflictError) {
        result += "Content Conflict Error";
    } else if (type == QNetworkReply::NetworkError::ContentNotFoundError) {
        result += "Content Not Found Error";
    } else if (type == QNetworkReply::NetworkError::ProtocolUnknownError) {
        result += "Protocol Unknown Error";
    } else if (type == QNetworkReply::NetworkError::InsecureRedirectError) {
        result += "Insecure Redirect Error";
    } else if (type == QNetworkReply::NetworkError::RemoteHostClosedError) {
        result += "Remote Host Closed Error";
    } else if (type == QNetworkReply::NetworkError::TooManyRedirectsError) {
        result += "Too Many Redirects Error";
    } else if (type == QNetworkReply::NetworkError::ConnectionRefusedError) {
        result += "Connection Refused Error";
    } else if (type == QNetworkReply::NetworkError::OperationCanceledError) {
        result += "Operation Canceled Error";
    } else if (type == QNetworkReply::NetworkError::ServiceUnavailableError) {
        result += "Service Unavailable Error";
    } else if (type == QNetworkReply::NetworkError::SslHandshakeFailedError) {
        result += "Ssl Handshake Failed Error";
    } else if (type == QNetworkReply::NetworkError::NetworkSessionFailedError) {
        result += "Network Session Failed Error";
    } else if (type == QNetworkReply::NetworkError::ProxyConnectionClosedError) {
        result += "Proxy Connection Closed Error";
    } else if (type == QNetworkReply::NetworkError::AuthenticationRequiredError) {
        result += "Authentication Required Error";
    } else if (type == QNetworkReply::NetworkError::ProxyConnectionRefusedError) {
        result += "Proxy Connection Refused Error";
    } else if (type == QNetworkReply::NetworkError::OperationNotImplementedError) {
        result += "Operation Not Implemented Error";
    } else if (type == QNetworkReply::NetworkError::TemporaryNetworkFailureError) {
        result += "Temporary Network Failure Error";
    } else if (type == QNetworkReply::NetworkError::ProtocolInvalidOperationError) {
        result += "Protocol Invalid Operation Error";
    } else if (type == QNetworkReply::NetworkError::BackgroundRequestNotAllowedError) {
        result += "Background Request Not Allowed Error";
    } else if (type == QNetworkReply::NetworkError::ProxyAuthenticationRequiredError) {
        result += "Proxy Authentication Required Error";
    } else if (type == QNetworkReply::NetworkError::ContentOperationNotPermittedError) {
        result += "Content Operation Not Permitted Error";
    } else {
        result += "joku NetworkError";
        result += type;
    }
    return result;
}
// */
