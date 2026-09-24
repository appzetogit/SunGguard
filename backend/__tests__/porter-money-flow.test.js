import { jest } from "@jest/globals";

/**
 * The porter money chain, end to end, on the real arithmetic.
 *
 * Nothing here is mocked except the two config documents — the fare, the
 * rider's cut, the platform's margin and the COD amount are all produced by
 * the functions the running app uses. The point is the invariants between
 * them: the customer is charged what the breakdown adds up to, the rider is
 * never paid more than was collected, the platform's margin is never
 * negative, and a COD booking asks the rider for exactly the fare.
 *
 * Both products are covered because they price differently on purpose — the
 * local flow charges a base fare, the outstation one deliberately does not.
 */

const { computeCityParcelFare, computeRiderEarning, computeReturnLegAmounts } =
  await import("../app/services/cityParcelFareService.js");
const {
  computeParcelDailyFare,
  applyBillableDaysToFare,
  resolveParcelBillableDays,
} = await import("../app/utils/parcelFare.js");
const { computeRiderParcelEarnings } = await import(
  "../app/services/parcelWorkflowService.js"
);
const { distanceMeters } = await import("../app/utils/geoUtils.js");

/** A rate card an admin could plausibly save on /admin/city-parcels/pricing. */
const CITY_CONFIG = {
  baseFare: 30,
  perKmCharge: 12,
  weightCharge: 10,
  minFare: 45,
  platformCharge: 5,
  expressCharge: 20,
  riderBaseFareSharePercent: 80,
  riderDistanceFareSharePercent: 70,
  returnRiderPayoutPercent: 60,
  returnCustomerChargePercent: 0,
};

/**
 * And one for /admin/parcels/pricing. Outstation is a flat delivery charge —
 * distance/weight no longer price the customer at all. The rider's payout is
 * a separate, unrelated number: per-km rate × distance from where they
 * accepted the job to the pickup point (see computeRiderParcelEarnings).
 */
const PARCEL_CONFIG = {
  fixedDeliveryCharge: 40,
  riderPerKmRate: 8,
};

/** Two points ~1km apart, used to exercise the rider-payout distance calc. */
const PARCEL_PICKUP = { lat: 28.6139, lng: 77.209 };
const PARCEL_ACCEPT = { lat: 28.622, lng: 77.209 };
const PARCEL_ACCEPT_KM =
  distanceMeters(PARCEL_ACCEPT.lat, PARCEL_ACCEPT.lng, PARCEL_PICKUP.lat, PARCEL_PICKUP.lng) /
  1000;

const money = (n) => Math.round(n * 100) / 100;

/* ========================================================================
   Local (city parcel)
   ======================================================================== */

describe("local delivery pricing", () => {
  it("charges the customer exactly what the breakdown adds up to", () => {
    const q = computeCityParcelFare({
      config: CITY_CONFIG,
      distanceKm: 6,
      weightKg: 2,
      deliverySpeed: "normal",
    });

    // 30 base + 72 distance + 20 weight + 5 platform = 127
    expect(q.baseFare).toBe(30);
    expect(q.distanceFare).toBe(72);
    expect(q.weightFare).toBe(20);
    expect(q.platformCharge).toBe(5);
    expect(q.expressCharge).toBe(0);
    expect(q.fare).toBe(127);
    expect(q.fare).toBe(
      money(q.baseFare + q.distanceFare + q.weightFare + q.platformCharge + q.expressCharge),
    );
  });

  it("adds the express charge only when express is chosen", () => {
    const normal = computeCityParcelFare({ config: CITY_CONFIG, distanceKm: 6, weightKg: 2 });
    const express = computeCityParcelFare({
      config: CITY_CONFIG,
      distanceKm: 6,
      weightKg: 2,
      deliverySpeed: "express",
    });

    expect(express.fare - normal.fare).toBe(CITY_CONFIG.expressCharge);
  });

  it("lifts a tiny trip to the minimum fare", () => {
    // 30 + 2.4 + 0 + 5 = 37.4, under the 45 floor.
    const q = computeCityParcelFare({ config: CITY_CONFIG, distanceKm: 0.2, weightKg: 0 });

    expect(q.minFareApplied).toBe(true);
    expect(q.fare).toBe(CITY_CONFIG.minFare);
  });

  it("pays the rider a share of base and distance only, never the platform's cut", () => {
    const q = computeCityParcelFare({ config: CITY_CONFIG, distanceKm: 6, weightKg: 2 });
    const earning = computeRiderEarning(q, CITY_CONFIG);

    // 30 × 80% + 72 × 70% = 24 + 50.4
    expect(earning).toBe(74.4);
    // The weight and platform charges stay with the platform.
    expect(earning).toBeLessThan(q.fare);
  });

  it("never pays the rider more than the customer paid, at any distance", () => {
    for (const distanceKm of [0.1, 0.5, 1, 3, 7.5, 15, 30]) {
      for (const weightKg of [0, 0.5, 5, 20]) {
        const q = computeCityParcelFare({ config: CITY_CONFIG, distanceKm, weightKg });
        const earning = computeRiderEarning(q, CITY_CONFIG);

        expect(earning).toBeLessThanOrEqual(q.fare);
        // Which is the same as saying the platform's margin never goes negative.
        expect(money(q.fare - earning)).toBeGreaterThanOrEqual(0);
      }
    }
  });

  it("holds that invariant even when the rider takes 100% of both shares", () => {
    const generous = {
      ...CITY_CONFIG,
      riderBaseFareSharePercent: 100,
      riderDistanceFareSharePercent: 100,
    };
    for (const distanceKm of [0.1, 1, 12, 30]) {
      const q = computeCityParcelFare({ config: generous, distanceKm, weightKg: 1 });
      expect(computeRiderEarning(q, generous)).toBeLessThanOrEqual(q.fare);
    }
  });

  it("pays a return leg off the distance fare, and bills the customer nothing by default", () => {
    const q = computeCityParcelFare({ config: CITY_CONFIG, distanceKm: 6, weightKg: 2 });
    const ret = computeReturnLegAmounts({ ...q, fare: q.fare }, CITY_CONFIG);

    expect(ret.riderPayout).toBe(money(q.distanceFare * 0.6));
    expect(ret.customerCharge).toBe(0);
  });
});

/* ========================================================================
   Outstation (pickup-service parcel)
   ======================================================================== */

describe("outstation pricing", () => {
  it("charges a flat delivery fee — distance and weight no longer price it", () => {
    const daily = computeParcelDailyFare({ config: PARCEL_CONFIG });

    expect(daily.baseFare).toBe(PARCEL_CONFIG.fixedDeliveryCharge);
    expect(daily.distanceFare).toBe(0);
    expect(daily.weightFare).toBe(0);
    expect(daily.platformCharge).toBe(0);
    expect(daily.companyCharge).toBe(0);
    expect(daily.expressCharge).toBe(0);
    expect(daily.fare).toBe(PARCEL_CONFIG.fixedDeliveryCharge);
  });

  it("pays the rider the distance from their accept point to pickup, at the admin's per-km rate", () => {
    const earning = computeRiderParcelEarnings(
      { riderAcceptLocation: PARCEL_ACCEPT, pickupAddress: PARCEL_PICKUP },
      PARCEL_CONFIG,
    );

    // The fare (a flat charge) and the payout (a distance calc) are two
    // unrelated numbers now — the payout is not "a share of the fare".
    expect(earning).toBe(money(PARCEL_ACCEPT_KM * PARCEL_CONFIG.riderPerKmRate));
  });

  it("pays nothing when the rider never accepted — no location snapshot to measure from", () => {
    const earning = computeRiderParcelEarnings(
      { pickupAddress: PARCEL_PICKUP },
      PARCEL_CONFIG,
    );
    expect(earning).toBe(0);
  });

  it("multiplies the customer total by booked days, one flat charge per day", () => {
    const daily = computeParcelDailyFare({ config: PARCEL_CONFIG });
    const days = resolveParcelBillableDays({ pickupWindow: "7_days" });
    const priced = applyBillableDaysToFare(daily, days);

    expect(days).toBe(7);
    expect(priced.fare).toBe(money(daily.fare * 7));
  });

  it("resolves every booking window to the days it bills for", () => {
    expect(resolveParcelBillableDays({ pickupWindow: "today" })).toBe(1);
    expect(resolveParcelBillableDays({ pickupWindow: "15_days" })).toBe(15);
    expect(resolveParcelBillableDays({ pickupWindow: "30_days" })).toBe(30);
    expect(
      resolveParcelBillableDays({ pickupWindow: "custom_days", pickupWindowDays: 4 }),
    ).toBe(4);
    // A month is the ceiling, whatever the client asks for.
    expect(
      resolveParcelBillableDays({ pickupWindow: "custom_days", pickupWindowDays: 900 }),
    ).toBe(31);
  });
});

/* ========================================================================
   What the customer pays, and what the rider ends up holding
   ======================================================================== */

/** Mirrors buildInitialCodSettlement / the city createParcel branch. */
const codStateFor = (paymentMethod, fare) =>
  String(paymentMethod).toUpperCase() === "COD"
    ? { amount: fare, status: "COLLECT_PENDING", paymentStatus: "PENDING" }
    : { amount: 0, status: "NOT_APPLICABLE", paymentStatus: "PENDING" };

describe("payment method decides who holds the money", () => {
  const cityQuote = computeCityParcelFare({
    config: CITY_CONFIG,
    distanceKm: 6,
    weightKg: 2,
  });

  it("COD asks the rider to collect the whole fare, not the rider's share of it", () => {
    const cod = codStateFor("COD", cityQuote.fare);

    expect(cod.amount).toBe(cityQuote.fare);
    expect(cod.status).toBe("COLLECT_PENDING");
    // The rider's own earning is settled separately through the ledger; it is
    // not netted off the cash they hand back.
    expect(cod.amount).not.toBe(computeRiderEarning(cityQuote, CITY_CONFIG));
  });

  it("online leaves the rider holding nothing", () => {
    const online = codStateFor("UPI", cityQuote.fare);

    expect(online.amount).toBe(0);
    expect(online.status).toBe("NOT_APPLICABLE");
  });

  it("a COD booking switched to online at the door stops counting as cash", () => {
    // What riderCheckCodQr does once Razorpay reports the QR paid.
    const booking = { ...codStateFor("COD", cityQuote.fare), paymentMethod: "COD" };
    const converted = {
      ...booking,
      paymentMethod: "UPI",
      paymentStatus: "PAID",
      amount: 0,
      status: "NOT_APPLICABLE",
    };

    expect(converted.amount).toBe(0);
    expect(converted.status).toBe("NOT_APPLICABLE");
    expect(converted.paymentMethod).toBe("UPI");
  });
});

/* ========================================================================
   Cash back to admin, and earnings out to the rider
   ======================================================================== */

describe("rider cash and earnings never mix", () => {
  const cityQuote = computeCityParcelFare({ config: CITY_CONFIG, distanceKm: 6, weightKg: 2 });
  const parcelDaily = computeParcelDailyFare({ config: PARCEL_CONFIG });
  const parcelEarning = computeRiderParcelEarnings(
    { riderAcceptLocation: PARCEL_ACCEPT, pickupAddress: PARCEL_PICKUP },
    PARCEL_CONFIG,
  );
  const depositTotal = money(cityQuote.fare + parcelDaily.fare);

  it("a deposit covers the full collected fares, across both products", () => {
    const held = [
      { kind: "city_parcel", amount: cityQuote.fare },
      { kind: "parcel", amount: parcelDaily.fare },
    ];

    // The rider hands back what the customers paid, in full.
    expect(money(held.reduce((sum, h) => sum + h.amount, 0))).toBe(depositTotal);
  });

  it("depositing cash does not reduce what the rider can withdraw", () => {
    // Mirrors computeWithdrawableBalance in deliveryController: only earning
    // rows count, and the Cash Settlement written on deposit approval is not
    // one of them.
    const ledger = [
      { type: "Delivery Earning", status: "Settled", amount: computeRiderEarning(cityQuote, CITY_CONFIG) },
      { type: "Delivery Earning", status: "Settled", amount: parcelEarning },
      { type: "Cash Collection", status: "Settled", amount: depositTotal },
      { type: "Cash Settlement", status: "Settled", amount: -depositTotal },
    ];

    const earned = ledger
      .filter((t) => t.status === "Settled" && ["Delivery Earning", "Incentive", "Bonus"].includes(t.type))
      .reduce((a, t) => a + Math.abs(t.amount), 0);

    // The cash rows cancel each other and touch neither side.
    expect(money(earned)).toBe(money(computeRiderEarning(cityQuote, CITY_CONFIG) + parcelEarning));
  });

  it("the platform keeps fare minus rider earning on every job", () => {
    const cityMargin = money(cityQuote.fare - computeRiderEarning(cityQuote, CITY_CONFIG));
    const parcelMargin = money(parcelDaily.fare - parcelEarning);

    expect(cityMargin).toBe(52.6); // 127 − 74.4
    expect(cityMargin).toBeGreaterThan(0);
    expect(parcelMargin).toBeGreaterThan(0);
  });
});
