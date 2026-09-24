import mongoose from "mongoose";

export const DEFAULT_COURIER_COMPANIES = [
  { name: "Blue Dart", sortOrder: 1 },
  { name: "DTDC", sortOrder: 2 },
  { name: "Delhivery", sortOrder: 3 },
  { name: "India Post", sortOrder: 4 },
  { name: "Ekart", sortOrder: 5 },
  { name: "Ecom Express", sortOrder: 6 },
  { name: "XpressBees", sortOrder: 7 },
  { name: "FedEx", sortOrder: 8 },
  { name: "DHL", sortOrder: 9 },
  { name: "Shadowfax", sortOrder: 10 },
];

/**
 * A courier company is now purely informational — a name/contact the customer
 * picks at booking so the rider knows who to ask for at the counter. The rider
 * physically drives the parcel there and drops it with a photo proof; there is
 * no address or coordinates to dispatch or navigate against, and no charge
 * tied to the choice (see utils/parcelFare.js — price is a flat delivery
 * charge regardless of courier).
 */
const courierCompanySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    /** Contact number printed for the rider — who to ask for at the counter. */
    phone: {
      type: String,
      trim: true,
      default: "",
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    /**
     * Marks the special "Other" catch-all option. Customers pick this and type
     * their own courier company name. There should be exactly one such document.
     */
    isOther: {
      type: Boolean,
      default: false,
      index: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    /**
     * Delivery zones this courier is offered in on the customer's zone-filtered
     * dropdown (see listActiveForZones). Empty means "not tied to a zone" — it
     * still only appears when an admin has actually assigned it somewhere via
     * this list; `allZones` and the "Other" catch-all are the two exceptions
     * that are always offered regardless of zone.
     */
    zoneIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "DeliveryZone",
      },
    ],
    /**
     * When true, this courier is offered in every zone — the admin's "All
     * Zones" pick instead of hand-selecting each one. `zoneIds` is ignored
     * while this is set (kept in the document in case the admin later
     * switches back to specific zones).
     */
    allZones: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true },
);

/**
 * Fields retired when a courier company stopped carrying a charge or a
 * pinned office address (see the doc comment above — it's name/phone/zones
 * now). Mongo keeps whatever was last written until explicitly unset, so a
 * document saved before this migration otherwise carries this dead weight
 * in every API response forever.
 */
let legacyFieldsCleaned = false;
courierCompanySchema.statics.cleanupLegacyFields = async function () {
  if (legacyFieldsCleaned) return;
  legacyFieldsCleaned = true;
  await this.collection.updateMany(
    {},
    { $unset: { platformCharge: "", companyCharge: "", location: "" } },
  );
};

courierCompanySchema.statics.ensureDefaults = async function () {
  const count = await this.countDocuments();
  if (count > 0) return;
  await this.insertMany(
    DEFAULT_COURIER_COMPANIES.map((c) => ({
      name: c.name,
      sortOrder: c.sortOrder,
      isActive: true,
    })),
  );
};

/**
 * Ensure the single "Other" catch-all courier option exists. Customers can pick
 * it to type a custom company name.
 */
courierCompanySchema.statics.ensureOtherOption = async function () {
  const existing = await this.findOne({ isOther: true });
  if (existing) return existing;
  return this.create({
    name: "Other",
    sortOrder: 9999,
    isActive: true,
    isOther: true,
  });
};

courierCompanySchema.statics.listActiveForBooking = async function () {
  await this.cleanupLegacyFields();
  await this.ensureDefaults();
  await this.ensureOtherOption();
  return this.find({ isActive: true })
    .sort({ sortOrder: 1, name: 1 })
    .select("_id name phone isOther zoneIds allZones")
    .lean();
};

/**
 * Active couriers offered in the given zone(s), plus `allZones` couriers and
 * the "Other" catch-all — both always available regardless of zone. Used by
 * the customer-facing zone-filtered dropdown (see
 * controller/courierCompanyController.js).
 */
courierCompanySchema.statics.listActiveForZones = async function (zoneIds = []) {
  await this.cleanupLegacyFields();
  await this.ensureDefaults();
  await this.ensureOtherOption();
  const ids = (Array.isArray(zoneIds) ? zoneIds : []).filter(Boolean).map(String);
  const or = [{ isOther: true }, { allZones: true }];
  if (ids.length) or.push({ zoneIds: { $in: ids } });

  return this.find({
    isActive: true,
    $or: or,
  })
    .sort({ sortOrder: 1, name: 1 })
    .select("_id name phone isOther zoneIds allZones")
    .lean();
};

courierCompanySchema.statics.findActiveByNameOrId = async function (nameOrId) {
  await this.ensureDefaults();
  const raw = String(nameOrId || "").trim();
  if (!raw) return null;

  if (mongoose.Types.ObjectId.isValid(raw) && String(new mongoose.Types.ObjectId(raw)) === raw) {
    const byId = await this.findOne({ _id: raw, isActive: true }).lean();
    if (byId) return byId;
  }

  return this.findOne({
    name: new RegExp(`^${raw.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i"),
    isActive: true,
  }).lean();
};

export default mongoose.model("CourierCompany", courierCompanySchema);
