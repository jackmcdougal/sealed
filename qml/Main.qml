/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * sealed is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4
import "ut_components"
import Qt.labs.platform 1.0 as Platform

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'sealed.brennoflavio'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property string email: ""
    property string password: ""
    property string totp: ""
    property bool isLoggingIn: false
    property string loginMessage: ""
    property bool loginSuccess: false
    property var loginScreenData: null
    property var visibleFields: []
    property bool isCheckingLogin: false

    function checkLoginScreen() {
        isCheckingLogin = true;
        python.call('main.login_screen', [], function (result) {
                loginScreenData = result;
                visibleFields = result.fields || [];
                isCheckingLogin = false;
                if (!result.show) {
                    navigateToPasswordList();
                }
            });
    }

    function navigateToPasswordList() {
        var passwordListPage = pageStack.push(Qt.resolvedUrl("PasswordListPage.qml"));
        passwordListPage.backRequested.connect(function () {
                pageStack.pop();
            });
        passwordListPage.passwordSelected.connect(function (passwordId, passwordName) {
                var detailPage = pageStack.push(Qt.resolvedUrl("PasswordLoginPage.qml"));
                detailPage.passwordData = {
                    "name": passwordName,
                    "folder": "Development",
                    "username": "user@example.com",
                    "password": "••••••••••••",
                    "totp": "123456",
                    "notes": "Account details for " + passwordName,
                    "created": "2024-01-15 10:30:00",
                    "updated": "2025-01-10 14:25:00"
                };
                detailPage.backRequested.connect(function () {
                        pageStack.pop();
                    });
            });
    }

    function performLogin() {
        isLoggingIn = true;
        loginMessage = "";

        // Send empty strings for fields that are not visible
        var emailValue = visibleFields.indexOf("email") !== -1 ? email : "";
        var passwordValue = visibleFields.indexOf("password") !== -1 ? password : "";
        var totpValue = visibleFields.indexOf("totp") !== -1 ? totp : "";
        python.call('main.login', [emailValue, passwordValue, totpValue], function (result) {
                isLoggingIn = false;
                if (result && result.success) {
                    loginSuccess = true;
                    loginMessage = "";
                    navigateToPasswordList();
                } else {
                    loginSuccess = false;
                    loginMessage = result && result.message ? result.message : i18n.tr("Login failed");
                }
            });
    }

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: push(loginPage)

        Page {
            id: loginPage
            visible: false

            header: AppHeader {
                id: loginHeader
                pageTitle: i18n.tr('Sealed')
                isRootPage: true
                appIconName: "lock"
                showSettingsButton: true
                onSettingsClicked: {
                    pageStack.push(Qt.resolvedUrl("ConfigurationPage.qml"));
                }
            }

            Flickable {
                anchors {
                    top: loginHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                contentHeight: loginContent.height + units.gu(4)

                Column {
                    id: loginContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: units.gu(2)
                        topMargin: units.gu(4)
                    }
                    spacing: units.gu(2)

                    Label {
                        text: i18n.tr("Bitwarden Login")
                        fontSize: "large"
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Form {
                        id: loginForm
                        buttonText: i18n.tr("Login")
                        buttonIconName: "lock-broken"
                        enabled: !root.isLoggingIn

                        InputField {
                            id: emailField
                            visible: root.visibleFields.indexOf("email") !== -1
                            title: i18n.tr("Email")
                            placeholder: i18n.tr("Enter your email")
                            text: root.email
                            onTextChanged: root.email = text
                            property bool isValid: root.visibleFields.indexOf("email") === -1 || text.trim() !== ""
                        }

                        InputField {
                            id: passwordField
                            visible: root.visibleFields.indexOf("password") !== -1
                            title: i18n.tr("Password")
                            placeholder: i18n.tr("Enter your password")
                            text: root.password
                            echoMode: TextInput.Password
                            onTextChanged: root.password = text
                            property bool isValid: root.visibleFields.indexOf("password") === -1 || text.trim() !== ""
                        }

                        InputField {
                            id: totpField
                            visible: root.visibleFields.indexOf("totp") !== -1
                            title: i18n.tr("Two-Factor Code - Only Authenticator app is supported")
                            placeholder: i18n.tr("Enter your 2fa code")
                            text: root.totp
                            onTextChanged: root.totp = text
                            property bool isValid: true
                        }

                        onSubmitted: {
                            root.performLogin();
                        }
                    }

                    Label {
                        id: loginMessageLabel
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        text: root.loginMessage
                        color: root.loginSuccess ? theme.palette.normal.positive : theme.palette.normal.negative
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.loginMessage !== ""
                    }
                }
            }

            LoadToast {
                id: loginLoadingToast
                showing: root.isLoggingIn
                message: i18n.tr("Logging in... This may take a few moments")
            }

            LoadToast {
                id: checkingLoginToast
                showing: root.isCheckingLogin
                message: i18n.tr("Checking login status...")
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('main', function () {
                    root.checkLoginScreen();
                });
        }

        onError: {
        }
    }

    Component.onDestruction: {
        python.call('main.cleanup', [], function () {});
    }
}
