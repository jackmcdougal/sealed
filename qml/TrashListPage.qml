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
    id: trashListPage

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
        loadToast.message = i18n.tr("Loading deleted items...");
        python.call('main.list_trash', [], function (result) {
                isLoading = false;
                loadToast.showing = false;
                if (result.success) {
                    passwords = result.items;
                } else {
                    errorMessage = i18n.tr("Failed to load deleted items");
                    passwords = [];
                }
            });
    }

    function copyToClipboard(text, itemName) {
        Clipboard.push(text);
        toast.show(i18n.tr("%1 copied to clipboard").arg(itemName));
    }

    header: AppHeader {
        id: trashHeader
        pageTitle: i18n.tr('Trash')
        isRootPage: false
        appIconName: "delete"
        showSettingsButton: false
    }

    ActionableList {
        id: trashList
        anchors {
            top: trashHeader.bottom
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
        searchPlaceholder: i18n.tr("Search deleted items...")
        searchFields: ["title", "subtitle"]
        emptyMessage: errorMessage !== "" ? errorMessage : i18n.tr("No items in trash")

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
                    trashListPage.copyToClipboard(item.username, i18n.tr("Username"));
                } else {
                    toast.show(i18n.tr("No username"));
                }
            } else if (actionId === "copy-password") {
                if (item.password) {
                    trashListPage.copyToClipboard(item.password, i18n.tr("Password"));
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
                            "favorite": item.favorite || false,
                            "isTrashed": true
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
                            "favorite": item.favorite || false,
                            "isTrashed": true
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
                        trashListPage.loadPasswords();
                    });
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
            errorMessage = i18n.tr("An error occurred");
            isLoading = false;
            loadToast.showing = false;
        }
    }

    Toast {
        id: toast
    }
}
