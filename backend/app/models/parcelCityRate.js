import mongoose from "mongoose";

/**
 * Admin-managed rate card: what a given courier company charges to ship a
 * parcel from one city to another. Uploaded in bulk via Excel (see
 * controller/parcelCityRateController.js), one row per (origin, destination)
 * with a charge column per courier company.
 *
 * This is a SEPARATE charge from ParcelConfig.fixedDeliveryCharge — that one
 * pays for the rider's pickup + drop-to-courier-counter service; this one is
 * what the courier itself charges for the onward city-to-city leg, passed
 * straight through to the customer (see fareBreakdown.courierCharge).
 *
 * A route/courier combination with no row here is not bookable — the
 * customer sees "service not available" rather than a fabricated price.
 */
const parcelCityRateSchema = new mongoose.Schema(
  {
    originCity: { type: String, required: true, trim: true },
    /** Lowercased/collapsed-whitespace form of originCity, used for matching. */
    originCityKey: { type: String, required: true, trim: true, lowercase: true, index: true },
    destinationCity: { type: String, required: true, trim: true },
    destinationCityKey: { type: String, required: true, trim: true, lowercase: true, index: true },
    courierCompanyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "CourierCompany",
      required: true,
      index: true,
    },
    charge: { type: Number, required: true, min: 0 },
  },
  { timestamps: true },
);

parcelCityRateSchema.index(
  { originCityKey: 1, destinationCityKey: 1, courierCompanyId: 1 },
  { unique: true },
);

/** Trim + collapse inner whitespace + lowercase — "  Surat" and "surat" match. */
parcelCityRateSchema.statics.normalizeCityKey = function (city) {
  return String(city || "").trim().toLowerCase().replace(/\s+/g, " ");
};

/**
 * The charge for one (origin, destination, courier) combination, or null if
 * unbookable.
 *
 * A courier's price to move a parcel between two cities is the same going
 * either way in practice, and admins were only ever filling in one direction
 * per pair. So a route is bidirectional by default: if the exact direction
 * hasn't been priced, the reverse direction's rate is used instead. An admin
 * who genuinely wants asymmetric pricing (Surat→Indore ≠ Indore→Surat) just
 * adds a row for both directions — an explicit rate for the exact direction
 * always wins over the reverse-direction fallback.
 */
parcelCityRateSchema.statics.findRate = async function (originCity, destinationCity, courierCompanyId) {
  const originCityKey = this.normalizeCityKey(originCity);
  const destinationCityKey = this.normalizeCityKey(destinationCity);
  if (!originCityKey || !destinationCityKey || !courierCompanyId) return null;

  const exact = await this.findOne({
    originCityKey,
    destinationCityKey,
    courierCompanyId,
  }).lean();
  if (exact) return exact;

  if (originCityKey === destinationCityKey) return null;

  return this.findOne({
    originCityKey: destinationCityKey,
    destinationCityKey: originCityKey,
    courierCompanyId,
  }).lean();
};

export default mongoose.model("ParcelCityRate", parcelCityRateSchema);
