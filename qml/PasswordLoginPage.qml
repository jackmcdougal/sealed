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
import io.thp.pyotherside 1.4
import "ut_components"
import "lib"

Page {
    id: passwordLoginPage

    property string loginId: ""
    property string name: ""
    property string username: ""
    property string password: ""
    property string totpSecret: ""
    property string notes: ""
    property string created: ""
    property string updated: ""
    property bool passwordVisible: false
    property bool favorite: false
    property bool isTrashed: false

    signal backRequested

    function copyToClipboard(text, itemName) {
        Clipboard.push(text);
        toast.show(i18n.tr("%1 copied to clipboard").arg(itemName));
    }

    header: AppHeader {
        id: detailHeader
        pageTitle: name
        isRootPage: false
        showSettingsButton: false
    }

    Flickable {
        anchors {
            top: detailHeader.bottom
            left: parent.left
            right: parent.right
            bottom: bottomBar.top
        }
        contentHeight: contentColumn.height + units.gu(4)
        clip: true

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: units.gu(2)
            }
            spacing: units.gu(2)

            ConfigurationGroup {
                title: i18n.tr("Main")

                DetailField {
                    title: i18n.tr("Name")
                    subtitle: name
                    onCopyClicked: copyToClipboard(name, i18n.tr("Name"))
                }
            }

            ConfigurationGroup {
                title: i18n.tr("Credentials")

                DetailField {
                    title: i18n.tr("Username")
                    subtitle: username
                    showDivider: true
                    onCopyClicked: copyToClipboard(username, i18n.tr("Username"))
                }

                DetailField {
                    title: i18n.tr("Password")
                    visibleContent: password
                    showVisibilityToggle: true
                    isContentVisible: passwordLoginPage.passwordVisible
                    showDivider: totpSecret !== ""
                    onVisibilityToggled: passwordLoginPage.passwordVisible = !passwordLoginPage.passwordVisible
                    onCopyClicked: copyToClipboard(password, i18n.tr("Password"))
                }

                DetailField {
                    visible: totpSecret !== ""
                    title: i18n.tr("TOTP")
                    subtitle: i18n.tr("Tap to copy")
                    onCopyClicked: {
                        python.call('main.get_totp', [totpSecret], function (result) {
                                if (result && result.code) {
                                    copyToClipboard(result.code, i18n.tr("TOTP Code"));
                                }
                            });
                    }
                }
            }

            ConfigurationGroup {
                title: i18n.tr("Misc")

                DetailField {
                    title: i18n.tr("Notes")
                    subtitle: notes
                    showDivider: true
                    onCopyClicked: copyToClipboard(notes, i18n.tr("Notes"))
                }

                DetailField {
                    title: i18n.tr("Created")
                    subtitle: created
                    showDivider: true
                    onCopyClicked: copyToClipboard(created, i18n.tr("Created date"))
                }

                DetailField {
                    title: i18n.tr("Updated")
                    subtitle: updated
                    onCopyClicked: copyToClipboard(updated, i18n.tr("Updated date"))
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
            visible: !passwordLoginPage.isTrashed
            iconName: "edit"
            text: i18n.tr("Edit")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("UpsertLoginPage.qml"), {
                        "isEditMode": true,
                        "loginId": passwordLoginPage.loginId || "",
                        "loginName": passwordLoginPage.name,
                        "loginUsername": passwordLoginPage.username,
                        "loginPassword": passwordLoginPage.password,
                        "loginNotes": passwordLoginPage.notes,
                        "loginTotpSecret": passwordLoginPage.totpSecret,
                        "favorite": favorite
                    });
            }
        }

        IconButton {
            visible: !passwordLoginPage.isTrashed
            iconName: "delete"
            text: i18n.tr("Trash")
            onClicked: {
                trashLoadToast.showing = true;
                python.call('main.trash_item', [passwordLoginPage.loginId], function (result) {
                        trashLoadToast.showing = false;
                        pageStack.clear();
                        pageStack.push(Qt.resolvedUrl("PasswordListPage.qml"));
                    });
            }
        }

        IconButton {
            visible: passwordLoginPage.isTrashed
            iconName: "undo"
            text: i18n.tr("Restore")
            onClicked: {
                loadToast.showing = true;
                python.call('main.restore_item', [passwordLoginPage.loginId], function (result) {
                        loadToast.showing = false;
                        pageStack.pop();
                        pageStack.push(Qt.resolvedUrl("PasswordListPage.qml"));
                    });
            }
        }

        IconButton {
            visible: passwordLoginPage.isTrashed
            iconName: "delete"
            text: i18n.tr("Delete")
            onClicked: {
                deleteLoadToast.showing = true;
                python.call('main.delete_item', [passwordLoginPage.loginId], function (result) {
                        deleteLoadToast.showing = false;
                        pageStack.pop();
                        pageStack.push(Qt.resolvedUrl("PasswordListPage.qml"));
                    });
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('main', function () {});
        }

        onError: {
        }
    }

    Toast {
        id: toast
    }

    LoadToast {
        id: loadToast
        message: i18n.tr("Restoring item...")
    }

    LoadToast {
        id: deleteLoadToast
        message: i18n.tr("Deleting item...")
    }

    LoadToast {
        id: trashLoadToast
        message: i18n.tr("Moving to trash...")
    }
}
