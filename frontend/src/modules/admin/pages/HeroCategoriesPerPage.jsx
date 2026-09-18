import React, { useEffect, useState } from "react";
import {
  HiOutlinePencilSquare,
  HiOutlinePhoto,
  HiOutlinePlus,
  HiOutlineXMark,
} from "react-icons/hi2";
import { adminApi } from "../services/adminApi";
import Card from "@shared/components/ui/Card";
import Modal from "@shared/components/ui/Modal";
import PageHeader from "@shared/components/ui/PageHeader";
import { useToast } from "@shared/components/ui/Toast";
import { cn } from "@/lib/utils";
import { Loader2 } from "lucide-react";

const emptyBannerItem = () => ({
  imageUrl: "",
  title: "",
  subtitle: "",
  linkType: "none",
  linkValue: "",
  isUploading: false,
});

export default function HeroCategoriesPerPage() {
  const { showToast } = useToast();
  const [headers, setHeaders] = useState([]);
  const [allCategories, setAllCategories] = useState([]);
  const [pageData, setPageData] = useState([]);
  const [loading, setLoading] = useState(true);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingRow, setEditingRow] = useState(null);
  const [formBanners, setFormBanners] = useState([emptyBannerItem()]);
  const [formCategoryIds, setFormCategoryIds] = useState([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      setLoading(true);
      try {
        const treeRes = await adminApi.getCategoryTree();
        const tree = treeRes.data?.results || treeRes.data?.result || [];
        const headerList = Array.isArray(tree) ? tree : [];
        if (cancelled) return;
        setHeaders(headerList);

        const flatCategories = headerList.flatMap((h) => (h.children || []).map((c) => ({ ...c, headerName: h.name })));
        setAllCategories(flatCategories);

        const homeRes = await adminApi.getHeroConfig({ pageType: "home" });
        const homeResult = homeRes.data?.result || homeRes.data || {};
        const homeBanners = homeResult.banners?.items || [];
        const homeCatIds = homeResult.categoryIds || [];

        const rows = [
          {
            id: "home",
            label: "Home",
            pageType: "home",
            headerId: null,
            bannerCount: homeBanners.length,
            categoryCount: homeCatIds.length,
          },
        ];

        await Promise.all(
          headerList.map(async (h) => {
            const res = await adminApi.getHeroConfig({
              pageType: "header",
              headerId: h._id,
            });
            if (cancelled) return;
            const result = res.data?.result || res.data || {};
            const items = result.banners?.items || [];
            const catIds = result.categoryIds || [];
            rows.push({
              id: h._id,
              label: h.name || "Unnamed",
              pageType: "header",
              headerId: h._id,
              bannerCount: items.length,
              categoryCount: catIds.length,
            });
          })
        );

        if (!cancelled) setPageData(rows);
      } catch (e) {
        if (!cancelled) console.error(e);
        showToast("Failed to load hero config", "error");
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    load();
    return () => { cancelled = true; };
  }, [showToast]);

  const openEdit = async (row) => {
    setEditingRow(row);
    setFormCategoryIds([]);
    setFormBanners([emptyBannerItem()]);
    try {
      const res = await adminApi.getHeroConfig({
        pageType: row.pageType,
        headerId: row.headerId || undefined,
      });
      const result = res.data?.result || res.data || {};
      const items = result.banners?.items || [];
      const catIds = result.categoryIds || [];
      setFormBanners(
        items.length
          ? items.map((b) => ({ ...b, isUploading: false }))
          : [emptyBannerItem()]
      );
      setFormCategoryIds(Array.isArray(catIds) ? catIds : []);
    } catch (e) {
      console.error(e);
    }
    setModalOpen(true);
  };

  const updateBannerItem = (idx, changes) => {
    setFormBanners((prev) => {
      const next = [...prev];
      next[idx] = { ...next[idx], ...changes };
      return next;
    });
  };

  const addBannerItem = () => {
    setFormBanners((prev) => [...prev, emptyBannerItem()]);
  };

  const removeBannerItem = (idx) => {
    setFormBanners((prev) => prev.filter((_, i) => i !== idx));
  };

  const handleBannerFileChange = async (idx, file) => {
    if (!file) return;
    updateBannerItem(idx, { isUploading: true });
    try {
      const fd = new FormData();
      fd.append("image", file);
      const res = await adminApi.uploadExperienceBanner(fd);
      const url = res.data?.result?.url || res.data?.url;
      if (!url) throw new Error("Upload failed");
      updateBannerItem(idx, { imageUrl: url, isUploading: false });
      showToast("Banner image uploaded", "success");
    } catch (e) {
      console.error(e);
      updateBannerItem(idx, { isUploading: false });
      showToast("Failed to upload banner image", "error");
    }
  };

  const toggleCategory = (catId) => {
    setFormCategoryIds((prev) =>
      prev.includes(catId) ? prev.filter((id) => id !== catId) : [...prev, catId]
    );
  };

  const handleSave = async () => {
    const items = formBanners.filter((b) => b.imageUrl).map((b) => ({
      imageUrl: b.imageUrl,
      title: b.title || "",
      subtitle: b.subtitle || "",
      linkType: b.linkType || "none",
      linkValue: b.linkValue || "",
      status: b.status || "active",
    }));

    if (!editingRow) return;
    setSaving(true);
    try {
      await adminApi.setHeroConfig({
        pageType: editingRow.pageType,
        headerId: editingRow.headerId || undefined,
        banners: { items },
        categoryIds: formCategoryIds,
      });
      showToast("Hero config saved", "success");
      setPageData((prev) =>
        prev.map((p) =>
          p.id === editingRow.id
            ? {
                ...p,
                bannerCount: items.length,
                categoryCount: formCategoryIds.length,
              }
            : p
        )
      );
      setModalOpen(false);
      setEditingRow(null);
    } catch (e) {
      console.error(e);
      showToast(e.response?.data?.message || "Failed to save", "error");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="ds-section-spacing max-w-4xl">
      <PageHeader
        title="Hero & categories per page"
        description={
          <>
            Configure the <strong>separate</strong> hero banners and categories strip at the top of each page.
            If a header page has no config, the storefront shows the home page hero and categories.
            Create Sections are for the main content area only.
          </>
        }
      />

      <Card className="overflow-hidden relative min-h-[200px]" contentClassName="p-0">
        {loading && (
          <div className="absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center">
            <div className="flex flex-col items-center gap-2">
              <Loader2 className="h-8 w-8 text-primary animate-spin" />
              <p className="ds-caption text-gray-500 font-medium">Loading pages...</p>
            </div>
          </div>
        )}
        <div className="overflow-x-auto">
          <table className="ds-table">
            <thead className="ds-table-header">
              <tr>
                <th className="ds-table-header-cell">Page</th>
                <th className="ds-table-header-cell">Hero (top banners)</th>
                <th className="ds-table-header-cell">Categories below hero</th>
                <th className="ds-table-header-cell text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {!loading && pageData.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-20 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="p-4 bg-gray-50 rounded-full">
                        <HiOutlinePhoto className="h-8 w-8 text-gray-300" />
                      </div>
                      <p className="ds-h4 text-gray-400">No pages found</p>
                    </div>
                  </td>
                </tr>
              ) : (
                pageData.map((row) => (
                  <tr
                    key={row.id}
                    className={cn("ds-table-row hover:bg-slate-50/70 transition-colors")}
                  >
                    <td className="ds-table-cell">
                      <span className="font-semibold text-slate-800">{row.label}</span>
                    </td>
                    <td className="ds-table-cell">
                      {row.bannerCount > 0 ? (
                        <span className="text-sm font-medium text-slate-600">
                          {row.bannerCount} banner(s)
                        </span>
                      ) : (
                        <span className="text-sm text-slate-400 italic">Not set</span>
                      )}
                    </td>
                    <td className="ds-table-cell">
                      {row.categoryCount > 0 ? (
                        <span className="text-sm font-medium text-slate-600">
                          {row.categoryCount} categor
                          {row.categoryCount === 1 ? "y" : "ies"}
                        </span>
                      ) : (
                        <span className="text-sm text-slate-400 italic">Not set</span>
                      )}
                    </td>
                    <td className="ds-table-cell text-right">
                      <button
                        type="button"
                        onClick={() => openEdit(row)}
                        className="p-2 bg-primary/10 text-primary rounded-lg hover:bg-primary hover:text-white transition-all inline-flex items-center gap-1.5"
                      >
                        <HiOutlinePencilSquare className="ds-icon-sm" />
                        <span className="ds-caption">Edit</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      <p className="text-xs text-slate-400">
        This is a <strong>separate</strong> hero section. Experience sections in Create Sections
        are unchanged and used for the main content area below.
      </p>

      <Modal
        isOpen={modalOpen}
        onClose={() => !saving && setModalOpen(false)}
        title={editingRow ? `Edit hero & categories — ${editingRow.label}` : "Edit"}
        size="xl"
        footer={
          <div className="flex gap-2 justify-end">
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              disabled={saving}
              className="ds-btn ds-btn-md text-slate-600 hover:bg-slate-100 disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className="ds-btn ds-btn-md bg-primary text-primary-foreground shadow-lg shadow-primary/20 disabled:opacity-50"
            >
              {saving ? "Saving…" : "Save"}
            </button>
          </div>
        }
      >
        {editingRow && (
          <div className="space-y-6">
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                  Hero banners
                </label>
                <button
                  type="button"
                  onClick={addBannerItem}
                  className="flex items-center gap-1 text-[10px] font-bold text-primary"
                >
                  <HiOutlinePlus className="h-3 w-3" />
                  Add banner
                </button>
              </div>
              <div className="space-y-3 max-h-48 overflow-y-auto">
                {formBanners.map((item, idx) => (
                  <Card key={idx} className="p-3 bg-white border-slate-100">
                    <div className="flex items-start gap-3">
                      <div className="flex-1 space-y-2">
                        <div className="flex items-center gap-3">
                          <div className="w-16 h-16 rounded-xl bg-slate-50 border border-slate-200 overflow-hidden flex items-center justify-center shrink-0">
                            {item.imageUrl ? (
                              <img
                                src={item.imageUrl}
                                alt={item.title || `Banner ${idx + 1}`}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <HiOutlinePhoto className="h-6 w-6 text-slate-300" />
                            )}
                          </div>
                          <div className="flex-1 min-w-0 space-y-1">
                            <input
                              type="file"
                              accept="image/*"
                              className="hidden"
                              id={`hero-banner-file-${idx}`}
                              onChange={(e) => handleBannerFileChange(idx, e.target.files?.[0])}
                            />
                            <label
                              htmlFor={`hero-banner-file-${idx}`}
                              className="inline-block px-2 py-1 rounded-lg bg-slate-100 text-[10px] font-bold text-slate-600 cursor-pointer hover:bg-slate-200"
                            >
                              {item.isUploading ? "Uploading…" : item.imageUrl ? "Change" : "Upload"}
                            </label>
                            <input
                              value={item.title || ""}
                              onChange={(e) => updateBannerItem(idx, { title: e.target.value })}
                              className="w-full p-2 bg-slate-50 rounded-xl text-xs font-bold border-none outline-none"
                              placeholder="Title (optional)"
                            />
                            <input
                              value={item.subtitle || ""}
                              onChange={(e) => updateBannerItem(idx, { subtitle: e.target.value })}
                              className="w-full p-2 bg-slate-50 rounded-xl text-xs font-bold border-none outline-none"
                              placeholder="Subtitle (optional)"
                            />
                          </div>
                        </div>
                      </div>
                      {formBanners.length > 1 && (
                        <button
                          type="button"
                          onClick={() => removeBannerItem(idx)}
                          className="p-2 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all"
                        >
                          <HiOutlineXMark className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </Card>
                ))}
              </div>
            </div>

            <div>
              <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-2">
                Categories below hero
              </label>
              <div className="flex flex-wrap gap-2">
                {allCategories.map((c) => {
                  const isSelected = formCategoryIds.includes(c._id);
                  return (
                    <button
                      key={c._id}
                      type="button"
                      onClick={() => toggleCategory(c._id)}
                      className={cn(
                        "px-3 py-1.5 rounded-full text-[11px] font-bold border transition-all",
                        isSelected
                          ? "bg-primary text-primary-foreground border-primary"
                          : "bg-slate-50 text-slate-600 border-slate-200 hover:bg-white"
                      )}
                    >
                      {c.name}
                    </button>
                  );
                })}
              </div>
              {allCategories.length === 0 && (
                <p className="text-xs text-slate-400">No main categories found. Add categories in Header / Main Categories first.</p>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

