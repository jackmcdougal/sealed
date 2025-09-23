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
import Lomiri.Components.Popups 1.3
import io.thp.pyotherside 1.4
import "ut_components"
import "lib"

Page {
    id: passwordListPage

    property var passwords: []
    property bool isLoading: false
    property string errorMessage: ""

    signal passwordSelected(string passwordId, string passwordName)
    signal backRequested

    Component.onCompleted: {
        loadPasswords();
    }

    function loadPasswords() {
        isLoading = true;
        errorMessage = "";
        loadToast.showing = true;
        loadToast.message = i18n.tr("Loading passwords...");
        python.call('main.list_items', [], function (result) {
                isLoading = false;
                loadToast.showing = false;
                if (result.success) {
                    passwords = result.items;
                } else {
                    errorMessage = i18n.tr("Failed to load passwords");
                    passwords = [];
                }
            });
    }

    function copyToClipboard(text, itemName) {
        Clipboard.push(text);
        toast.show(i18n.tr("%1 copied to clipboard").arg(itemName));
    }

    header: AppHeader {
        id: passwordHeader
        pageTitle: i18n.tr('Passwords')
        isRootPage: true
        appIconName: "lock"
        showSettingsButton: true
        onSettingsClicked: {
            pageStack.push(Qt.resolvedUrl("ConfigurationPage.qml"));
        }
    }

    ActionableList {
        id: passwordList
        anchors {
            top: passwordHeader.bottom
            topMargin: units.gu(2)
            left: parent.left
            right: parent.right
            bottom: bottomBar.top
        }

        items: passwords.map(function (pwd) {
                var icon = "";
                if (pwd.favorite === true) {
                    icon = "starred";
                } else {
                    var itemType = pwd.item_type || "login";
                    if (itemType === "login") {
                        icon = "stock_key";
                    } else if (itemType === "secure_note") {
                        icon = "note";
                    } else if (itemType === "card") {
                        icon = "tag";
                    } else if (itemType === "identity") {
                        icon = "contact";
                    }
                }
                return {
                    "id": pwd.id,
                    "title": pwd.name,
                    "subtitle": pwd.username || "",
                    "username": pwd.username,
                    "password": pwd.password,
                    "totpSecret": pwd.totp || "",
                    "notes": pwd.notes || "",
                    "created": pwd.created || "",
                    "updated": pwd.updated || "",
                    "item_type": pwd.item_type || "login",
                    "icon": icon,
                    "cardholderName": pwd.cardholder_name || "",
                    "brand": pwd.brand || "",
                    "number": pwd.number || "",
                    "expiryMonth": pwd.expiry_month || "",
                    "expiryYear": pwd.expiry_year || "",
                    "code": pwd.code || "",
                    "favorite": pwd.favorite || false
                };
            })

        showSearchBar: true
        searchPlaceholder: i18n.tr("Search passwords...")
        searchFields: ["title", "subtitle"]
        emptyMessage: errorMessage !== "" ? errorMessage : i18n.tr("No passwords stored")

        itemActions: [{
                "id": "copy-username",
                "iconName": "contact"
            }, {
                "id": "copy-password",
                "iconName": "lock"
            }, {
                "id": "view-details",
                "iconName": "next"
            }]

        onActionTriggered: {
            if (actionId === "copy-username") {
                if (item.username) {
                    passwordListPage.copyToClipboard(item.username, i18n.tr("Username"));
                } else {
                    toast.show(i18n.tr("No username"));
                }
            } else if (actionId === "copy-password") {
                if (item.password) {
                    passwordListPage.copyToClipboard(item.password, i18n.tr("Password"));
                } else {
                    toast.show(i18n.tr("No password"));
                }
            } else if (actionId === "view-details") {
                var itemType = item.item_type || "login";
                if (itemType === "login") {
                    pageStack.push(Qt.resolvedUrl("PasswordLoginPage.qml"), {
                            "loginId": item.id || "",
                            "name": item.title || "",
                            "username": item.username || "",
                            "password": item.password || "",
                            "totpSecret": item.totpSecret || "",
                            "notes": item.notes || "",
                            "created": item.created || "",
                            "updated": item.updated || "",
                            "favorite": item.favorite || false
                        });
                } else if (itemType === "card") {
                    pageStack.push(Qt.resolvedUrl("PasswordCardPage.qml"), {
                            "cardId": item.id || "",
                            "name": item.title || "",
                            "cardholderName": item.cardholderName || "",
                            "brand": item.brand || "",
                            "number": item.number || "",
                            "expiryMonth": item.expiryMonth || "",
                            "expiryYear": item.expiryYear || "",
                            "code": item.code || "",
                            "notes": item.notes || "",
                            "created": item.created || "",
                            "updated": item.updated || "",
                            "favorite": item.favorite || false
                        });
                }
            }
        }
    }

    BottomBar {
        id: bottomBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        IconButton {
            iconName: "reload"
            text: i18n.tr("Refresh")
            onClicked: {
                loadToast.showing = true;
                loadToast.message = i18n.tr("Refreshing...");
                python.call('main.refresh', [], function () {
                        passwordListPage.loadPasswords();
                    });
            }
        }

        IconButton {
            iconName: "add"
            text: i18n.tr("Add")
            onClicked: {
                PopupUtils.open(addEntryDialog);
            }
        }

        IconButton {
            iconName: "delete"
            text: i18n.tr("Trash")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("TrashListPage.qml"));
            }
        }
    }

    Component {
        id: addEntryDialog
        Dialog {
            id: dialogue
            title: i18n.tr("Add New Entry")
            text: i18n.tr("Choose the type of entry you want to add:")

            Column {
                spacing: units.gu(2)
                width: parent.width

                Button {
                    width: parent.width
                    text: i18n.tr("Login")
                    color: theme.palette.normal.positive
                    onClicked: {
                        PopupUtils.close(dialogue);
                        pageStack.push(Qt.resolvedUrl("UpsertLoginPage.qml"));
                    }
                }

                Button {
                    width: parent.width
                    text: i18n.tr("Card")
                    color: theme.palette.normal.positive
                    onClicked: {
                        PopupUtils.close(dialogue);
                        pageStack.push(Qt.resolvedUrl("UpsertCardPage.qml"));
                    }
                }

                Button {
                    width: parent.width
                    text: i18n.tr("Cancel")
                    onClicked: {
                        PopupUtils.close(dialogue);
                    }
                }
            }
        }
    }

    LoadToast {
        id: loadToast
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('main', function () {});
        }

        onError: {
            console.log('Python error: ' + traceback);
            errorMessage = i18n.tr("An error occurred");
            isLoading = false;
            loadToast.showing = false;
        }
    }

    Toast {
        id: toast
    }
}
