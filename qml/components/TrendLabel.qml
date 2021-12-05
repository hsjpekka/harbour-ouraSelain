import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/scripts.js" as Scripts

Item {
    id: root
    width: implicitWidth
    height: implicitHeight
    implicitWidth: layout === layRow? title.width + valStr.width + icon.width + 2*_hgap :
                        layout === layCol? (title.width > valStr.width? title.width : valStr.width) :
                            title.width > (valStr.width + _hgap + icon.width)? title.width : valStr.width + _hgap + icon.width
    implicitHeight: layout === layRow? title.height:
                                       layout === layCol? title.height + valStr.height + icon.width + 2*_vgap :
                                           title.height + valStr.height + _vgap

    property alias  text: title.text

    property int    average: 0
    property real   factor: 1.2
    property int    fontSize: Theme.fontSizeSmall
    property bool   isValid: true
    property int    score: 0
    property string layout: layCompact
    readonly property string layCol: "column"
    readonly property string layRow: "row"
    readonly property string layCompact: "compact"
    property int    _vgap: Theme.paddingSmall
    property int    _hgap: Theme.paddingMedium

    Label {
        id: title
        text: qsTr("score")
        color: Theme.secondaryHighlightColor
        font.pixelSize: fontSize
        x: 0
        y: 0
    }

    Label {
        id: valStr
        text: isValid? score : "-"
        color: Theme.highlightColor
        font.pixelSize: fontSize
        x: layout === layRow?
               title.x + _hgap : (layout === layCol?
                    title.x + 0.5*(title.width - width) :
                    title.x + 0.5*(title.width -
                                   (width + _hgap + icon.width)))
        y: layout === layRow ? 0 : title.height + _vgap
    }

    Icon {
        id: icon
        source: score === average? "image://theme/icon-s-asterisk" :
                                   "image://theme/icon-s-arrow"
        rotation: score > average? 180 : 0
        color: (score > average*factor || score < average/factor) ?
                   Theme.primaryColor : Theme.highlightColor
        visible: isValid
        x: layout === layCol? title.x + 0.5*(title.width - width) :
                                    valStr.x + valStr.width + _hgap + 0.5*width
        y: layout === layCol? valStr.y + valStr.height + _vgap :
                              valStr.y
    }

    Rectangle {
        anchors.fill: parent
        color: parent.z === 0? "transparent" : Theme.backgroundGlowColor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (parent.z === 0) {
                parent.z = 1;
            } else {
                parent.z = 0;
            }
        }
    }
}
