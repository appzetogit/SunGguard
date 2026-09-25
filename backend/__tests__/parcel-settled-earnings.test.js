import mongoose from "mongoose";
import { MongoMemoryServer } from "mongodb-memory-server";
import Transaction from "../app/models/transaction.js";
import { getSettledParcelEarnings } from "../app/services/parcelRiderSettlementService.js";

/**
 * A delivered parcel's "Your Earning" must show the amount actually credited
 * to the rider's wallet, not a fresh recompute against today's per-km rate —
 * otherwise the order-history figure and the real Delivery Earning
 * transaction in Recent Earnings silently disagree (see
 * withRiderEarningBreakdown in parcelController.js, which reads this map).
 */

let mongod;

beforeAll(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

afterEach(async () => {
  await Transaction.deleteMany({});
});

describe("getSettledParcelEarnings", () => {
  const riderId = new mongoose.Types.ObjectId();

  it("returns the settled amount for each delivered parcel, keyed by parcel id", async () => {
    const parcelId1 = new mongoose.Types.ObjectId();
    const parcelId2 = new mongoose.Types.ObjectId();

    await Transaction.create([
      {
        user: riderId,
        userModel: "Delivery",
        type: "Delivery Earning",
        reference: `PCL-ERN-${parcelId1}`,
        amount: 80,
        date: new Date(),
      },
      {
        user: riderId,
        userModel: "Delivery",
        type: "Delivery Earning",
        reference: `PCL-ERN-${parcelId2}`,
        amount: 0.01,
        date: new Date(),
      },
    ]);

    const map = await getSettledParcelEarnings([parcelId1, parcelId2]);

    expect(map.get(String(parcelId1))).toBe(80);
    expect(map.get(String(parcelId2))).toBe(0.01);
  });

  it("omits a parcel with no settled transaction rather than inventing one", async () => {
    const unsettledId = new mongoose.Types.ObjectId();
    const map = await getSettledParcelEarnings([unsettledId]);
    expect(map.has(String(unsettledId))).toBe(false);
  });

  it("ignores a same-reference row of a different type (e.g. a cash entry)", async () => {
    const parcelId = new mongoose.Types.ObjectId();
    await Transaction.create({
      user: riderId,
      userModel: "Delivery",
      type: "Cash Collection",
      reference: `PCL-ERN-${parcelId}`,
      amount: 200,
      date: new Date(),
    });

    const map = await getSettledParcelEarnings([parcelId]);
    expect(map.has(String(parcelId))).toBe(false);
  });

  it("returns an empty map for an empty input", async () => {
    const map = await getSettledParcelEarnings([]);
    expect(map.size).toBe(0);
  });
});
