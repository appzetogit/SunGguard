import mongoose from "mongoose";
import CourierCompany from "../models/courierCompany.js";
import handleResponse from "../utils/helper.js";
import { zonesForPoint } from "../services/deliveryZoneService.js";

/** Indian mobile: 10 digits starting 6-9, with an optional +91 / 0 prefix. */
const PHONE_PATTERN = /^(?:\+?91[-\s]?|0)?[6-9]\d{9}$/;

/** Structural zoneIds validation, same shape the delivery-boy zone assignment uses. */
function normalizeZoneIds(input) {
  if (!Array.isArray(input)) return { ids: [], error: null };
  const ids = [];
  for (const raw of input) {
    const id = String(raw || "").trim();
    if (!id) continue;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return { ids: [], error: "One of the selected zones is not valid" };
    }
    ids.push(id);
  }
  return { ids, error: null };
}

export const adminListCourierCompanies = async (req, res) => {
  try {
    // Do not auto-reseed here — otherwise deleting the last company
    // (or emptying the list) would immediately recreate defaults.
    // The "Other" catch-all option is always ensured so the admin can manage it.
    await CourierCompany.cleanupLegacyFields();
    await CourierCompany.ensureOtherOption();
    const companies = await CourierCompany.find()
      .select("name phone isActive isOther sortOrder zoneIds allZones createdAt updatedAt")
      .sort({ sortOrder: 1, name: 1 })
      .lean();
    return handleResponse(res, 200, "Courier companies retrieved", companies);
  } catch (error) {
    return handleResponse(res, 500, error.message);
  }
};

export const adminCreateCourierCompany = async (req, res) => {
  try {
    const name = String(req.body?.name || "").trim();
    const phoneRaw = String(req.body?.phone || "").trim();
    const sortOrder = Number.isFinite(Number(req.body?.sortOrder))
      ? Number(req.body.sortOrder)
      : 0;
    const isActive = req.body?.isActive !== false && req.body?.isActive !== "false";

    if (!name) {
      return handleResponse(res, 400, "Courier company name is required");
    }
    if (phoneRaw && !PHONE_PATTERN.test(phoneRaw)) {
      return handleResponse(res, 400, "Enter a valid 10-digit mobile number");
    }

    const { ids: zoneIds, error: zoneError } = normalizeZoneIds(req.body?.zoneIds);
    if (zoneError) {
      return handleResponse(res, 400, zoneError);
    }
    const allZones = req.body?.allZones === true || req.body?.allZones === "true";

    const existing = await CourierCompany.findOne({
      name: new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i"),
    }).lean();
    if (existing) {
      return handleResponse(res, 400, "A courier company with this name already exists");
    }

    const company = await CourierCompany.create({
      name,
      phone: phoneRaw,
      sortOrder,
      isActive,
      zoneIds: allZones ? [] : zoneIds,
      allZones,
    });

    return handleResponse(res, 201, "Courier company created", company);
  } catch (error) {
    if (error?.code === 11000) {
      return handleResponse(res, 400, "A courier company with this name already exists");
    }
    return handleResponse(res, 500, error.message);
  }
};

export const adminUpdateCourierCompany = async (req, res) => {
  try {
    const { id } = req.params;
    const company = await CourierCompany.findById(id);
    if (!company) {
      return handleResponse(res, 404, "Courier company not found");
    }

    // The "Other" catch-all option keeps its fixed name — customers type their own.
    if (req.body?.name !== undefined && !company.isOther) {
      const name = String(req.body.name || "").trim();
      if (!name) {
        return handleResponse(res, 400, "Courier company name is required");
      }
      const duplicate = await CourierCompany.findOne({
        _id: { $ne: company._id },
        name: new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i"),
      }).lean();
      if (duplicate) {
        return handleResponse(res, 400, "A courier company with this name already exists");
      }
      company.name = name;
    }

    if (req.body?.phone !== undefined) {
      const phoneRaw = String(req.body.phone || "").trim();
      if (phoneRaw && !PHONE_PATTERN.test(phoneRaw)) {
        return handleResponse(res, 400, "Enter a valid 10-digit mobile number");
      }
      company.phone = phoneRaw;
    }
    if (req.body?.sortOrder !== undefined) {
      company.sortOrder = Number(req.body.sortOrder) || 0;
    }
    if (req.body?.isActive !== undefined) {
      company.isActive = req.body.isActive === true || req.body.isActive === "true";
    }
    if (req.body?.allZones !== undefined) {
      company.allZones = req.body.allZones === true || req.body.allZones === "true";
    }
    if (req.body?.zoneIds !== undefined) {
      const { ids: zoneIds, error: zoneError } = normalizeZoneIds(req.body.zoneIds);
      if (zoneError) {
        return handleResponse(res, 400, zoneError);
      }
      company.zoneIds = zoneIds;
    }
    // allZones ignores zoneIds on the read side, but keep them empty together
    // so the admin list doesn't show a stale zone selection under "All Zones".
    if (company.allZones) {
      company.zoneIds = [];
    }

    await company.save();
    return handleResponse(res, 200, "Courier company updated", company);
  } catch (error) {
    if (error?.code === 11000) {
      return handleResponse(res, 400, "A courier company with this name already exists");
    }
    return handleResponse(res, 500, error.message);
  }
};

export const adminDeleteCourierCompany = async (req, res) => {
  try {
    const { id } = req.params;
    const existing = await CourierCompany.findById(id);
    if (!existing) {
      return handleResponse(res, 404, "Courier company not found");
    }
    if (existing.isOther) {
      return handleResponse(
        res,
        400,
        "The 'Other' option cannot be deleted. Deactivate it instead if you want to hide it.",
      );
    }
    const company = await CourierCompany.findByIdAndDelete(id);
    return handleResponse(res, 200, "Courier company deleted", { id: company._id });
  } catch (error) {
    return handleResponse(res, 500, error.message);
  }
};

/**
 * Customer-facing: couriers offered at a given pickup point, filtered to the
 * delivery zone(s) that point resolves into (plus the "Other" catch-all,
 * always available). Unzoned installs (no active zones drawn yet) get every
 * active courier, same fallback every other zone-gated flow uses.
 */
export const listCouriersForLocation = async (req, res) => {
  try {
    const lat = Number(req.query.lat);
    const lng = Number(req.query.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return handleResponse(res, 400, "lat and lng are required");
    }

    const zones = await zonesForPoint(lat, lng);
    const zoneIds = zones.map((z) => String(z._id));

    const companies = zoneIds.length
      ? await CourierCompany.listActiveForZones(zoneIds)
      : await CourierCompany.listActiveForBooking();

    return handleResponse(res, 200, "Couriers retrieved", companies);
  } catch (error) {
    return handleResponse(res, 500, error.message);
  }
};
