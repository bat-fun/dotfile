import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#101012"

    property color accent: config.accent || "#C9363E"
    property color textColor: "#F0EEF0"
    property color mutedColor: "#A7A4AA"
    property color fieldColor: "#222125"
    property string loginUser: userModel.lastUser.length > 0
        ? userModel.lastUser
        : (userModel.count > 0
            ? userModel.data(userModel.index(0, 0), Qt.UserRole + 1)
            : "")
    property string timeText: Qt.formatDateTime(new Date(), "hh:mm")
    property string statusText: "Type your password to continue"

    TextConstants { id: textConstants }

    function submitLogin() {
        if (root.loginUser.length === 0) {
            root.statusText = "No login account is available"
            return
        }
        sddm.login(root.loginUser, password.text, session.index)
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
        opacity: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#5508080A" }
            GradientStop { position: 0.5; color: "#1208080A" }
            GradientStop { position: 1.0; color: "#5508080A" }
        }
    }

    Column {
        id: clockBlock
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: root.height * 0.06
        anchors.leftMargin: root.width * 0.05
        width: 280
        spacing: 4

        Text {
            width: clockBlock.width
            text: root.timeText
            color: root.textColor
            horizontalAlignment: Text.AlignLeft
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 38
            font.weight: Font.Light
        }

        Text {
            width: clockBlock.width
            text: Qt.formatDateTime(new Date(), "dddd  ·  MMMM d")
            color: root.mutedColor
            horizontalAlignment: Text.AlignLeft
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
        }
    }

    Column {
        id: content
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.width * 0.05
        anchors.bottomMargin: root.height * 0.06
        width: Math.min(360, root.width - 32)
        spacing: 0

        Rectangle {
            id: card
            width: parent.width
            height: cardContent.implicitHeight + 38
            radius: 16
            color: "#B8151518"
            border.width: 1
            border.color: "#50FFFFFF"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                height: 2
                radius: 1
                color: root.accent
                opacity: 0.9
            }

            Column {
                id: cardContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 21
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: "#2BC9363E"
                        border.width: 1
                        border.color: "#A6C9363E"

                        Text {
                            anchors.centerIn: parent
                            text: root.loginUser.length > 0
                                ? root.loginUser.charAt(0).toUpperCase()
                                : "?"
                            color: "#FFF0EEF0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: root.loginUser.length > 0
                                ? root.loginUser
                                : "No user selected"
                            color: root.textColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "PASSWORD REQUIRED"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.letterSpacing: 0.8
                        }
                    }
                }

                Rectangle {
                    id: passwordField
                    width: parent.width
                    height: 44
                    radius: 9
                    color: root.fieldColor
                    border.width: 1
                    border.color: password.activeFocus ? root.accent : "#454349"

                    TextInput {
                        id: password
                        anchors.left: parent.left
                        anchors.right: unlockButton.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 15
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.textColor
                        selectionColor: root.accent
                        selectedTextColor: "#FFFFFF"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        echoMode: TextInput.Password
                        activeFocusOnTab: true
                        KeyNavigation.tab: session
                        onAccepted: root.submitLogin()
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        anchors.right: unlockButton.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter password"
                        color: root.mutedColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        visible: password.text.length === 0 && !password.activeFocus
                    }

                    Rectangle {
                        id: unlockButton
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        width: 40
                        radius: 7
                        color: unlockMouse.containsMouse ? "#E15359" : root.accent

                        Text {
                            anchors.centerIn: parent
                            text: "→"
                            color: "white"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: unlockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.submitLogin()
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.statusText
                    color: root.mutedColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#24FFFFFF"
                }

                Row {
                    width: parent.width
                    spacing: 14

                    Column {
                        width: (parent.width - 14) / 2
                        spacing: 6

                        Text {
                            text: "SESSION"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            font.letterSpacing: 0.7
                        }

                        ComboBox {
                            id: session
                            width: parent.width
                            height: 34
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.fieldColor
                            borderColor: "#555158"
                            focusColor: root.accent
                            hoverColor: "#573035"
                            menuColor: "#19181C"
                            textColor: root.textColor
                            arrowColor: root.fieldColor
                            arrowIcon: ""
                            model: sessionModel
                            index: sessionModel.lastIndex
                            KeyNavigation.backtab: password
                            KeyNavigation.tab: layoutBox

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌄"
                                color: root.mutedColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }
                        }
                    }

                    Column {
                        width: (parent.width - 14) / 2
                        spacing: 6

                        Text {
                            text: "KEYBOARD"
                            color: root.mutedColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            font.letterSpacing: 0.7
                        }

                        LayoutBox {
                            id: layoutBox
                            width: parent.width
                            height: 34
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: root.fieldColor
                            borderColor: "#555158"
                            focusColor: root.accent
                            hoverColor: "#573035"
                            menuColor: "#19181C"
                            textColor: root.textColor
                            arrowColor: root.fieldColor
                            arrowIcon: ""
                            rowDelegate: Rectangle {
                                color: "transparent"

                                Image {
                                    id: layoutFlag
                                    width: 22
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    source: "/usr/share/sddm/flags/%1.png".arg(
                                        modelItem ? modelItem.modelData.shortName : "zz"
                                    )
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.left: layoutFlag.right
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    verticalAlignment: Text.AlignVCenter
                                    color: root.textColor
                                    font: layoutBox.font
                                    text: modelItem ? modelItem.modelData.shortName : "zz"
                                }
                            }
                            KeyNavigation.backtab: session
                            KeyNavigation.tab: password

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌄"
                                color: root.mutedColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 24

                    Text {
                        text: "RESTART"
                        color: restartMouse.containsMouse ? root.textColor : root.mutedColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5

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
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5

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

    Component.onCompleted: password.forceActiveFocus()
}