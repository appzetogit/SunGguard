# Porter (Outstation Parcel) — Payment, Earning & Cash Flow

Scope: outstation parcel booking money flow — customer fare, rider earning, COD cash
collection, COD→online conversion, deposit & withdraw. Everything below already exists
in the codebase (verified, not a proposal). Checked: 2026-09-25.

---

## 1. Customer fare — three parts, admin-controlled

Admin sets three independent numbers, all added together into one total:

| Part | Admin sets it at | Field | Depends on |
|---|---|---|---|
| Delivery charge | `/admin/parcels/pricing` | `ParcelConfig.fixedDeliveryCharge` | flat, nothing |
| Weight charge | `/admin/parcels/pricing` | `ParcelConfig.weightCharge` (₹/kg) | package weight |
| Courier charge | `/admin/parcels/cityRates` (Excel upload) | `ParcelCityRate.charge` | pickup city + destination city + selected courier company |

```
customer fare = fixedDeliveryCharge
              + (weightCharge × package weight in kg)
              + courierCharge (looked up for the exact origin→destination→courier combo)
```

- Computed in **one place only**: `backend/app/utils/parcelFare.js` → `computeParcelDailyFare()`.
- Called identically by the quote endpoint (`calculateFare`), the coupon check
  (`validateBookingCoupon`) and the actual booking (`createParcel`) — all in
  `backend/app/controller/parcelController.js`. Quote and booking can never disagree
  because they run the same function with the same inputs.
- Courier charge lookup: `ParcelCityRate.findRate(originCity, destinationCity, courierCompanyId)`
  (`backend/app/models/parcelCityRate.js`). If admin never priced that route/courier
  combination, booking is refused with *"Service not available from X to Y with the
  selected courier"* — no fabricated price, no silent free delivery.
- Bidirectional by default: a rate set for Surat→Indore also covers Indore→Surat unless
  admin explicitly prices the reverse direction with its own number.
- Multi-day bookings ("Custom days" / "Until a date"): each part above is a *daily* rate;
  `applyBillableDaysToFare()` multiplies the total by the number of days, then GST is
  applied once on the multi-day total (not once per day, to avoid a rounding drift on a
  month-long booking).

### Frontend

`frontend/src/modules/customer/pages/ParcelDeliveryPage.jsx`:
- Sends `pickupCity`, `destinationCity`, `courierCompanyId`, `weight` to `calculateFare`
  on pickup-city/destination-city **blur** (not on every keystroke — see §8).
- Fare card shows each part as its own line: *Delivery charge*, *Weight {kg} kg*,
  *{Courier} charge (City → City)*.
- "Confirm" is disabled until a valid quote exists (`fareEstimation.fare` truthy) — a
  route with no rate card entry cannot reach the booking screen.

---

## 2. Rider earning — completely separate number, per-km

The rider's payout has **nothing to do with what the customer paid**. It is:

```
rider earning = distance(rider's location when they accepted the job → pickup point)
              × ParcelConfig.riderPerKmRate
```

- Admin sets `riderPerKmRate` on the same `/admin/parcels/pricing` screen.
- The rider's GPS position is snapshotted **once**, at the moment they tap Accept
  (`parcel.riderAcceptLocation`, set in `parcelAcceptAtomic()` in
  `backend/app/services/parcelWorkflowService.js`). This locks the earning in — it
  cannot move even if the rider takes a longer physical route to the pickup.
- `computeRiderParcelEarningBreakdown(parcel, settings)` (same file) returns
  `{ earning, distanceKm, ratePerKm }` — the breakdown, not just the total — so every
  screen that shows an amount can also show *why*.
- Example from the brief that started this doc: admin sets delivery charge ₹50 and
  rider rate ₹5/km; rider accepts 4 km from the pickup point → earns ₹20. The remaining
  ₹30 of the ₹50 delivery charge is the platform's own margin (see §5).

### Where the breakdown shows up

| Screen | File | What it shows |
|---|---|---|
| Rider — active job card | `frontend/src/modules/delivery/pages/Dashboard.jsx` | "You earn ₹20 (4 km × ₹5/km)" |
| Rider — job detail screen | `frontend/src/modules/delivery/pages/ParcelTaskPage.jsx` | same breakdown, green card |
| Admin — parcel detail | `frontend/src/modules/admin/pages/AdminParcelDashboard.jsx` | "Rider ₹20 · Admin ₹30" + the km×rate line |
| Rider — pre-accept offer | `frontend/src/modules/delivery/layout/DeliveryLayout.jsx` | rate only (₹/km) — the amount is genuinely unknown until they accept, since it depends on where *they* are standing |

---

## 3. COD collection — the rider holds the FULL fare, not their cut

When payment method is COD:

- `Parcel.codSettlement.collectAmount` = the full customer fare (₹200 in the example),
  **not** the rider's ₹25/30 share.
- Rider collects the full amount in cash at pickup (`riderUpdateStatus` → `PICKED_UP`
  requires `pickupProofImage`; COD amount is fixed at that point).
- Two separate ledgers from here on, and they never mix:

| Ledger | Transaction type | What it tracks |
|---|---|---|
| Cash-in-hand | `Cash Collection` (+) / `Cash Settlement` (−) | Money the rider is physically holding, owed to admin |
| Earnings | `Delivery Earning` | The rider's own payout, always withdrawable regardless of cash-in-hand status |

`backend/app/services/riderCashService.js` is the source of truth for both. A rider
depositing cash reduces their **cash-in-hand** balance to 0; it does **not** touch their
**earnings** balance — that money was always theirs from the moment `applyParcelDelivered
RiderEarning()` (`backend/app/services/parcelRiderSettlementService.js`) ran at drop time.

Verified by `backend/__tests__/porter-money-flow.test.js` ("rider cash and earnings never
mix" suite) — deposit + settlement rows cancel out to exactly zero net effect on the
earnings side.

---

## 4. COD → Online conversion at the doorstep (Razorpay QR)

Exactly the flow requested: customer booked COD, but wants to pay digitally right there.

```
Rider taps "Customer wants to pay online" (ParcelTaskPage.jsx, COD card)
        │
        ▼
POST /delivery/cod-qr/parcel/:id           riderCreateCodQr (riderCashController.js)
        │  creates a single-use, fixed-amount Razorpay UPI QR (codQrService.js)
        │  saves parcel.codOnlineQr = { qrId, imageUrl, amount, createdAt }
        ▼
Customer scans, pays via their own UPI app
        │
        ▼
GET /delivery/cod-qr/parcel/:id  (polled)  riderCheckCodQr
        │  reads Razorpay's payments_amount_received on the QR
        │  once paid:
        │    parcel.paymentStatus  = "PAID"
        │    parcel.paymentMethod  = "UPI"          ← was "COD"
        │    parcel.codSettlement  = { collectAmount: 0, status: "NOT_APPLICABLE" }
        ▼
Order now behaves exactly like an online booking for every downstream step —
COD deposit flow, cash-in-hand tracking, "give rider cash" UI — none of it applies anymore.
```

- Amount on the QR is the exact `codSettlement.collectAmount` at that moment — never a
  client-supplied number.
- A live, unpaid QR is reused if the rider re-opens the sheet (no double QR / double
  charge risk).
- Rider never touches cash for this booking; nothing to deposit for it later.

---

## 5. Admin's own margin (not the same as revenue)

A common mistake: treating everything the customer paid as "admin income". Fixed here —
`adminGetReports` in `parcelController.js`:

```
courierChargeCollected = Σ (courier charge across delivered parcels)
                          — collected on behalf of the courier company, never the
                            platform's own money, so it is reported separately and
                            excluded from admin's margin

adminCommission = revenue − courierChargeCollected − riderPayout
```

Revenue report (`/admin/parcels/reports`) shows all three numbers side by side:
*Admin Commission*, *Riders Payout*, *Courier Charge Collected (pass-through)*.

---

## 6. Cash deposit → admin (once collected)

Two ways for a rider to clear cash-in-hand back to admin:

1. **Online, full balance** (preferred): `POST /delivery/cash/deposit/online` opens a
   Razorpay order for the rider's *entire* currently-held balance — the amount is summed
   server-side from the bookings they actually hold, never taken from the request (so a
   rider can't "pay ₹1 to clear ₹5,000"). `POST /delivery/cash/deposit/online/verify`
   confirms the gateway receipt and raises it for admin approval.
2. **Manual** (fallback): `POST /delivery/cash/deposit` with method (UPI / bank transfer
   / cash) + reference + proof image, also goes to the same approval queue.

Admin approves via `/admin/parcels` → Porter → Cash Deposits (`PorterCashDeposits.jsx`,
backed by `PATCH /porter/admin/cash-deposits/:id/review`). Approval marks the covered
bookings' `codSettlement.status = REMITTED_TO_ADMIN` and the rider's held balance drops
to 0. A rejected deposit leaves the cash-in-hand balance untouched (rider still owes it).

A per-rider **cash limit** (`getRiderCashStatus`) blocks a rider from accepting new COD
jobs once they're holding too much unremitted cash — admin configures the global limit
and can override it per rider (`adminSetRiderCashLimit`).

---

## 7. Rider withdrawal

- Earnings balance (never touched by cash deposits, §3) is what a rider can request to
  withdraw — `POST /delivery/request-withdrawal`.
- Wallet screen (`frontend/src/modules/delivery/pages/profile/Wallet.jsx`) shows
  `totalEarnings`, `withdrawnTotal`, `pendingWithdrawals`, and the resulting
  `availableBalance` — all derived from the `Delivery Earning` ledger rows only, so a
  pending cash deposit never shows up as "less money available to withdraw".

---

## 8. One UX fix worth knowing about (city-field typing)

The pickup-city / destination-city fields used to fire a `calculateFare` request on
every keystroke pause (typing "Indore" could fire 3–4 requests for "i", "in", "indo"...).
Fixed by moving the trigger to field **blur** instead of live-typing
(`cityCheckTick` in `ParcelDeliveryPage.jsx`) — the fare/rate check now happens once,
when the customer finishes typing the city, not while they're still typing it.

---

## 9. File map (for quick reference)

| Concern | Backend | Frontend |
|---|---|---|
| Fare calc | `utils/parcelFare.js`, `controller/parcelController.js` (`calculateFare`/`createParcel`) | `customer/pages/ParcelDeliveryPage.jsx` |
| City rate card | `models/parcelCityRate.js`, `controller/parcelCityRateController.js` | `admin/pages/AdminParcelDashboard.jsx` (City Rates tab) |
| Rider earning | `services/parcelWorkflowService.js` (`computeRiderParcelEarningBreakdown`) | `delivery/pages/{Dashboard,ParcelTaskPage}.jsx` |
| Rider cash (collect/deposit/limit) | `services/riderCashService.js`, `controller/riderCashController.js` | `delivery/pages/profile/{Wallet,Withdrawals}.jsx` |
| COD→online QR | `services/codQrService.js`, `controller/riderCashController.js` (`riderCreateCodQr`/`riderCheckCodQr`) | `delivery/pages/ParcelTaskPage.jsx` |
| Admin cash review/overview | `controller/riderCashController.js` (admin exports) | `admin/pages/porter/{PorterCashDeposits,PorterWallet,PorterRiderPayouts}.jsx` |
| Admin margin reporting | `controller/parcelController.js` (`adminGetReports`) | `admin/pages/AdminParcelDashboard.jsx` (Revenue Reports tab) |

---

## 10. Verified

- `backend/__tests__/porter-money-flow.test.js` — fare composition, rider payout,
  cash-vs-earnings separation, admin margin. All passing.
- `backend/__tests__/cod-online-qr.test.js` — COD→online QR conversion.
- `backend/__tests__/cash-payout-destination-controller.test.js` — deposit destination.
- Full suite: 503 passing (7 pre-existing failures unrelated to this flow, in
  `city-parcel-routes.test.js` — a disabled, unrelated product).
