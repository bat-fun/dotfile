import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#131314"

    property color accent: config.accent || "#C9363E"
    property color textColor: "#ECEBED"
    property color mutedColor: "#AAA8AC"
    property color fieldColor: "#202023"
    property string timeText: Qt.formatDateTime(new Date(), "hh:mm")
    property string statusText: "ENTER YOUR PASSWORD TO CONTINUE"

    TextConstants { id: textConstants }

    function submitLogin() {
        sddm.login(userModel.lastUser, password.text, session.index)
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#10110f"
        opacity: 0.18
    }

    Rectangle {
        id: loginPanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.width < 760 ? root.width : Math.min(420, root.width * 0.34)
        color: "#111113"
        opacity: 0.97

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: root.accent
            opacity: 0.86
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: root.width < 760 ? 24 : 36
            anchors.rightMargin: root.width < 760 ? 24 : 36

            Row {
                id: brandRow
                anchors.top: parent.top
                anchors.topMargin: 36
                spacing: 11

                Rectangle {
                    width: 32
                    height: 32
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: root.accent

                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: root.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: "ARC / NOIR"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "ARCH LINUX  ·  SECURE SESSION"
                        color: root.mutedColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.letterSpacing: 1
                    }
                }
            }

            Text {
                id: clock
                anchors.top: brandRow.bottom
                anchors.topMargin: 42
                text: root.timeText
                color: root.textColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 48
                font.weight: Font.Light
            }

            Text {
                id: dateLabel
                anchors.top: clock.bottom
                anchors.topMargin: 8
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: root.mutedColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
            }

            Column {
                id: form
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: dateLabel.bottom
                anchors.topMargin: 30
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: "#292022"
                        border.width: 1
                        border.color: root.accent

                        Text {
                            anchors.centerIn: parent
                            text: userModel.lastUser.length > 0 ? userModel.lastUser.charAt(0).toUpperCase() : "?"
                            color: root.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: userModel.lastUser.length > 0 ? userModel.lastUser : "Select a user"
                            color: root.textColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "LOCAL ACCOUNT"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.letterSpacing: 0.8
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "PASSWORD"
                        color: root.mutedColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: 4
                        color: root.fieldColor
                        border.width: 1
                        border.color: password.activeFocus ? root.accent : "#41413a"

                        TextInput {
                            id: password
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.textColor
                            selectionColor: root.accent
                            selectedTextColor: "#11120f"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            activeFocusOnTab: true
                            KeyNavigation.backtab: layoutBox
                            KeyNavigation.tab: session
                            onAccepted: root.submitLogin()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter password"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            visible: password.text.length === 0 && !password.activeFocus
                        }
                    }
                }

                Text {
                    id: statusMessage
                    width: parent.width
                    text: root.statusText
                    color: root.mutedColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: loginButton
                    width: parent.width
                    height: 42
                    radius: 4
                    color: loginMouse.containsMouse ? "#E15359" : root.accent
                    focus: true
                    KeyNavigation.backtab: layoutBox
                    Keys.onReturnPressed: root.submitLogin()
                    Keys.onEnterPressed: root.submitLogin()

                    Text {
                        anchors.centerIn: parent
                        text: "UNLOCK  →"
                        color: "#FFFFFF"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: loginMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.submitLogin()
                    }
                }

                Row {
                    width: parent.width
                    spacing: 18

                    Column {
                        width: (parent.width - 18) / 2
                        spacing: 7

                        Text {
                            text: "SESSION"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        ComboBox {
                            id: session
                            width: parent.width
                            height: 32
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            arrowIcon: ""
                            model: sessionModel
                            index: sessionModel.lastIndex
                            KeyNavigation.backtab: password
                            KeyNavigation.tab: layoutBox
                        }
                    }

                    Column {
                        width: (parent.width - 18) / 2
                        spacing: 7

                        Text {
                            text: "KEYBOARD"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        LayoutBox {
                            id: layoutBox
                            width: parent.width
                            height: 32
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            arrowIcon: ""
                            KeyNavigation.backtab: session
                            KeyNavigation.tab: loginButton
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 42
                spacing: 24

                Text {
                    text: "RESTART"
                    color: restartMouse.containsMouse ? root.textColor : root.mutedColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold

                    MouseArea {
                        id: restartMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: sddm.reboot()
                    }
                }

                Text {
                    text: "SHUT DOWN"
                    color: powerMouse.containsMouse ? root.textColor : root.mutedColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.timeText = Qt.formatDateTime(new Date(), "hh:mm")
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            password.text = ""
            root.statusText = textConstants.loginFailed
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.statusText = textConstants.loginSucceeded
        }

        function onInformationMessage(message) {
            root.statusText = message
        }
    }

    Component.onCompleted: {
        password.forceActiveFocus()
    }
}