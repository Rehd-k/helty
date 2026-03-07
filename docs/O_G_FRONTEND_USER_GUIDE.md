# O&G (Obstetrics & Gynaecology) Frontend – User Guide

This guide explains how to use every section of the O&G frontend built for the Helty hospital app.

---

## Who can see O&G

The O&G section is visible in the home sidebar only for staff whose **account type** is one of:

- **ONG** (Obstetrics & Gynaecology)
- **CONSULTANT**
- **INPATIENT_DOCTOR**
- **THEATERE** (e.g. for gynaecology procedures)

If you do not have one of these account types, the O&G menu items will not appear. If you open an O&G URL without permission, the app will show: **"You don't have access to this section."** (403).

---

## How to open the O&G section

1. Log in with an account that has one of the allowed account types above.
2. In the **home screen sidebar**, you will see:
   - **O&G Dashboard**
   - **Pregnancies (by patient)**
   - **Gynaecology procedures**
3. Click **O&G Dashboard** to land on the main O&G hub, or go directly to **Pregnancies** or **Gynaecology procedures**.

---

## 1. O&G Dashboard

- **Path:** Home → O&G Dashboard (or sidebar → O&G Dashboard).
- **What it does:** Shows two cards:
  - **Pregnancies** – Opens the “Select patient (mother)” screen so you can choose a patient and then view or add pregnancies.
  - **Gynaecology procedures** – Opens the list of gynaecology procedures (with optional patient filter); you can add new procedures here.
- **Use it when:** You want a single entry point for either antenatal/labour/postnatal flows or gynae procedures.

---

## 2. Selecting a patient (mother)

- **Path:** O&G Dashboard → Pregnancies, or sidebar → Pregnancies (by patient).
- **What it does:**
  - You see a **search box** and a **Search** button.
  - Enter the patient’s name or patient ID and tap **Search**.
  - A list of matching patients appears; tap a row to open **Pregnancies** for that patient.
- **Use it when:** Before viewing or adding pregnancies, you must select the mother (patient). All pregnancies are tied to a `patientId` (mother).

---

## 3. Pregnancies list

- **Path:** After selecting a patient (mother) from the previous screen.
- **What it does:**
  - Shows all pregnancies for that patient (G, P, LMP, EDD, status).
  - **Add pregnancy** (FAB or button) opens the “Add pregnancy” form.
  - Tapping a row opens **Pregnancy detail** (tabs: Overview, Antenatal visits, Labour & delivery, Postnatal).
- **Use it when:** You want to see all pregnancies for a mother or add a new pregnancy.

---

## 4. Add pregnancy

- **Path:** Pregnancies list → Add pregnancy (FAB or “Add pregnancy” button).
- **What it does:** Form with:
  - **Gravida** (required, number ≥ 0)
  - **Para** (required, number ≥ 0)
  - **LMP** (required, date)
  - **EDD** (required, date)
  - **Booking date** (optional)
  - **Status** (e.g. ONGOING, DELIVERED)
  - **Outcome** (optional text)
- **Actions:** **Save pregnancy** sends the data to the API; you are returned to the pregnancies list and can open the new pregnancy.

---

## 5. Pregnancy detail (tabs)

- **Path:** Pregnancies list → tap a pregnancy row.
- **What it does:** A single pregnancy view with four tabs:
  - **Overview** – Gravida, para, LMP, EDD, status, booking date, outcome, patient name.
  - **Antenatal visits** – List of antenatal visits for this pregnancy; add or edit visits.
  - **Labour & delivery** – One button: **Record delivery**. Use it to create a delivery for this pregnancy; after saving you are taken to the Labour & delivery view (partogram + babies).
  - **Postnatal** – Explains that postnatal visits are linked to a labour delivery; record a delivery first, then open that delivery to add mother/baby postnatal visits.

---

## 6. Antenatal visits

- **Path:** Pregnancy detail → **Antenatal visits** tab.
- **What it does:**
  - Lists all antenatal visits (date, gestation, BP, weight, presentation, etc.).
  - **Add visit** opens the “Add antenatal visit” form.
  - Tapping a visit row opens “Edit antenatal visit”.
- **Add antenatal visit form:** Visit date, staff, gestation (weeks), systolic/diastolic BP, weight, fundal height, fetal heart rate, presentation (CEPHALIC, BREECH, etc.), urine protein, notes, ultrasound findings. Save to create the visit.
- **Edit antenatal visit:** Same fields; save to update.

---

## 7. Labour & delivery

### 7.1 Record delivery

- **Path:** Pregnancy detail → **Labour & delivery** tab → **Record delivery**.
- **What it does:** Form for one delivery:
  - **Delivery date & time** (required)
  - **Mode** (e.g. SVD, CS_ELECTIVE, CS_EMERGENCY)
  - **Outcome** (LIVE_BIRTH, STILLBIRTH, OTHER)
  - **Delivered by** (staff)
  - **Blood loss (ml)**, **Placenta complete**, **Episiotomy**, **Perineal tear grade**, **Notes**
- **After save:** You are taken to the **Labour & delivery view** for that delivery (partogram + babies).

### 7.2 Labour & delivery view (Partogram + Babies)

- **Path:** After recording a delivery, or from anywhere you have the delivery ID (e.g. from a link).
- **What it does:**
  - **Partogram tab:** List of partogram entries (time, dilation, FHR, etc.). **Add entry** opens the partogram form (recorded at, cervical dilation, station, contractions, FHR, moulding, descent, oxytocin, comments).
  - **Babies tab:** List of babies (birth order, sex, weight, “Registered as patient” or not). **Add baby** opens the add-baby form; you can **Edit** a baby or **Register as patient** (if not yet registered).
- **App bar:** **Postnatal visits** (icon) opens the postnatal list for this delivery so you can add mother/baby postnatal visits.

### 7.3 Add baby

- **Path:** Labour & delivery view → Babies tab → **Add baby**.
- **What it does:** Form: **Sex** (M/F/U), **Birth order**, **Birth weight (g)**, **Birth length (cm)**, **Apgar 1 min**, **Apgar 5 min**, **Resuscitation**. Mother is taken from the pregnancy; save to create the baby.

### 7.4 Register baby as patient

- **Path:** Labour & delivery view → Babies tab → baby row → **Register as patient** (person-add icon).
- **What it does:** Form: **First name**, **Surname** (required), **Other name**, **Gender** (optional; can be derived from baby sex). Save to create a Patient linked to the baby (DOB = delivery date). If the baby is already registered, the API returns an error (e.g. 409); the UI shows that message.

### 7.5 Edit baby

- **Path:** Labour & delivery view → Babies tab → tap a baby row.
- **What it does:** Edit birth weight, length, Apgar 1/5, resuscitation. Save to update.

---

## 8. Postnatal visits

- **Path:** From **Labour & delivery view** → app bar → **Postnatal visits** (icon). Or open **Postnatal list** from a route that passes a `labourDeliveryId`.
- **What it does:**
  - Lists postnatal visits for that delivery (mother or baby, date, notes, weight, etc.).
  - **Add** (if a delivery is selected) opens “Add postnatal visit”.
- **Add postnatal visit form:**
  - **Type:** MOTHER or BABY.
  - If MOTHER: **Visit date**, **Staff**, and optional uterus involution, lochia, perineum, blood pressure, temperature, breastfeeding, notes.
  - If BABY: **Baby** (choose from babies of this delivery), **Visit date**, **Staff**, and optional weight, feeding, jaundice, immunisation given, notes.
- **Note:** Postnatal visits are always tied to a **labour delivery**. So you must have recorded at least one delivery before you can add postnatal visits; open that delivery and use “Postnatal visits” from there.

---

## 9. Gynaecology procedures

- **Path:** O&G Dashboard → **Gynaecology procedures**, or sidebar → **Gynaecology procedures**.
- **What it does:**
  - Lists gynaecology procedures (optionally filtered by patient). Each row shows procedure type, date, notes.
  - **Add procedure** (FAB or button) opens the add form.
  - Tapping a row opens **Edit procedure** (findings, complications, notes).
- **Add procedure form:** **Patient ID**, **Procedure type** (e.g. D&C, HYSTERECTOMY, MYOMECTOMY, LAPAROSCOPY), **Procedure date & time**, **Surgeon**, **Findings**, **Complications**, **Notes**. Save to create.
- **Edit procedure:** Update findings, complications, notes only.

---

## 10. Troubleshooting

| Issue | What to do |
|-------|------------|
| **O&G menu not visible** | Ensure your account type is ONG, CONSULTANT, INPATIENT_DOCTOR, or THEATERE. |
| **403 – “You don’t have access to this section”** | Your JWT is valid but your account type is not allowed for O&G (or that endpoint). Use an allowed account or contact admin. |
| **401 – Session expired** | Log in again. |
| **404 – Not found** | The resource (pregnancy, visit, delivery, baby, procedure) was deleted or the ID is wrong. Go back and reopen from the list. |
| **400 / Validation errors** | Check required fields (e.g. LMP, EDD, delivery date/time, staff, patient ID). Use the correct date format (YYYY-MM-DD or full ISO date-time). |
| **409 – e.g. “Baby is already registered as a patient”** | That baby already has a linked patient; you don’t need to register again. |
| **Empty lists** | Ensure you have selected the right patient or labour delivery. Use “Refresh” or pull-to-refresh where available. |

---

## 11. Quick reference – where to do what

| Goal | Where to go |
|------|-------------|
| Start O&G | Home → O&G Dashboard (or Pregnancies / Gynaecology from sidebar). |
| View or add pregnancies for a mother | O&G Dashboard → Pregnancies → Search patient → tap patient → Pregnancies list. |
| Add a pregnancy | Pregnancies list → Add pregnancy (FAB). |
| View pregnancy details | Pregnancies list → tap pregnancy. |
| Add antenatal visit | Pregnancy detail → Antenatal visits tab → Add visit. |
| Record labour & delivery | Pregnancy detail → Labour & delivery tab → Record delivery. |
| Add partogram entry | Labour & delivery view → Partogram tab → Add entry. |
| Add baby | Labour & delivery view → Babies tab → Add baby. |
| Register baby as patient | Labour & delivery view → Babies tab → baby row → Register as patient icon. |
| Add postnatal visit (mother or baby) | Labour & delivery view → Postnatal visits (app bar) → Add. |
| List or add gynae procedures | O&G Dashboard → Gynaecology procedures, or sidebar → Gynaecology procedures. |

This guide covers all sections created for the O&G frontend. The app uses the same API base URL and JWT auth as the rest of Helty; only the `/obstetrics` paths and these screens are specific to O&G.
