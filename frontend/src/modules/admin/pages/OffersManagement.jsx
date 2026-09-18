import React, { useEffect, useMemo, useState } from 'react';
import Card from '@shared/components/ui/Card';
import Badge from '@shared/components/ui/Badge';
import Modal from '@shared/components/ui/Modal';
import PageHeader from '@shared/components/ui/PageHeader';
import StatCard from '@shared/components/ui/StatCard';
import { useToast } from '@shared/components/ui/Toast';
import {
    HiOutlinePlus,
    HiOutlineTag,
    HiOutlineSparkles,
    HiOutlineClock,
    HiOutlineTrash,
    HiOutlinePencilSquare,
    HiOutlineArrowUpCircle,
    HiOutlineArrowDownCircle,
} from 'react-icons/hi2';
import { Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { adminApi } from '../services/adminApi';

const STYLE_OPTIONS = [
    { id: 'blue', label: 'Blue', className: 'bg-black ' },
    { id: 'green', label: 'Green', className: 'bg-primary' },
    { id: 'orange', label: 'Orange', className: 'bg-orange-500' },
];

const ICON_OPTIONS = [
    { id: 'sparkles', label: 'Sparkles', icon: HiOutlineSparkles },
    { id: 'clock', label: 'Timer', icon: HiOutlineClock },
    { id: 'tag', label: 'Tag', icon: HiOutlineTag },
];

const OffersManagement = () => {
    const { showToast } = useToast();
    const [offers, setOffers] = useState([]);
    const [isLoading, setIsLoading] = useState(false);

    const [categories, setCategories] = useState([]);
    const [products, setProducts] = useState([]);

    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingOffer, setEditingOffer] = useState(null);
    const [formData, setFormData] = useState({
        title: '',
        description: '',
        code: '',
        style: 'blue',
        icon: 'sparkles',
        appliesOnOrderNumber: 1,
        order: 0,
        status: 'active',
        categoryIds: [],
        productIds: [],
    });

    const loadMasterData = async () => {
        try {
            const [catRes, prodRes] = await Promise.all([
                adminApi.getCategories(),
                adminApi.getProducts({ limit: 100 }),
            ]);

            const catList = catRes.data.results || catRes.data.result || [];
            setCategories(Array.isArray(catList) ? catList.filter(c => c.type === 'category') : []);

            const rawResult = prodRes.data.result;
            const prodList = Array.isArray(prodRes.data.results)
                ? prodRes.data.results
                : Array.isArray(rawResult?.items)
                    ? rawResult.items
                    : Array.isArray(rawResult)
                        ? rawResult
                        : [];
            setProducts(prodList);
        } catch (e) {
            console.error(e);
            showToast('Failed to load products or categories', 'error');
        }
    };

    const loadOffers = async () => {
        setIsLoading(true);
        try {
            const res = await adminApi.getOffers();
            const list = res.data.results || res.data.result || res.data;
            setOffers(Array.isArray(list) ? list : []);
        } catch (e) {
            console.error(e);
            showToast('Failed to load offers', 'error');
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadMasterData();
        loadOffers();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const resetForm = () => {
        setFormData({
            title: '',
            description: '',
            code: '',
            style: 'blue',
            icon: 'sparkles',
            appliesOnOrderNumber: 1,
            order: offers.length,
            status: 'active',
            categoryIds: [],
            productIds: [],
        });
    };

    const openCreateModal = () => {
        setEditingOffer(null);
        resetForm();
        setIsModalOpen(true);
    };

    const openEditModal = (offer) => {
        setEditingOffer(offer);
        setFormData({
            title: offer.title || '',
            description: offer.description || '',
            code: offer.code || '',
            style: offer.style || 'blue',
            icon: offer.icon || 'sparkles',
            appliesOnOrderNumber: offer.appliesOnOrderNumber || 1,
            order: typeof offer.order === 'number' ? offer.order : 0,
            status: offer.status || 'active',
            categoryIds: offer.categoryIds || [],
            productIds: offer.productIds || [],
        });
        setIsModalOpen(true);
    };

    const handleSave = async (e) => {
        e.preventDefault();
        if (!formData.title.trim()) {
            showToast('Please enter offer title', 'warning');
            return;
        }

        const payload = {
            ...formData,
            appliesOnOrderNumber: Number(formData.appliesOnOrderNumber) || 1,
            order: Number(formData.order) || 0,
        };

        try {
            if (editingOffer) {
                const res = await adminApi.updateOffer(editingOffer._id, payload);
                const updated = res.data.result || res.data.results || res.data;
                setOffers(prev => prev.map(o => (o._id === editingOffer._id ? updated : o)));
                showToast('Offer updated', 'success');
            } else {
                const res = await adminApi.createOffer(payload);
                const created = res.data.result || res.data.results || res.data;
                setOffers(prev => [...prev, created]);
                showToast('Offer created', 'success');
            }
            setIsModalOpen(false);
        } catch (e) {
            console.error(e);
            showToast(e.response?.data?.message || 'Failed to save offer', 'error');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Delete this offer?')) return;
        try {
            await adminApi.deleteOffer(id);
            setOffers(prev => prev.filter(o => o._id !== id));
            showToast('Offer deleted', 'success');
        } catch (e) {
            console.error(e);
            showToast('Failed to delete offer', 'error');
        }
    };

    const handleReorder = async (direction, offer) => {
        const index = offers.findIndex(o => o._id === offer._id);
        if (index < 0) return;
        const newIndex = direction === 'up' ? index - 1 : index + 1;
        if (newIndex < 0 || newIndex >= offers.length) return;

        const copy = [...offers];
        const [removed] = copy.splice(index, 1);
        copy.splice(newIndex, 0, removed);

        const items = copy.map((o, idx) => ({ id: o._id, order: idx }));

        try {
            await adminApi.reorderOffers(items);
            setOffers(copy.map((o, idx) => ({ ...o, order: idx })));
        } catch (e) {
            console.error(e);
            showToast('Failed to reorder offers', 'error');
        }
    };

    const categoryMap = useMemo(() => {
        const map = {};
        categories.forEach(c => {
            map[c._id] = c;
        });
        return map;
    }, [categories]);

    const productMap = useMemo(() => {
        const map = {};
        products.forEach(p => {
            map[p._id] = p;
        });
        return map;
    }, [products]);

    const stats = useMemo(() => {
        const active = offers.filter(o => o.status === 'active').length;
        return {
            total: offers.length,
            active,
            inactive: offers.length - active,
        };
    }, [offers]);

    return (
        <div className="ds-section-spacing">
            <PageHeader
                title="Offers Manager"
                description="Create offer cards, attach products & categories, and control the order they appear."
                badge={
                    <Badge variant="primary" className="text-[10px] font-black uppercase tracking-widest">
                        Beta
                    </Badge>
                }
                actions={
                    <button
                        onClick={openCreateModal}
                        className="ds-btn ds-btn-md bg-primary text-primary-foreground shadow-lg shadow-primary/20"
                    >
                        <HiOutlinePlus className="ds-icon-sm" />
                        NEW OFFER
                    </button>
                }
            />

            <div className="ds-grid-cards-3">
                <StatCard
                    label="Total Offers"
                    value={stats.total}
                    icon={HiOutlineTag}
                    color="text-brand-600"
                    bg="bg-brand-50"
                />
                <StatCard
                    label="Active"
                    value={stats.active}
                    icon={HiOutlineSparkles}
                    color="text-emerald-600"
                    bg="bg-emerald-50"
                />
                <StatCard
                    label="Inactive"
                    value={stats.inactive}
                    icon={HiOutlineClock}
                    color="text-slate-500"
                    bg="bg-slate-100"
                />
            </div>

            <Card className="overflow-hidden relative min-h-[160px]">
                {isLoading && (
                    <div className="absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center">
                        <div className="flex flex-col items-center gap-2">
                            <Loader2 className="h-8 w-8 text-primary animate-spin" />
                            <p className="ds-caption text-gray-500 font-medium">Loading offers...</p>
                        </div>
                    </div>
                )}
                <div className="p-4 border-b border-slate-50 flex items-center justify-between">
                    <h2 className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        Active Offers ({offers.length})
                    </h2>
                </div>

                <div className="divide-y divide-slate-50">
                    {offers.map((offer, idx) => {
                        const styleMeta = STYLE_OPTIONS.find(s => s.id === offer.style) || STYLE_OPTIONS[0];
                        const iconMeta = ICON_OPTIONS.find(i => i.id === offer.icon) || ICON_OPTIONS[0];
                        const IconComp = iconMeta.icon;

                        return (
                            <div
                                key={offer._id}
                                className="px-4 py-4 flex flex-col md:flex-row md:items-center gap-4 hover:bg-slate-50/40 transition-colors"
                            >
                                <div className="flex items-center gap-3 md:w-[260px]">
                                    <div className={cn(
                                        "h-12 w-12 rounded-2xl flex items-center justify-center text-white",
                                        styleMeta.className
                                    )}>
                                        <IconComp className="h-6 w-6" />
                                    </div>
                                    <div>
                                        <p className="text-xs font-black text-slate-900">
                                            #{idx + 1} • {offer.title}
                                        </p>
                                        {offer.code && (
                                            <p className="text-[10px] font-mono font-bold text-slate-500 mt-0.5">
                                                CODE: {offer.code}
                                            </p>
                                        )}
                                        {offer.appliesOnOrderNumber && (
                                            <p className="text-[10px] font-bold text-brand-600 mt-0.5">
                                                On order #{offer.appliesOnOrderNumber}
                                            </p>
                                        )}
                                    </div>
                                </div>

                                <div className="flex-1 grid grid-cols-1 md:grid-cols-3 gap-3 text-[11px]">
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                                            Categories
                                        </p>
                                        <div className="flex flex-wrap gap-1.5">
                                            {(offer.categoryIds || []).map(id => (
                                                <span
                                                    key={id}
                                                    className="px-2 py-1 rounded-full bg-slate-100 text-[10px] font-bold text-slate-700"
                                                >
                                                    {categoryMap[id]?.name || 'Unknown'}
                                                </span>
                                            ))}
                                            {(!offer.categoryIds || offer.categoryIds.length === 0) && (
                                                <span className="text-[10px] text-slate-400">None selected</span>
                                            )}
                                        </div>
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                                            Products
                                        </p>
                                        <div className="flex flex-wrap gap-1.5">
                                            {(offer.productIds || []).slice(0, 3).map(id => (
                                                <span
                                                    key={id}
                                                    className="px-2 py-1 rounded-full bg-slate-100 text-[10px] font-bold text-slate-700"
                                                >
                                                    {productMap[id]?.name || 'Product'}
                                                </span>
                                            ))}
                                            {offer.productIds && offer.productIds.length > 3 && (
                                                <span className="text-[10px] text-slate-500">
                                                    +{offer.productIds.length - 3} more
                                                </span>
                                            )}
                                            {(!offer.productIds || offer.productIds.length === 0) && (
                                                <span className="text-[10px] text-slate-400">None selected</span>
                                            )}
                                        </div>
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                                            Meta
                                        </p>
                                        <div className="flex items-center gap-3">
                                            <span className="text-[10px] font-bold text-slate-500">
                                                Order: {offer.order ?? idx}
                                            </span>
                                            <Badge
                                                variant={offer.status === 'active' ? 'success' : 'gray'}
                                                className="text-[9px] font-black uppercase"
                                            >
                                                {offer.status}
                                            </Badge>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex items-center gap-2 self-start md:self-stretch md:flex-col md:justify-between">
                                    <div className="flex items-center gap-1">
                                        <button
                                            disabled={idx === 0}
                                            onClick={() => handleReorder('up', offer)}
                                            className={cn(
                                                "p-1.5 rounded-xl border text-slate-400 hover:text-slate-700 hover:bg-slate-50 transition-all",
                                                idx === 0 && "opacity-30 cursor-not-allowed"
                                            )}
                                        >
                                            <HiOutlineArrowUpCircle className="h-4 w-4" />
                                        </button>
                                        <button
                                            disabled={idx === offers.length - 1}
                                            onClick={() => handleReorder('down', offer)}
                                            className={cn(
                                                "p-1.5 rounded-xl border text-slate-400 hover:text-slate-700 hover:bg-slate-50 transition-all",
                                                idx === offers.length - 1 && "opacity-30 cursor-not-allowed"
                                            )}
                                        >
                                            <HiOutlineArrowDownCircle className="h-4 w-4" />
                                        </button>
                                    </div>
                                    <div className="flex items-center gap-1">
                                        <button
                                            onClick={() => openEditModal(offer)}
                                            className="p-2 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-xl transition-all"
                                        >
                                            <HiOutlinePencilSquare className="h-5 w-5" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(offer._id)}
                                            className="p-2 text-slate-400 hover:text-rose-500 hover:bg-rose-50 rounded-xl transition-all"
                                        >
                                            <HiOutlineTrash className="h-5 w-5" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        );
                    })}

                    {offers.length === 0 && !isLoading && (
                        <div className="px-6 py-20 text-center">
                            <div className="flex flex-col items-center gap-3">
                                <div className="p-4 bg-gray-50 rounded-full">
                                    <HiOutlineSparkles className="h-8 w-8 text-gray-300" />
                                </div>
                                <p className="ds-h4 text-gray-400">No offers configured yet</p>
                                <p className="ds-caption text-gray-400">Click &quot;New Offer&quot; to create your first offer card.</p>
                            </div>
                        </div>
                    )}
                </div>
            </Card>

            <Modal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                title={editingOffer ? "Edit Offer" : "Create Offer"}
            >
                <form onSubmit={handleSave} className="space-y-6">
                    <div className="space-y-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                            Offer Title
                        </label>
                        <input
                            value={formData.title}
                            onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                            placeholder="E.g. 60% OFF on first order"
                            className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-bold outline-none ring-1 ring-transparent focus:ring-primary/20"
                        />
                    </div>
                    <div className="space-y-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                            Description
                        </label>
                        <textarea
                            rows={3}
                            value={formData.description}
                            onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                            placeholder="Short copy to explain this offer"
                            className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-bold outline-none resize-none"
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Offer Code
                            </label>
                            <input
                                value={formData.code}
                                onChange={(e) => setFormData(prev => ({ ...prev, code: e.target.value.toUpperCase() }))}
                                placeholder="WELCOME60"
                                className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-mono font-black uppercase tracking-widest outline-none"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Applies on order #
                            </label>
                            <input
                                type="number"
                                min={1}
                                value={formData.appliesOnOrderNumber}
                                onChange={(e) => setFormData(prev => ({ ...prev, appliesOnOrderNumber: e.target.value }))}
                                className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-bold outline-none"
                            />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Style
                            </label>
                            <div className="flex gap-2">
                                {STYLE_OPTIONS.map(opt => (
                                    <button
                                        key={opt.id}
                                        type="button"
                                        onClick={() => setFormData(prev => ({ ...prev, style: opt.id }))}
                                        className={cn(
                                            "flex-1 px-3 py-2 rounded-2xl text-[11px] font-bold border flex items-center justify-center gap-1",
                                            formData.style === opt.id
                                                ? "border-slate-900 bg-slate-900 text-white"
                                                : "border-slate-200 bg-slate-50 text-slate-600"
                                        )}
                                    >
                                        <span className={cn("h-3 w-3 rounded-full", opt.className)} />
                                        {opt.label}
                                    </button>
                                ))}
                            </div>
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Icon
                            </label>
                            <div className="flex gap-2">
                                {ICON_OPTIONS.map(opt => {
                                    const Icon = opt.icon;
                                    return (
                                        <button
                                            key={opt.id}
                                            type="button"
                                            onClick={() => setFormData(prev => ({ ...prev, icon: opt.id }))}
                                            className={cn(
                                                "flex-1 px-3 py-2 rounded-2xl text-[11px] font-bold border flex items-center justify-center gap-1",
                                                formData.icon === opt.id
                                                    ? "border-slate-900 bg-slate-900 text-white"
                                                    : "border-slate-200 bg-slate-50 text-slate-600"
                                            )}
                                        >
                                            <Icon className="h-4 w-4" />
                                            {opt.label}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Attach Categories (optional)
                            </label>
                            <div className="flex flex-wrap gap-1.5 max-h-40 overflow-y-auto pr-1">
                                {categories.map(c => {
                                    const isSelected = formData.categoryIds.includes(c._id);
                                    return (
                                        <button
                                            key={c._id}
                                            type="button"
                                            onClick={() =>
                                                setFormData(prev => ({
                                                    ...prev,
                                                    categoryIds: isSelected
                                                        ? prev.categoryIds.filter(id => id !== c._id)
                                                        : [...prev.categoryIds, c._id],
                                                }))
                                            }
                                            className={cn(
                                                "px-2.5 py-1.5 rounded-full text-[11px] font-bold border transition-all",
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
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Attach Products (optional)
                            </label>
                            <div className="flex flex-wrap gap-1.5 max-h-40 overflow-y-auto pr-1">
                                {products.map(p => {
                                    const isSelected = formData.productIds.includes(p._id);
                                    return (
                                        <button
                                            key={p._id}
                                            type="button"
                                            onClick={() =>
                                                setFormData(prev => ({
                                                    ...prev,
                                                    productIds: isSelected
                                                        ? prev.productIds.filter(id => id !== p._id)
                                                        : [...prev.productIds, p._id],
                                                }))
                                            }
                                            className={cn(
                                                "px-2.5 py-1.5 rounded-full text-[11px] font-bold border transition-all",
                                                isSelected
                                                    ? "bg-brand-500 text-primary-foreground border-brand-500"
                                                    : "bg-slate-50 text-slate-600 border-slate-200 hover:bg-white"
                                            )}
                                        >
                                            {p.name}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Display Order
                            </label>
                            <input
                                type="number"
                                min={0}
                                value={formData.order}
                                onChange={(e) => setFormData(prev => ({ ...prev, order: e.target.value }))}
                                className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-bold outline-none"
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                                Status
                            </label>
                            <select
                                value={formData.status}
                                onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
                                className="w-full px-4 py-3 bg-slate-50 border-none rounded-2xl text-xs font-bold outline-none"
                            >
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                            </select>
                        </div>
                    </div>

                    <div className="flex gap-4 pt-4">
                        <button
                            type="button"
                            onClick={() => setIsModalOpen(false)}
                            className="ds-btn ds-btn-md flex-1 bg-slate-100 text-slate-500 hover:bg-slate-200"
                        >
                            CANCEL
                        </button>
                        <button
                            type="submit"
                            className="ds-btn ds-btn-md flex-1 bg-primary text-primary-foreground shadow-xl shadow-primary/20"
                        >
                            {editingOffer ? 'SAVE CHANGES' : 'CREATE OFFER'}
                        </button>
                    </div>
                </form>
            </Modal>
        </div>
    );
};

export default OffersManagement;


