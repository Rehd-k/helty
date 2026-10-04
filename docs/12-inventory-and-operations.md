# Inventory and operations

Three stock systems can put a line on an invoice.

| Stock | API prefix | What it holds | How it is billed |
|---|---|---|---|
| Pharmacy | `/pharmacy` | Drugs, batches, suppliers | `DispenseScreen` writes invoice lines. Refills can raise a bill |
| Purchases | `/purchases` | Non-drug items | `InvoicePurchasesApiService` (`/invoice-purchases`) and `PurchaseItemSalesScreen` |
| Store consumables | `/store/consumables` | General consumables | `InvoiceConsumablesApiService` (`/invoice-consumables`) |

Goods-receipt math shared by batches (unit, pack, carton, cost) is `lib/src/shared/batch_receive_conversion.dart`.

Purchases screens are hospital-only, except `PurchaseItemSalesRoute`, which is also on the pharmacy route list. Store, dialysis consumables, and theatre consumables are hospital modules.

## Pharmacy inventory (`lib/src/pharmacy/`)

`PharmacyApiService` covers drugs, manufacturers, suppliers, batches, purchase orders, goods receipts, stock transfers, dispense history, and locations. Methods that look like consumables delegate to `StoreConsumableApiService` so pharmacy screens can issue the same consumable catalog.

| Screen | Role |
|---|---|
| `MedicineInventoryScreen` | Drug list. Default home for pharmacy store staff |
| `AddDrugScreen`, `AddSupplierScreen`, `AddBatchScreen` | Masters and goods receipt |
| `BatchesPreviewWardPricingScreen` | Ward price preview. Route carries the batch id |
| `StockTransferScreen`, `CreateRequisitionScreen`, `SupplyHistoryScreen` | Move and request stock |
| `PharmacyLocationScreen` | Stores and dispensaries |
| `PharmacyInventoryValuationScreen` | Stock value |
| `PharmacyReportsHubScreen`, `PharmacySalesBreakdownScreen`, `PharmacySalesBreakdownDetailScreen` | Sales reports |
| `PharmacyDashboardScreen`, `PharmacyHeadDashboardScreen` | Homes. Head dashboard is `PHARMACY_HEAD` |

Models in `pharmacy_model.dart`: `Drug`, `DrugBatch`, `Supplier`, `Dispensation`, `PurchaseOrder`, `StockTransfer`, `PharmacyLocation`. Dashboard, report, queue, and refill models have their own files. Permissions are `pharmacy/auth/pharmacy_permissions.dart`.

Ward price name constant `kInpatientWardPriceName` is what inpatient dispense uses when it picks a price tier.

`PharmacyPOSScreen` (`dispensory.screen.dart`) is registered and visible, and it does not call the API. The working dispense screen is `DispenseScreen`.

Clinical queue screens are documented in [Clinical modules](10-clinical-modules.md).

## Purchases (`lib/src/purchases/`)

Parallel to pharmacy for items that are not drugs.

| Screen | Role |
|---|---|
| `PurchasesDashboardScreen` | Home. `PurchasesDashboardService` |
| `PurchasesInventoryScreen` | Items on hand |
| `PurchasesAddItemScreen`, `PurchasesAddSupplierScreen`, `PurchasesAddPurchaseScreen` | Masters and receipts |
| `PurchasesStockTransferScreen`, `PurchasesTransferHistoryScreen` | Transfers |
| `PurchasesPurchaseHistoryScreen` | Purchase history |
| `PurchasesLocationScreen` | Locations |
| `PurchasesRequisitionHistoryScreen` | Requisitions |
| `PurchasesUsageHistoryScreen` | Issues and returns |
| `PurchaseItemSalesScreen` | Counter sale onto an invoice |

`PurchasesApiService` uses `/purchases`. Models: `purchases_model.dart`, `purchases_dashboard_model.dart`, `purchases_usage_history_model.dart`.

The billing charge sheet embeds `PurchasesConsumableBillingPanel`, which shares catalog cart widgets with dispense.

## Store (`lib/src/store/`)

General stores plus the consumable catalog that other departments bill.

| Screen | Role |
|---|---|
| `StoreDashboardScreen` | Home |
| `StoreCategoriesScreen`, `StoreItemsScreen` | Catalog structure |
| `StoreLocationsScreen` | Locations |
| `StoreStockScreen` | On-hand quantities |
| `StoreMovementsScreen` | Issue, receive, and transfer tabs |
| `StoreAnalyticsScreen` | Movement analytics |
| `StoreConsumablesCatalogScreen` | Consumables other modules sell |
| `StoreConsumableDetailScreen` | One consumable, including batches |
| `StoreConsumableAnalyticsScreen` | Consumable usage |

`StoreApiService` uses `/store/...`. `StoreConsumableApiService` uses `/store/consumables`. `store_providers.dart` exposes both. `consumable_invoice_helper.dart` is the bridge from a stock row to an invoice line. Models are split between `store_models.dart` (category, item, location, stock, movements, analytics) and `consumable_models.dart` (batches, usage, invoice lines).

Nurse consumable usage, theatre case consumables, and dialysis session consumables all reduce this kind of stock and can raise charges.

## Wards, beds, and rooms

`WardManagementScreen` and `WardService` (`/wards`, `/beds`) define where inpatients are. `AdmissionWardLocationSection` is the picker on an admission. `ConsultingRoomsScreen` is the outpatient room list used at check-in. The CMD beds screen (`CMDBedsFacilitiesScreen`) reads a snapshot from `/cmd/beds/snapshot`. It does not replace ward management.

## Hospital assets (`lib/src/hospital_assets/`)

Equipment register.

| Screen | Role |
|---|---|
| `HospitalAssetsScreen` | List. `HospitalAssetsApiService.me()` loads `/hospital-assets/me` first |
| `HospitalAssetDetailScreen` | One asset and its log. Path includes `assetId` |
| `HospitalAssetAccessScreen` | Grants |

Models: `HospitalAsset`, `HospitalAssetLog`, `HospitalAssetAccessGrant`, `HospitalAssetAccessMe`. `hospital_asset_providers.dart` is also read by `HomeScreen`, which adds the menu item only on the hospital product and only when the current user has access. Chips and colors are `asset_theme.dart`.

## Housekeeping (`lib/src/housekeeping/`)

`HousekeepingHomeScreen` is a tile launcher. The other screens are workers, areas, shifts, and supply logs. `HousekeepingApiService` uses `/housekeeping/workers` and the sibling resources. It imports nursing model helpers for roster-shaped rows. Models: `HousekeepingWorker`, `HousekeepingArea`, `HousekeepingShiftEntry`, `HousekeepingSupplyLog`. Landing for janitor account types is this home. The module is `AppModule.housekeeping`, hospital only.

## ICT dashboard

`DashboardScreen` in `lib/src/ui/dashboard/dashboard_screen.dart` is a card grid for ICT (`accountType` `ict`, route `DashboardRoute`, module `AppModule.ict`). It is the ICT home, not the CMD command center. Database backup is a super-admin hub action, documented with that hub.

## Department setup already covered elsewhere

Creating departments and the billable catalog is [Finance](11-finance.md), because those records are what cashiers sell. Staff registration is [Authentication and permissions](05-authentication-and-permissions.md) (`RegisterScreen`, `StaffService`).
