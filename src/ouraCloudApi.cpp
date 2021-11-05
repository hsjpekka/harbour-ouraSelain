#include "ouraCloudApi.h"
#include <QJsonParseError>
#include <QJsonValue>
#include <QJsonArray>
#include <QDebug>
#include <QUrlQuery>
#include <QByteArray>

ouraCloudApi::ouraCloudApi(QObject *parent) : QObject(parent)
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

int ouraCloudApi::activity(int year, int month, int day)
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

int ouraCloudApi::addRecord(ContentType content, QJsonObject newRec)
{
    QJsonValue newVal(newRec);
    if (content == User) {
        userInfo = newRec;
    }
    return addRecord(content, newVal);
}

int ouraCloudApi::addRecord(ContentType content, QJsonValue newRec)
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
        newVal = newRec.toObject().value(periodKey);
        if (newVal.isDouble()) {
            newPeriod = newVal.toInt();
        }
    }
    newYMDP = yyyymmddpp(dateNew, newPeriod);
    oldYMDP = newYMDP + 1;

    i = arr->count(); // assume the stored records are from earlier dates than the new record
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
        //qInfo() << "päivittää tiedot" << content << newYMDP;
        arr->replace(i, newRec);
    } else {
        //qInfo() << "uusi kooste" << content << newYMDP;
        arr->insert(0, newRec);
    }

    //qInfo() << dateNew << newYMDP << dateOld << oldYMDP << i;

    return arr->count();
}

int ouraCloudApi::addRecordList(ContentType content, QJsonArray array)
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

double ouraCloudApi::average(QString type, QString key, int days, int year1, int month1, int day1)
{
    // returns the average value of key in the last days
    // defaults to the average of the previous 7 days
    // days = number of days counting backwards from the given date
    double result=0, addition=0;
    QJsonValue jsonVal;
    QDate date(year1, month1, day1);
    ContentType cType;
    int i, missingDays=0;

    cType = valueType(type);

    if (!date.isValid()) { // year == 0
        date = QDate::currentDate().addDays(-1);
        //if (cType == Activity || cType == BedTimes || cType == Readiness || cType == Sleep) {
        //    date = lastDate(cType);
        //}
    }

    if (cType == Activity || cType == BedTimes || cType == Readiness || cType == Sleep) {
        if (firstDateIn(cType).isValid() && firstDateIn(cType).daysTo(date) < days) {
            days = firstDateIn(cType).daysTo(date);
            qInfo() << "Less stored days than requested for averaging" << type << key << "days" << days;
        }
    }

    for (i=0; i<days; i++) {
        if (cType == Sleep) {
            addition = averageSleep(key, date.addDays(-i));
        } else if (cType == Readiness) {
            addition = averageReadiness(key, date.addDays(-i));
        } else {
            jsonVal = valueFinder(cType, key, date.addDays(-i));
            addition = jsonToDouble(jsonVal);
        }

        if (addition == 0) {
            missingDays++;
        }
        result += addition;
    }

    if (missingDays >= days) {
        missingDays = days - 1;
    }

    return result/(days - missingDays);
}

double ouraCloudApi::averageReadiness(QString key, QDate date)
{
    int i, j, N;
    double result=0;
    QJsonValue jsonVal;

    N = readinessCount(date);
    i = iSummary(Readiness, date, 0);
    j = 0;
    //qInfo() << "alku " << key << date << "i=" << i << "N=" << N;

    while (j < N) {
        jsonVal = valueReadiness(key, date, i);
        result += jsonToDouble(jsonVal);
        i++;
        j++;
    }

    if (N == 0) {
        N = 1;
    }

    //qInfo() << "loppu averageReadiness()" << key << date << result;

    return result/N;
}

double ouraCloudApi::averageSleep(QString key, QDate date)
{
    int eka, i, N;
    double result=0, periodTime, totalTime=0;
    bool weightedAverages = false;
    QJsonValue jsonVal;

    //qInfo() << "alku averageSleep()" << key << date;
    if (key == "hr_average" || key == "efficiency" || key == "restless" ||
            key == "breath_average" || key.indexOf("score") >= 0) {
        weightedAverages = true;
    }

    N = sleepCount(date);
    eka = iSummary(Sleep, date, 0);
    for (i=0; i<N; i++) {
        if (weightedAverages) {
            jsonVal = valueAtI(&userSleepList, eka + i, "duration"); //valueSleep("duration", date, i);
            periodTime = jsonToDouble(jsonVal);
            totalTime += periodTime;
        } else {
            periodTime = 1;
        }
        jsonVal = valueAtI(&userSleepList, eka + i, key); //valueSleep(key, date, i);
        result += jsonToDouble(jsonVal)*periodTime;
    }

    if (weightedAverages) {
        if (totalTime == 0) {
            if (N > 0) {
                result = result/N;
            }
        } else {
            result = result/totalTime;
        }
    }

    //qInfo() << "loppu averageSleep()" << date.toString("yyyy-MM-dd") << iSummary(Sleep, date, 0)
    //        << key << result << N << "kok. aika" << totalTime << weightedAverages;

    return result;
}

QJsonValue ouraCloudApi::checkValue(QJsonObject *object, QString key, bool silent)
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

QDate ouraCloudApi::dateAt(ContentType type, int i)
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

bool ouraCloudApi::dateAvailable(QString summaryType, QDate date)
{
    bool result = false;
    if (value(summaryType, keySummaryDate, date) != "-")
        result = true;
    return result;
}

QDate ouraCloudApi::dateChange(int step)
{
    dateConsidered = dateConsidered.addDays(step);
    return dateConsidered;
}

void ouraCloudApi::download(ContentType content)
{
    QUrl url;
    QUrlQuery query;
    QNetworkRequest request;
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

    return;
}

void ouraCloudApi::downloadOuraCloud(QString recordType)
{
    ContentType type = TypeError;
    //iDownloads = 0;
    //downloadNext();
    if (recordType != "") {
        type = valueType(recordType);
        download(type);
        if (type == User) {
            isLoadingInfo = true;
        } else if (type == Activity) {
            isLoadingActivity = true;
        } else if (type == BedTimes) {
            isLoadingBedTimes = true;
        } else if (type == Readiness) {
            isLoadingReadiness = true;
        } else if (type == Sleep) {
            isLoadingSleep = true;
        }
    } else {
        download(User);
        isLoadingInfo = true;
        download(Activity);
        isLoadingActivity = true;
        download(Readiness);
        isLoadingReadiness = true;
        download(Sleep);
        isLoadingSleep = true;
        download(BedTimes);
        isLoadingBedTimes = true;
    }
    return;
}

int ouraCloudApi::endHour(QString summaryType)
{
    return endHour(summaryType, dateConsidered);
}

int ouraCloudApi::endHour(QString summaryType, QDate date)
{
    QTime time;
    time = endTime(summaryType, date);
    return time.hour();
}

int ouraCloudApi::endMinute(QString summaryType)
{
    return endMinute(summaryType, dateConsidered);
}

int ouraCloudApi::endMinute(QString summaryType, QDate date)
{
    QTime time;
    time = endTime(summaryType, date);
    return time.minute();
}

QTime ouraCloudApi::endTime(QString summaryType, QDate date)
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

QDate ouraCloudApi::firstDate(QString summaryType, int first) // the first or last date in the latest summary reply
{
    return firstDateIn(valueType(summaryType), first);
}

QDate ouraCloudApi::firstDate(int first) // the first or last date in the latest summary reply
{
    QDate date1, date2;
    QJsonValue locVal;
    QJsonArray locArray;
    QJsonObject locObject;
    QString str;

    date1 = firstDateIn(Activity, first);
    str.append("Activity " + date1.toString(dateFormat));
    date2 = firstDateIn(BedTimes, first);
    str.append("BedTimes " + date1.toString(dateFormat));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            //str.append("bedTimes ");
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Readiness, first);
    str.append("Readiness " + date1.toString(dateFormat));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            //str.append("readiness ");
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Sleep, first);
    str.append("Sleep " + date1.toString(dateFormat));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) > 0) {
            //str.append("sleep");
            date1 = date2;
        }
    } else {
        //str.append("sleep");
        date1 = date2;
    }
    //qInfo() << str << "valittu" << date1.toString(dateFormat);
    return date1;
}

QDate ouraCloudApi::firstDateIn(ContentType type, int first) // the first or last date in the latest summary reply
{

    QDate date1(0,0,0);
    int i, iN;
    //QString key;
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
        if (i >= iN)
            i = iN - 1;
    } else {
        i = iN + first;
        if (i < 0)
            i = 0;
        //qInfo() << "i" << i << "iN" << iN << "first" << first;
    }
    //qInfo() << "löytyy " + keyActivity;
    date1 = dateAt(type, i);

    return date1;
}

void ouraCloudApi::fromCloudActivity()
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
    if (cloudValue.isArray()) {
        addRecordList(Activity, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Activity, cloudValue);
    }

    if ( !cloudValue.isUndefined()) {
        dateConsidered = lastDate();
    }

    isLoadingActivity = false;
    emit finishedActivity();
    //downloadNext();
    //download(Readiness);
    return;
}

void ouraCloudApi::fromCloudBedTimes()
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
    if (cloudValue.isArray()) {
        addRecordList(BedTimes, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(BedTimes, cloudValue.toObject());
    }

    if ( !cloudValue.isUndefined()) {
        dateConsidered = lastDate();
    }

    isLoadingBedTimes = false;
    emit finishedBedTimes();
    //downloadNext();
    return;
}

void ouraCloudApi::fromCloudReadiness()
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
    if (cloudValue.isArray()) {
        addRecordList(Readiness, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Readiness, cloudValue.toObject());
    }

    if ( !cloudValue.isUndefined()) {
        dateConsidered = lastDate();
    }

    isLoadingReadiness = false;
    emit finishedReadiness();
    //downloadNext();
    //download(Sleep);
    return;
}

void ouraCloudApi::fromCloudSleep()
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
    if (cloudValue.isArray()) {
        addRecordList(Sleep, cloudValue.toArray());
    } else if (cloudValue.isObject() && !cloudJson.contains(keyError)) {
        addRecord(Sleep, cloudValue.toObject());
    }

    if ( !cloudValue.isUndefined()) {
        dateConsidered = lastDate();
    }

    isLoadingSleep = false;
    emit finishedSleep();
    //downloadNext();
    //download(BedTimes);
    return;
}

void ouraCloudApi::fromCloudUserInfo()
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

    isLoadingInfo = false;
    emit finishedInfo();
    //downloadNext();
    //download(Activity);
    return;
}

int ouraCloudApi::fromDB(QString summaryType, QString jsonDb)
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

QString ouraCloudApi::getStatus()
{
    //QString result(" " + debug);
    return debug;
}

bool ouraCloudApi::isLoading(QString summaryType)
{
    ContentType type = TypeError;
    bool result=false;

    if (summaryType == "") {
        result = isLoadingActivity || isLoadingBedTimes || isLoadingInfo || isLoadingReadiness || isLoadingSleep;
    } else {
        type = valueType(summaryType);
        if (type == Activity) {
            result = isLoadingActivity;
        } else if (type == BedTimes) {
            result = isLoadingBedTimes;
        } else if (type == Readiness) {
            result = isLoadingReadiness;
        } else if (type == Sleep) {
            result = isLoadingSleep;
        } else if (type == User) {
            result = isLoadingInfo;
        }
    }

    return result;
}

int ouraCloudApi::iSummary(ContentType type, QDate searchDate, int i0)
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

    //qInfo() << "tyyppi" << type;
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

        if (i >= iN) {
            dayAtI = dateAt(type, iN - 1);
            i = iN - searchDate.daysTo(dayAtI);
        }

        if (i < 0) {
            i = 0;
        } else if (i >= iN) {
            i = iN -1;
        }

        //qInfo() << "haku" << searchDate.toString(dateFormat) << str;
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
        //qInfo() << "i" << i << iN << dayAtI.toString(dateFormat);
    }

    if (i >= iN) {
        i = iN - 1;
    }

    while (i < iN) {
        // continue loop if daysTo < 0
        //qInfo() << "jäsen" << i;
        dayAtI = dateAt(type, i);
        if (type == Sleep) {
            jValue = valueAtI(table, i, "is_longest");
            if (jValue.isDouble()) {
                isLongest = jValue.toInt();
            } else {
                qInfo() << "is_longest is not a number";
            }
        }

        //qInfo() << dayAtI.toString(dateFormat) << "-" << searchDate.toString(dateFormat) << "=" << daysTo << "i0" << i0;
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
        //qInfo() << searchDate << str << "not found!!" << iN;
    }

    return iResult;
}

double ouraCloudApi::jsonToDouble(QJsonValue val)
{
    double result = 0;
    QString str;

    if (val.isBool() && val.toBool()) {
        result = 1;
    } else if (val.isDouble()) {
        result = val.toDouble();
    } else if (val.isNull()) {
        result = 0;
    } else {
        qInfo() << "cannot convert to double" << qValueToQString(val);
    }

    return result;
}

QDate ouraCloudApi::lastDate(QString summaryType, int i)
{
    return firstDateIn(valueType(summaryType), -(i+1));
}

QDate ouraCloudApi::lastDate(int i) // i = 1 == second last date
{
    QDate date1, date2;
    QJsonValue locVal;
    QJsonArray locArray;
    QJsonObject locObject;

    date1 = firstDateIn(Activity, -(i+1));
    date2 = firstDateIn(BedTimes, -(i+1));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) < 0) {
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Readiness, -(i+1));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) < 0) {
            date1 = date2;
        }
    } else {
        date1 = date2;
    }
    date2 = firstDateIn(Sleep, -(i+1));
    if (date1.isValid()) {
        if (date2.isValid() && date2.daysTo(date1) < 0) {
            date1 = date2;
        }
    } else {
        date1 = date2;
    }

    return date1;
}

QString ouraCloudApi::myName(QString defVal)
{
    QString name;
    QJsonValue jValue;
    jValue = valueUser("name");
    if (jValue.isNull())
        jValue = valueUser("email");
    if (jValue.isString())
        name = jValue.toString();
    else
        name = defVal;

    return name;
}

int ouraCloudApi::numberOfRecords(QString summaryType)
{
    ContentType type;
    QJsonArray *table;
    int iResult = 0;

    type = valueType(summaryType);
    if (type == Activity) {
        table = &userActivityList;
    } else if (type == Readiness) {
        table = &userReadinessList;
    } else if (type == Sleep) {
        table = &userSleepList;
    } else if (type == BedTimes) {
        table = &userBedTimesList;
    } else if (type == User) {
        if (userInfo.keys().count() > 0) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return iResult;
    }

    iResult = table->count();

    return iResult;
}

int ouraCloudApi::periodCount(QString content, QDate date)
{
    ContentType type = User;
    if (content == keySleep)
        type = Sleep;
    else if (content == keyReadiness)
        type = Readiness;
    //qInfo() << "periodCount:" << type << content;
    return periodCount(type, date);
}

int ouraCloudApi::periodCount(ContentType type, QDate date)
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
                //qInfo() << "found correct date" << date << itemDate << i;
                result++; //sleep records during the day
            }
        }
        i++;
    }

    if (result == 0)
        qInfo() << str << "no records from" << date.toString(dateFormat) << "records" << length;

    //qInfo() << str << "löytyi" << result << "period_Id:tä" << date.toString(dateFormat);
    return result;
}

QString ouraCloudApi::printActivity()
{
    return jsonActivity;
}

QString ouraCloudApi::printBedTimes()
{
    return jsonBedTimes;
}

QString ouraCloudApi::printInfo()
{
    return jsonInfo;
}

QString ouraCloudApi::printReadiness()
{
    return jsonReadiness;
}

QString ouraCloudApi::printSleep()
{
    return jsonSleep;
}

QJsonObject ouraCloudApi::processCloudResponse(QNetworkReply *reply, QString *jsonStorage)
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

    qInfo() << jsonStorage->left(47);
    return result;
}

QString ouraCloudApi::qValueToQString(QJsonValue jValue)
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

int ouraCloudApi::readinessCount(QDate date) {
    return periodCount(Readiness, date);
}

QJsonObject ouraCloudApi::recordNr(QString summaryType, int i)
{
    ContentType type;
    QJsonArray *array;
    QJsonObject obj;
    QJsonValue jVal;

    type = valueType(summaryType);
    if (type == Activity) {
        array = &userActivityList;
    } else if (type == BedTimes) {
        array = &userBedTimesList;
    } else if (type == Readiness) {
        array = &userReadinessList;
    } else if (type == Sleep) {
        array = &userSleepList;
    } else {
        return obj;
    }

    if (i < 0 || i >= array->count()) {
        return obj;
    }

    jVal = array->at(i);
    if (jVal.isObject()) {
        return jVal.toObject();
    } else {
        return obj;
    }
}

QString ouraCloudApi::setAppAuthority(QString app, QString scrt)
{
    appId = app;
    appSecret = scrt;
    return appId + " " + appSecret;
}

QDate ouraCloudApi::setDateConsidered(QDate date)
{
    if (date.isValid()) {
        dateConsidered = date;
    } else {
        dateConsidered = lastDate(1);
    }
    return dateConsidered;
}

QDate ouraCloudApi::setEndDate(int year, int month, int day)
{
    queryEndDate.setDate(year, month, day);
    return queryEndDate;
}

void ouraCloudApi::setPersonalAccessToken(QString pat)
{
    userToken = pat;
    //qInfo() << "setting token >>" << userToken << "<<";

    return;
}

void ouraCloudApi::setStatus(const QString newStatus)
{
    debug = newStatus;
    return;
}

QDate ouraCloudApi::setStartDate(int year, int month, int day)
{
    queryStartDate.setDate(year, month, day);
    return queryStartDate;
}

int ouraCloudApi::sleepCount(QDate date) {
    return periodCount(Sleep, date);
}

int ouraCloudApi::startHour(QString summaryType)
{
    return startHour(summaryType, dateConsidered);
}

int ouraCloudApi::startHour(QString summaryType, QDate date)
{
    QTime time;
    time = startTime(summaryType, date);
    return time.hour();
}

int ouraCloudApi::startMinute(QString summaryType)
{
    return startMinute(summaryType, dateConsidered);
}

int ouraCloudApi::startMinute(QString summaryType, QDate date)
{
    QTime time;
    time = startTime(summaryType, date);
    return time.minute();
}

QTime ouraCloudApi::startTime(QString summaryType, QDate date)
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

int ouraCloudApi::storeOldRecords(QString summaryType, QString recordStr)
{
    ContentType ct;
    QJsonDocument jsonDoc;
    int result = -1;

    ct = valueType(summaryType);

    //qInfo() << summaryType.left(6).append("..") << recordStr.left(40);

    jsonDoc = QJsonDocument::fromJson(recordStr.toUtf8());
    if (jsonDoc.isObject()) {
        result = addRecord(ct, jsonDoc.object());
    } else if (jsonDoc.isArray()) {
        result = addRecordList(ct, jsonDoc.array());
    }

    return result;
}

int ouraCloudApi::storeRecords(QString summaryType, QString jsonString)
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

QDate ouraCloudApi::summaryDate(QJsonObject *obj) {
    QJsonValue val;
    QDate result(0,0,0);
    val = checkValue(obj, "summary_date");
    if (val.isString()) {
        result = QDate::fromString(val.toString(), dateFormat);
    }
    if (!result.isValid())
        qInfo() << "invalid date" << val.toString() << result.toString(dateFormat);
    //else
    //    qInfo() << result.toString(dateFormat);
    return result;
}

QString ouraCloudApi::value(QString summaryType, QString key)
{
    return value(summaryType, key, dateConsidered);
}

QString ouraCloudApi::value(QString summaryType, QString key, int i0)
{
    return value(summaryType, key, dateConsidered, i0);
}

QString ouraCloudApi::value(QString summaryType, QString key, QDate date, int i0)
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

    //qInfo() << summaryType << key << date.toString(dateFormat) << "i0" << i0;
    sType = valueType(summaryType);
    if (i0 == -2) {
        ind = iSummary(sType, date, 0);
    }
    while (doLoop) { // check for multiple summaries for the same date if i0 = -2
        result = valueFinder(sType, key, date, ind);
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
        ind++;
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

QJsonValue ouraCloudApi::valueActivity(QString key, QDate date)
{
    return valueFinder(Activity, key, date);
}

QJsonValue ouraCloudApi::valueAtI(QJsonArray *list, int i, QString key)
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

QJsonValue ouraCloudApi::valueBedTimes(QString key, QDate date)
{
    return valueFinder(BedTimes, key, date);
}

QJsonValue ouraCloudApi::valueFinder(ContentType content, QString key, QDate date, int i0)
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

QJsonValue ouraCloudApi::valueReadiness(QString key, QDate date, int i0)
{
    return valueFinder(Readiness, key, date, i0);
}

QJsonValue ouraCloudApi::valueSleep(QString key, QDate date, int i0)
{
    return valueFinder(Sleep, key, date, i0);
}

ouraCloudApi::ContentType ouraCloudApi::valueType(QString summaryType)
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

QJsonValue ouraCloudApi::valueUser(QString key)
{
    QJsonValue jValue;
    if (userInfo.contains(key)) {
        jValue = userInfo.value(key);
    }
    return jValue;
}

int ouraCloudApi::yyyymmddpp(QString dateStr, int period)
{ // string format yyyy-mm-dd
    int dd=0, mm=0, yyyy=0, result = 0, i=0, j=0;
    QChar ch('-');
    bool ok;
    i = dateStr.indexOf(ch); // 4
    yyyy = dateStr.left(i).toInt(&ok);
    if (ok) {
        j = dateStr.indexOf(ch, i+1); // 7
        mm = dateStr.mid(i+1,(j-i-1)).toInt(&ok,10);
        if (ok) {
            dd = dateStr.right(dateStr.length()-j-1).toInt(&ok,10);
        }
    }
    if (ok)
        result = ((yyyy*20 + mm)*50 + dd)*100 + period;
    return result;
}
