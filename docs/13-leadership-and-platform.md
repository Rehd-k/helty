# Leadership and platform

These features sit across departments. CMD and CMAC read activity. Chat, help, print, and announcements are available while someone works inside a department.

## CMD (`lib/src/cmd/`)

The command center for `accountType` `cmd`, and the default home for admin and super admin on the hospital product.

`CmdCommandService` GETs the paths in `cmd_endpoints.dart`. `cmd_providers.dart` has one `FutureProvider` per bundle. Models are in `cmd_models.dart`.

| Screen | Bundle |
|---|---|
| `CMDDashboardScreen` | `CmdExecutiveDashboardBundle` from `/cmd/dashboard` |
| `CMDHospitalOverviewScreen` | `CmdHospitalOverview` |
| `CMDFinancialCommandScreen` | `CmdFinancialOverview` |
| `CMDStaffOversightScreen` | Staff oversight |
| `CMDBedsFacilitiesScreen` | `CmdBedsSnapshot` |
| `CMDLabMonitoringScreen` | `CmdLabMonitoring` |
| `CMDAlertsIncidentsScreen` | `CmdIncident` rows |
| `CMDReportsAnalyticsScreen` | Reports |
| `CMDAuditComplianceScreen` | Audit |
| `CMDSystemControlScreen` | System control |
| `CMDCommunicationCenterScreen` | Communications, next to custom patient push |
| `CMDPatientExperienceScreen` | `CmdPatientExperienceOverview` |
| `ConsultingRoomsScreen` | Local consulting-room list. It does not call the command API |

Widgets in the folder (`cmd_async_scaffold.dart`, `cmd_command_header.dart`, `cmd_data_table_box.dart`, oversight header and sidebar) are the command-center chrome. `cmd_overview_metrics.dart` and `cmd_oversight_metrics.dart` derive the figures the cards show. Missing API fields stay as an em dash.

CMD can open the accounts module in a read-only way (`canAccessAccountsModule`). The command screens themselves do not patch encounters or post payments.

The sidebar for this role is `cmdUnifiedMenuItems` / `cmdExecutiveMenuItems` in `home_screen.dart`, shown when `AppModule.administration` is on.

## CMAC (`lib/src/cmac/`)

Clinical management analytics, plus quality and safety records.

Analytics (`CmacAnalyticsService`, `/cmac/analytics`):

| Screen | Response |
|---|---|
| `CmacOverviewScreen` | `CmacOverviewResponse` |
| `CmacInsightsScreen` | Insights |
| `CmacPatientActivityScreen` | Activity |
| `CmacClinicalScreen` | `CmacClinicalResponse` |
| `CmacLaboratoryScreen` | `CmacLaboratoryResponse` |
| `CmacPharmacyScreen` | `CmacPharmacyResponse` |
| `CmacOperationsScreen` | Operations |
| `CmacQualityScreen` | Quality summary |
| `CmacStaffScreen` | Staff |

These screens aggregate. They do not write orders, encounters, or invoices.

Quality and safety (`CmacQualitySafetyService`, `/quality-safety/referrals|complaints|incidents|infections`):

| Screen | Role |
|---|---|
| `CmacQualitySafetyHubScreen` | Launcher |
| List screens per entity | Referrals, complaints, incidents, infections |
| `CmacQualityDetailScreen` | One record. Path `cmac/quality/:entity/:recordId` |

`QualitySafetyRecord` is the shared row. `CmacPatientPickerField` searches the patient registry when a form needs a patient. `cmac_palette.dart` and `cmac_from_json.dart` are local color and parsing helpers. The CMAC menu is `cmacExecutiveMenuItems`.

## Reports (`lib/src/reports/`)

Operational extracts, separate from the accounts financial pack and from the CMD reports screen.

`HospitalReportsHubScreen` can be opened with a preset request type for lab, radiology, or pharmacy. `HospitalReportScreen` runs one extract. `HospitalReportsService` supports ward admissions, requests by ward, discharge history, medical-records attendance, and medical-records admissions, under `/reports/...`, exported as json, csv, or xlsx.

The routes are hospital-only and mapped to `AppModule.medicalRecords`.

## Printing (`lib/src/printing/`)

Client-side documents. Nothing in this folder is an HTTP client.

**PDF themes.** `ReportPdfTheme` with `ClassicNavyTheme`, `CleanClinicalTheme`, `FormalLetterheadTheme`, and `DiagnosticsStripTheme`. `ReportTemplateNotifier` remembers the choice. Startup reads it from SharedPreferences inside `bootstrapHeltyApp`. Letterhead lines and `ORG_LOGO` come from `OrgConfig`.

**PDF builders.**

| File | Document |
|---|---|
| `inpatient_invoice_pdf.dart` | Inpatient bill |
| `lab_order_pdf.dart` | Lab request or result |
| `investigations_report_pdf.dart` | Lab or radiology investigation report |
| `radiology_report_pdf.dart` | Imaging report |
| `radiology_clinical_notes_pdf.dart` | Clinical notes attached to imaging |
| `simple_table_report_pdf.dart` | Generic table export |

**Receipts.** `ReceiptEscposService`, `TransactionReceiptPrinter`, network printer (`escpos_network.dart` with io and stub), and the Windows default raw printer. `receipt_printer_picker_sheet.dart` is the picker.

**IDs.** `printing/core/display_id.dart` formats chart and document numbers on paper.

## Chat (`lib/src/chat/`)

Staff direct messages, plus a pending-orders ticker.

| Piece | Role |
|---|---|
| `StaffChatScreen`, `StaffChatThreadScreen` | Inbox and thread. List and thread bodies can be embedded in the shell side panel |
| `StaffMessagesShellAction` | The shell button |
| `ChatApiService` | `/chat/conversations` and messages. Dio is injected |
| `InternalChatSocket` | Socket.IO presence and new messages |
| `ChatNotificationCoordinator` | Started from `HeltyApp.initState` |
| `ChatLocalNotificationService` | OS notifications via `flutter_local_notifications` |
| `PendingOrdersNotificationService` | Ticker for departmental queues |

Models: `ChatConversationSummary`, `ChatMessage`, `ChatStaffPresence`, `ChatPeerStaff`. Providers: `staff_chat_shell_provider.dart`, `pending_orders_tick_provider.dart`. Routes are shared home children, so every product has chat.

`just_audio` is available for notification sounds. The shell side panel (`desktop_shell_side_panel.dart`, `shell_side_panel_provider.dart`) is where chat can sit beside the page on a wide window.

## Notifications (`lib/src/notifications/`)

| Piece | Role |
|---|---|
| `LocalNotificationPlatformService` | Shows a local notification |
| `NotificationNavigationNotifier` | Routes a notification tap into a page |
| `CustomPatientPushScreen` | CMD sends a title, body, and optional image to the patient app |
| `CustomPushService` | `POST /notifications/custom` |

An empty patient-id list on the custom push means broadcast. Who may send it is `custom_push_permissions.dart`. The route is hospital-only, beside the CMD screens. Staff chat notifications are implemented in `chat/`, not here.

## Help (`lib/src/help/`)

`HelpCenterScreen` and `SupportTicketDetailScreen`. `TicketsApiService` uses `/tickets` with an injected Dio. Models: `SupportTicketSummary`, `SupportTicketDetail`, `TicketMessage`, `TicketRequester`, `TicketAssignment`. A staff picker assigns a ticket. Routes are shared, so help exists on every product.

## Health content (`lib/src/health_content/`)

Admin for the patient app.

| Screen | Content |
|---|---|
| `HealthCampaignsAdminScreen` | Campaigns |
| `HealthNewsAdminScreen` | News articles |

Both use `_HealthContentEditorDialog`. `HealthContentService` lists and writes campaigns and news, unwrapping `items`, `data`, `campaigns`, `news`, or `articles` depending on the payload. Models: `HealthCampaign`, `HealthNewsArticle`, `HealthContentWritePayload`. Hospital only, mapped to `AppModule.medicalRecords`.

## System announcements (`lib/src/system_announcements/`)

`AnnouncementManagementScreen` is the editor. `AnnouncementBannerHost` is mounted from `HomeScreen` and shows `AnnouncementBannerStrip` or `AnnouncementModal` for active items from `/system-announcements/active`. `SystemAnnouncementService` does the admin writes. Dismissal is per device in `AnnouncementDismissalStorage`. The management route is declared with the billing routes and mapped to `AppModule.administration`.

## Super admin hub (`lib/src/ui/super_admin/`)

| Screen | Role |
|---|---|
| `SuperAdminHubScreen` | Tiles for each department the product allows (`allowedHubDepartments`) |
| `SuperAdminStaffListScreen` | Directory |
| `SuperAdminStaffDetailScreen` | One staff record |

The hub uses `initialRouteForRole` when a tile is opened, combined with the preview provider when the super admin wants that department’s menu. `StaffService` is the HTTP client for the directory. The hub also starts a database backup through `DbBackupService` (`POST /admin/db-backups`) after a confirm dialog, and it can open the patient-merge flow.

## Shell pieces that are not a department

| Piece | File | Role |
|---|---|---|
| Home shell | `lib/src/ui/home/home_screen.dart` | Sidebar, preview, nested `AutoRouter` |
| Menu catalogs | `lib/src/ui/home/account_types.dart` | The `MenuItem` lists |
| Side panel | `desktop_shell_side_panel.dart` | Chat and similar tools on a wide layout |
| Clock gate | `lib/src/widgets/clock_sync_gate.dart` | API race and clock skew |
| Update layer | `helty_desktop_update_layer.dart` | Windows App Installer check |
| Notification host | `widgets/notifications/app_notification_host.dart` | In-app toasts |
| Watermark | `watermark_overlay.dart` | Organization mark over content |

## Colors shared by all of the above

`DepartmentColors` and `finance_status_colors.dart` keep a billing screen and a CMD finance card from inventing a second palette. CMAC keeps a local palette file for its own charts. New leadership screens should prefer `ColorScheme` plus `DepartmentColors` so they match the rest of the hospital UI described in [UI conventions](08-ui-conventions.md).
