# Clinical modules

Read [Patient journey](09-patient-journey.md) first for the order of operations. This chapter is the map of each clinical folder: what it is for, the screens, and the API it calls.

Shared chart APIs live in `lib/src/services/` and `lib/src/models/`, not inside the feature folder.

## Patients (`lib/src/paitients/`)

The registry. The directory name is `paitients`; types are `Patient`, `PatientService`, `PatientNotifier`.

| Piece | Role |
|---|---|
| `PatientListScreen`, `PatientFormScreen` | Search and edit |
| `NewPatientScreen` in `view_waiting_patient.dart` | Create, including a waiting-patient handoff |
| `LinkOneTimePatientScreen` | Bind a temporary registration to a full chart |
| `MergePatientsDialog` | Collapse duplicates |
| `PatientService` | `/patients`, registered-today, consultation credits, similar matches, merge, no-ID create |
| `patient_providers.dart` | `patientServiceProvider`, `patientProvider` |

Models include `Patient`, `PatientAllergyEntry`, `NoIdPatient`, `RegisteredTodayResponse`.

## Front desk (`lib/src/frontdesk/`)

Reception home, check-in, and patient-app access.

| Screen | Role |
|---|---|
| `FrontDeskDashboardScreen` | Desk summary. Numbers come from `FrontdeskDashboardService` |
| `CheckInPatientDialog` | Paid invoice without an encounter → `WaitingPatientService` |
| `PatientDevicesScreen`, `PendingDeviceApprovalsScreen`, `FamilyLinksScreen` | `PatientAccessService` |

Dashboard model types live in `lib/src/models/frontdesk_dashboard_models.dart`. Device rows and family-child rows live beside the access feature.

Check-in is the step before the walk-in queue. It does not open an encounter.

## Doctors (`lib/src/doctor/`)

Physician worklists and the live chart.

| Screen | Role |
|---|---|
| `DoctorWalkInQueueScreen` | Queue. Starts `POST /encounters/outpatient/start` |
| `DoctorWaitingPatientsScreen` | Same start path from the waiting list |
| `DoctorOutpatientListScreen` | Physician home |
| `DoctorOngoingEncountersScreen` | Encounters still open |
| `DoctorCompletedEncountersScreen` | Finished encounters |
| `DoctorEncounterViewScreen` | The editable chart |
| `DoctorCompletedEncounterViewScreen` | The read view |
| `WardRoundsScreen` | Admissions plus `WardRoundNoteService` |
| `EncounterSpecialtyGate`, `EncounterSpecialtyFormsPanel` | Specialty questionnaires |
| `doctor/templates/` | Save and apply encounter templates |
| `DoctorEmergencyStartScreen` | Redirects into ED registration |
| `DoctorProfileScreen` | The signed-in doctor’s profile |

`EncounterService` is the chart client: get, patch, diagnoses, complete, follow-up, edit history, outpatient start. `ClinicalSpecialtyService` loads the section catalog. `Icd10Service` searches diagnosis codes. Question definitions live in `doctor/encounter/questionnaire/encounter_question_models.dart`. The operative-note compiler in that folder turns a structured questionnaire into narrative for theatre notes. It has a unit test.

`EncounterScope` is how a tab knows `encounterId`, `patientId`, whether amend mode is on, and whether this is an emergency visit. Tabs should read that scope instead of taking a second copy of the ids from a global provider.

## Nurses (`lib/src/nurses/` and `lib/src/nursing/`)

`nurses/` is the bedside UI. `nursing/` is the roster API.

| Screen | Role |
|---|---|
| `NursesDashboardScreen` | Home. Uses `nursingBootstrapProvider` |
| `WaitingPatientsScreen` | Outpatient nursing queue |
| `NurseConsumableUsageScreen` | Bedside stock usage |
| `InpatientsListScreen` | Ward census |
| `AwaitingNursesClearanceScreen` | Stays waiting for nursing discharge clearance |
| `InpatientPatientViewScreen` | Inpatient chart shell |
| `NursingRosterScreen`, `NursingAssignmentsScreen` | Shifts and assignments |

Inpatient tabs and the services they call:

| Tab | Service |
|---|---|
| Overview | Admission and patient |
| Vitals | `WaitingPatientService` / patient vitals endpoints |
| Medications | `MedicationAdministrationService`, `MedicationOrderService`, `MedicationRequestService` |
| IV | `IvFluidOrderService` |
| Intake and output | `IntakeOutputService` |
| Nursing report | `NursingNoteService` |
| Wound | `WoundAssessmentService` |
| Ward round | `WardRoundNoteService` |
| Procedures | `ProcedureRecordService` |
| Consumables | Store and invoice consumable helpers. This tab is UI-only and is not its own route |
| Care plan | `CarePlanService` |
| Monitoring | `MonitoringChartService` |
| Lab results | Lab orders |
| Imaging | Radiology orders |
| Alerts | `AdmissionAlertService` |
| Handover | `HandoverReportService` |

`NursingApiService` methods cover `GET /nurses/dashboard/me`, role overviews, rosters, and inpatient and outpatient assignments. Models in `nursing_models.dart` include `NursingDashboardMe`, `NursingRosterEntry`, `InpatientNurseAssignment`, `OutpatientNurseAssignment`. `ward_matching.dart` maps a charge-nurse role to emergency, OPD, or obstetrics.

Dose timing shared with prescribing is `lib/src/medications/rx_schedule_utils.dart` (`RxFrequency`, duration units, quantity, next due). There is no separate medications screen module.

## Emergency (`lib/src/emergency/`)

| Screen | Role |
|---|---|
| `EdBoardScreen` | Live board |
| `EdRegistrationScreen` | Creates the visit |
| `EdTriageScreen` | Triage |
| `EdEmergencyRequestsScreen`, `EdEmergencyRequestDetailScreen` | Inbound request inbox |

`EmergencyService` handles visits, disposition, admit, the clinical file, and the specialty modules `em.triage` and `em.disposition`. `EmergencyRequestService` is the inbox. `EncountersNursingService` writes monitoring, nursing notes, and medication administrations from the ED context.

Models: `EmergencyVisitModel`, `EdAdmitPayload`, `EdDispositionPayload`, `StaffEmergencyRequest`, and the enums `EdWorkflowStatus`, `EdArrivalMode`, `EdDisposition`.

Workflow statuses: registered, triage, waiting doctor, in treatment, disposition pending, discharged, transferred, admitted, left without being seen, deceased, cancelled.

## Admissions (`lib/src/admissions/`)

This folder is shared discharge UI, not a census. The census is the inpatient list, ward rounds, and billing ward inpatients.

| File | Role |
|---|---|
| `discharge_admission_dialog.dart` | `DischargeAdmissionPayload` |
| `discharge_summary_dialog.dart` | Summary text |
| `admission_discharge_helpers.dart` | `performClinicalDischarge`, `resolveActiveAdmissionId` |
| `admission_ward_location_section.dart` | Ward and bed picker |

`AdmissionService` does `POST` and `PATCH /admissions`, discharge, and both clearance queues. `AdmissionModel` is the stay.

A clinical discharge can stop in `PENDING_BILLING_CLEARANCE` until billing and then nursing clear it.

## Obstetrics (`lib/src/obstetrics/`)

Base path `/obstetrics`.

Screens: dashboard, patient select, pregnancies list, pregnancy view, labour view, postnatal list, gynaecology procedures, plus add and edit forms for pregnancy, antenatal visit, labour, partogram entry, baby, postnatal visit, and gynae procedure. `ObstetricsRegisterBabyScreen` creates a `Patient` for the newborn.

Pregnancy tabs: overview, antenatal, clinical orders, clinical results, labour and delivery, postnatal. `PregnancyViewScope` carries `pregnancyId` and an optional `encounterId`. `PregnancyEncounterScopeBridge` connects that scope to `EncounterScope` when the pregnancy is opened from a doctor encounter.

`ObstetricsService` is the client. Models: `Pregnancy`, `AntenatalVisit`, `LabourDelivery`, `PartogramEntry`, `Baby`, `PostnatalVisit`, `GynaeProcedure`, plus the clinical bundles in `pregnancy_clinical_models.dart`.

Clinical orders and results on a pregnancy read lab and imaging for the linked encounter. Labour can be resolved by admission id.

## Laboratory (`lib/src/lab/`)

The department worklist, separate from the doctor’s order tab (that tab uses `LabOrderService`).

| Screen | Role |
|---|---|
| `LabDashboardScreen` | Home |
| `LabCreateOrderScreen` | Order from the lab |
| `LabOrderDetailScreen` | One order |
| `LabResultEntryScreen` | Results, including AST |
| `LabRecordSampleSheet` | Sample collection |
| `LabConfigScreen` | Categories, tests, versions, fields, antibiotics, AST options |
| `LabInvestigationsScreen` | Volume and revenue report |

`LabApiService` and `LabOrdersParams` back the worklist. Models include `LabOrder`, `LabOrderStatus`, `LabTest`, `LabSample`, `LabResult`, `LabAstResult`, `ReferenceFlag`. Result PDFs are `lab_order_pdf.dart`.

Orders carry patient and staff references and can store `encounterId`. Results surface on the encounter, the nurse lab tab, the obstetrics results tab, and the patient hub.

## Radiology (`lib/src/radiology/`)

Base path `/radiology`.

| Screen | Role |
|---|---|
| `RadiologyDashboardScreen` | Home |
| `RadiologyCreateRequestScreen` | New request |
| `RadiologyWorklistScreen` | Worklist |
| `RadiologyRequestDetailScreen` | Schedule, procedure, images, report |
| `RadiologyPatientHistoryScreen` | One patient’s studies |
| `RadiologyInvestigationsScreen` | Volume and revenue |

`RadiologyService` covers orders, schedules, procedures, image upload, reports, machines, the dashboard, and history. Models: `RadiologyOrder`, `RadiologyOrderItem`, `RadiologyModality`, `RadiologySchedule`, `RadiologyProcedure`, `RadiologyImage`, `RadiologyStudyReport`.

The doctor imaging tab calls `createOrder` with `encounterId`. Report preview and clinical-notes PDFs live under `lib/src/printing/pdf/`.

## Investigations (`lib/src/investigations/`)

Shared reporting for lab and radiology. There is no standalone HTTP class. `investigation_providers.dart` calls `LabApiService` and `RadiologyService`.

`InvestigationSummary`, `InvestigationListRow`, and `InvestigationInvoiceRef` are the rows. `InvestigationInvoiceRef` is how a count line points back at billing.

## Pharmacy, clinical side (`lib/src/pharmacy/`)

Inventory screens are listed in [Inventory and operations](12-inventory-and-operations.md). The clinical queue is:

| Screen | Role |
|---|---|
| `MedicationRequestsScreen` | Orders waiting to be supplied |
| `PharmacyRefillRequestsScreen` | `PharmacyRefillService` on `/pharmacy/refill-requests` |
| `WaitingPatientScreen` | Pharmacy waiting list |
| `DispenseScreen` | Live dispense onto an invoice |
| `DispenseHistoryScreen` | Past dispenses and returns |
| `PharmacyDashboardScreen`, `PharmacyHeadDashboardScreen` | Department homes |

`PharmacyQueueApiService` reads the invoice-drug queue. A `MockPharmacyQueueService` exists beside it for local UI work. Medication order and request models are in `lib/src/models/`.

Prescribing itself happens on the encounter prescription tab and on the inpatient medications tab, through `MedicationOrderService` and `MedicationRequestService`.

## Dialysis (`lib/src/dialysis/`)

Prefix `/dialysis`.

| Screen | Role |
|---|---|
| `DialysisDashboardScreen` | Home |
| `DialysisSelectPatientScreen` | Pick the patient |
| `DialysisCreateSessionScreen` | New session |
| `DialysisSessionDetailScreen` | Edit session, add consumables |
| `DialysisPatientEncountersScreen` | Encounter list and notes |

`DialysisApiService`: `createSession`, `getSessions`, `getSessionById`, `updateSession`, `addSessionConsumable`. Models: `DialysisSession`, `DialysisSessionStatus`, `DialysisSessionConsumable`, `DialysisPatientRef`.

The patient hub Dialysis tab calls the same API. Access is `canAccessDialysisModule`.

## Theatre (`lib/src/theatre/`)

Requests use `/surgery-requests`. Rooms, schedules, and cases use `/theatre`.

| Screen | Role |
|---|---|
| `TheatreDashboardScreen` | Request and case list |
| `TheatreRoomsScreen` | Rooms |
| `TheatreScheduleFormScreen` | Schedule |
| `TheatreCaseDetailScreen` | Start, complete, notes, consumables, bill, transfer |

`TheatreApiService` includes `startCase`, `completeCase`, `addCaseConsumable`, `billCase`, `transferCase`, and operative-note CRUD. Models: `SurgeryRequest`, `SurgeryRequestStatus`, `TheatreSchedule`, `TheatreRoom`, `TheatreCase`, `TheatreOperativeNote`, `TheatreCaseConsumable`.

A request is created from the encounter Surgery tab with `encounterId` and `patientId`. `billCase` posts charges. `transferCase` moves the patient to a ward. The hub Theatre tab lists requests. Access is `canAccessTheatreModule`.

## Patient chart and hub

**Chart** (`lib/src/patient_chart/`). `PatientChartService.getChart` is `GET /patients/:id/chart`. The `include` sections cover encounters, admissions, medication orders, prescriptions, lab orders and reports, radiology orders and reports, vitals, allergies, appointments, invoices, payments, wallet, histories, doctor reports, and archived encounters. Screens: `PatientChartSelectScreen`, `PatientChartScreen`. Archived uploads use `PatientArchivedEncounter`. Who may open it is `patient_chart_permissions.dart`.

**Hub** (`lib/src/patient_hub/`). `PatientHubService` composes the chart service, `PatientService`, `DialysisApiService`, and `TheatreApiService`. Screens: `PatientHubSearchScreen`, `PatientHubScreen`. Tabs: overview, profile, encounters, vitals, labs, imaging, meds, dialysis, theatre, documents, notes. `HubSectionRequest` and the date-range bar control what is loaded. The hub does not start encounters or post orders.

## Medical records (`lib/src/medical_records/`)

`ConsultationPaymentReportScreen` lists paid consultations with the diagnosis filled in by `formatEncounterDiagnosis`. `ConsultationPaymentReportService` loads the invoices and indexes encounters. The row type is `ConsultationPaymentReportRow` (patient, diagnosis, `paidAt`, `invoiceId`, `encounterId`). The route is part of the accounting module.

## Department head (`lib/src/department_head/`)

`DepartmentStaffScreen` and `DepartmentRosterScreen`. `DepartmentHeadApiService` uses `/department-head/staff` and the roster endpoints (`listStaff`, `listRosters`, `rosterSummary`, `addToRoster`, `removeRoster`). Roster parsing reuses nursing model helpers. This module does not write encounters or invoices. It sits beside `nursing/` rosters, scoped to the head’s department. Access is `department_head_permissions.dart`.
