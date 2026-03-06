# API Routes – Encounter & Related (for backend implementation)

Use these with the Prisma models in `prisma/schema.prisma`. Request/response shapes align with the Flutter app’s `EncounterModel`, `MedicationOrderModel`, etc.

---

## 1. Encounters

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/encounters/:id` | Get one encounter by id. Return full encounter (for History, Exam, Notes, Diagnosis, Procedures, Follow-up tabs). |
| **GET** | `/encounters` | List encounters. Query: `doctorId`, `date` (filter by startedAt), `status`, `skip`, `take`. Response: `{ data: Encounter[], total: number }`. |
| **POST** | `/encounters` | Create encounter. Body: `{ patientId, doctorId, appointmentId?, visitType?, insurance? }`. **Must return the created encounter with its real `id`** so the client can navigate to the encounter view and all subsequent saves use that id. |
| **PATCH** | `/encounters/:id` | Partial update. Body: any subset of encounter fields (e.g. `chiefComplaint`, `hpi`, `status`, `soapSubjective`, `primaryIcdCode`, `proceduresJson`, `followUpDate`, `followUpInstructions`, `referral`, `closedAt`, etc.). Return updated encounter. To **complete** an encounter (doctor finished with patient), send `{ "status": "done", "closedAt": "<ISO8601>" }`. |

**Encounter response shape (minimal for list, full for GET one / PATCH):**

- `id`, `patientId`, `doctorId`, `appointmentId?`, `status`, `startedAt`, `closedAt?`, `visitType?`, `insurance?`
- History: `chiefComplaint`, `hpi`, `pmh`, `surgicalHistory`, `drugHistory`, `allergyHistory`, `familyHistory`, `socialHistory`
- Examination: `examinationNotes`
- Notes: `soapSubjective`, `soapObjective`, `soapAssessment`, `soapPlan`, `soapLockedAt`
- Diagnosis: `primaryIcdCode`, `primaryIcdDescription`, `secondaryDiagnosesJson` (stringified JSON array), `proceduresJson` (stringified JSON array)
- Follow-up: `followUpDate`, `followUpInstructions`, `referral`

---

## 2. Medication orders (prescriptions)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/medication-orders` | List by encounter. Query: `encounterId`. Response: `{ data: MedicationOrder[] }` or array. |
| **POST** | `/medication-orders` | Create. Body: `{ encounterId, drugId, drugName, dose?, frequency?, duration?, route?, specialInstructions? }`. Return created order. |

**MedicationOrder:** `id`, `encounterId`, `drugId`, `drugName`, `dose?`, `frequency?`, `duration?`, `route?`, `specialInstructions?`, `status`.

---

## 3. Lab orders (investigations)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/lab-orders` | List by encounter. Query: `encounterId`. Response: array of lab orders. |
| **POST** | `/lab-orders` | Create one or many. Body: `{ encounterId, catalogTestId, testName, priority?, clinicalNotes? }` or `{ encounterId, orders: [{ catalogTestId, testName, priority?, clinicalNotes? }] }`. Return created order(s). |
| **PATCH** | `/lab-orders/:id` | Update (e.g. result values, status). Body: `{ status?, resultValues? }`. |

**LabOrder:** `id`, `encounterId`, `catalogTestId`, `testName`, `priority?`, `clinicalNotes?`, `status`, `resultValues?` (object/map).

---

## 4. Imaging orders

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/imaging-orders` | List by encounter. Query: `encounterId`. Response: array of imaging orders. |
| **POST** | `/imaging-orders` | Create. Body: `{ encounterId, catalogId, studyName, area?, contrast?, urgency?, notesToRadiologist? }`. Return created order. |

**ImagingOrder:** `id`, `encounterId`, `catalogId`, `studyName`, `area?`, `contrast`, `urgency?`, `notesToRadiologist?`, `status`.

---

## 5. Admissions

| Method | Route | Description |
|--------|--------|-------------|
| **POST** | `/admissions` | Create from encounter. Body: `{ patientId, encounterId, reason?, ward?, bedPreference?, provisionalDiagnosis?, expectedLOS?, isolationRequired?, specialInstructions? }`. Return created admission. Optionally PATCH encounter to `status: 'admitted'`. |

**Admission:** `id`, `patientId`, `encounterId`, `reason?`, `ward?`, `bedPreference?`, `provisionalDiagnosis?`, `expectedLOS?`, `isolationRequired`, `specialInstructions?`, `status`.

---

## 6. Waiting patients (for doctor walk-in queue)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/waiting-patients` | List. Query: `q?`, `consultingRoomId?`, `skip`, `take`, `sortBy?`, `sortOrder?`. Response: `{ data: WaitingPatient[], total, skip, take }`. Each item may include nested `patient`, `vitals`, `consultingRoom`, `service` (expand via query e.g. `include=patient,vitals,consultingRoom,service` or your backend convention). |

**WaitingPatient:** `id`, `patientId`, `consultingRoomId`, `vitalsId?`, `serviceId?`, `seen`, `createdById?`, `updatedById?`, `staffId?`, `createdAt`, `updatedAt`, and when expanded: `patient`, `vitals` (PatientVitals), `consultingRoom`, `service`.

---

## 7. Patient vitals (nurse-recorded)

| Method | Route | Description |
|--------|--------|-------------|
| **POST** | `/patient-vitals` | Create. Body: `{ waitingPatientId }` plus optional: `systolic`, `diastolic`, `temperature`, `height`, `weight`, `bmi`, `pulseRate`, `spo2`. If linked to waiting list, set `waitingPatient.vitalsId` to new vitals id. Return created vitals. |
| **PATCH** | `/patient-vitals/:id` | Partial update. Body: any of the numeric/text vitals fields. |
| **DELETE** | `/patient-vitals/:id` | Delete (soft or hard per your policy). |

**PatientVitals:** `id`, `patientId?`, `systolic?`, `diastolic?`, `temperature?`, `height?`, `weight?`, `bmi?`, `pulseRate?`, `spo2?`, `createdAt`, `updatedAt`.

---

## 8. Catalogs (for dropdowns / order creation)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/drug-catalog` or `/drugs` | List/search. Query: `q?` (search name/generic), `skip`, `take`. Response: array of `{ id, name, generic?, strength?, form?, ... }`. |
| **GET** | `/lab-catalog` or `/lab-tests` | List. Query: `q?`, `skip`, `take`. Response: array of `{ id, name, department?, cost?, turnaround?, sampleType?, preparation? }`. |
| **GET** | `/imaging-catalog` or `/imaging-studies` | List. Query: `q?`, `skip`, `take`. Response: array of `{ id, name, area?, contrastAvailable, cost? }`. |

---

## 9. Consulting rooms & services (for waiting list)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/consulting-rooms` | List. Query: `q?`, `skip`, `take`. Response: array of `{ id, name, description?, location?, capacity }`. |
| **GET** | `/services` | List services (consultation types). Response: array of `{ id, name, description? }`. |

---

## 10. ICD-10 (diagnosis tab)

| Method | Route | Description |
|--------|--------|-------------|
| **GET** | `/icd10` or `/icd10/search` | Search. Query: `q` (code or description fragment). Response: array of `{ code, description }`. (Can be backed by Prisma table or external API.) |

---

## Summary table

| Area | GET one | GET list | POST | PATCH | DELETE |
|------|---------|----------|------|--------|--------|
| Encounters | `/encounters/:id` | `/encounters` | `/encounters` | `/encounters/:id` | — |
| Medication orders | — | `/medication-orders?encounterId=` | `/medication-orders` | — | — |
| Lab orders | — | `/lab-orders?encounterId=` | `/lab-orders` | `/lab-orders/:id` | — |
| Imaging orders | — | `/imaging-orders?encounterId=` | `/imaging-orders` | — | — |
| Admissions | — | — | `/admissions` | — | — |
| Waiting patients | — | `/waiting-patients` | — | — | — |
| Patient vitals | — | — | `/patient-vitals` | `/patient-vitals/:id` | `/patient-vitals/:id` |
| Drug catalog | — | `/drug-catalog` or `/drugs` | — | — | — |
| Lab catalog | — | `/lab-catalog` or `/lab-tests` | — | — | — |
| Imaging catalog | — | `/imaging-catalog` or `/imaging-studies` | — | — | — |
| Consulting rooms | — | `/consulting-rooms` | — | — | — |
| Services | — | `/services` | — | — | — |
| ICD-10 | — | `/icd10?q=` | — | — | — |

Use these routes and the Prisma schema to implement your service and controller layer (e.g. NestJS, Express, or similar).
