import React, { useState, useEffect, useMemo } from 'react';
import Card from '@shared/components/ui/Card';
import Badge from '@shared/components/ui/Badge';
import Pagination from '@shared/components/ui/Pagination';
import PageHeader from '@shared/components/ui/PageHeader';
import StatCard from '@shared/components/ui/StatCard';
import { adminApi } from '../services/adminApi';
import {
    HiOutlineStar,
    HiOutlineTrash,
    HiOutlineShieldCheck,
    HiOutlineExclamationTriangle,
    HiOutlineChatBubbleBottomCenterText,
    HiOutlineHandThumbUp,
    HiOutlineMagnifyingGlass,
    HiOutlineBuildingStorefront
} from 'react-icons/hi2';
import { useToast } from '@shared/components/ui/Toast';
import Modal from '@shared/components/ui/Modal';
import { cn } from '@/lib/utils';
import { Loader2 } from 'lucide-react';

const ReviewModeration = () => {
    const { showToast } = useToast();
    const [isReplyModalOpen, setIsReplyModalOpen] = useState(false);
    const [selectedReview, setSelectedReview] = useState(null);
    const [replyText, setReplyText] = useState('');
    const [loading, setLoading] = useState(true);
    const [reviews, setReviews] = useState([]);
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(25);
    const [total, setTotal] = useState(0);

    useEffect(() => {
        fetchReviews(1);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [pageSize]);

    const fetchReviews = async (requestedPage = 1) => {
        try {
            setLoading(true);
            const res = await adminApi.getPendingReviews({ page: requestedPage, limit: pageSize });
            if (res.data.success) {
                const payload = res.data.result || {};
                const data = Array.isArray(payload.items) ? payload.items : (res.data.results || []);
                setReviews(data.map(r => ({
                    ...r,
                    id: r._id,
                    user: r.userId?.name || "Anonymous",
                    item: r.productId?.name || "Deleted Product",
                    itemImage: r.productId?.images?.[0],
                    date: new Date(r.createdAt).toLocaleString(),
                    tags: [] // Tags can be empty or logic-based
                })));
                setTotal(typeof payload.total === 'number' ? payload.total : data.length);
                setPage(typeof payload.page === 'number' ? payload.page : requestedPage);
            }
        } catch (error) {
            console.error("Fetch Reviews Error:", error);
            showToast("Failed to load reviews", "error");
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        try {
            const res = await adminApi.updateReviewStatus(id, 'approved');
            if (res.data.success) {
                setReviews(reviews.filter(r => r.id !== id));
                fetchReviews(page);
                showToast('Review approved and published', 'success');
            }
        } catch (error) {
            showToast("Failed to approve review", "error");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure you want to reject and remove this review?')) return;
        try {
            const res = await adminApi.updateReviewStatus(id, 'rejected');
            if (res.data.success) {
                setReviews(reviews.filter(r => r.id !== id));
                fetchReviews(page);
                showToast('Review rejected and removed', 'warning');
            }
        } catch (error) {
            showToast("Failed to remove review", "error");
        }
    };

    const handleReplyClick = (review) => {
        setSelectedReview(review);
        setIsReplyModalOpen(true);
    };

    const submitReply = () => {
        if (!replyText.trim()) return;
        // Reply logic for reviews is usually public or private.
        // For now we'll just show toast since we don't have review-reply model yet
        showToast(`Reply noted for ${selectedReview.user}`, 'success');
        setIsReplyModalOpen(false);
        setReplyText('');
    };

    const stats = useMemo(() => {
        const flagged = reviews.filter(r => r.status === 'flagged').length;
        const approved = reviews.filter(r => r.status === 'approved').length;
        const avgRating = reviews.length
            ? (reviews.reduce((acc, r) => acc + (r.rating || 0), 0) / reviews.length).toFixed(1)
            : '0.0';
        return {
            total,
            flagged,
            approved,
            avgRating,
        };
    }, [reviews, total]);

    return (
        <div className="ds-section-spacing">
            <PageHeader
                title="Moderation Suite"
                description="Protect community integrity and store reputations."
                actions={
                    <div className="flex bg-slate-100 p-1 rounded-xl">
                        <button className="px-5 py-2 rounded-lg text-[10px] font-black uppercase bg-white text-slate-900 shadow-sm">ALL REVIEWS</button>
                        <button className="px-5 py-2 rounded-lg text-[10px] font-black uppercase text-slate-400 hover:text-slate-600">FLAGGED ONLY</button>
                    </div>
                }
            />

            <div className="ds-grid-cards-4">
                <StatCard
                    label="Pending Reviews"
                    value={stats.total}
                    icon={HiOutlineChatBubbleBottomCenterText}
                    color="text-brand-600"
                    bg="bg-brand-50"
                />
                <StatCard
                    label="Flagged"
                    value={stats.flagged}
                    icon={HiOutlineExclamationTriangle}
                    color="text-rose-600"
                    bg="bg-rose-50"
                />
                <StatCard
                    label="Approved"
                    value={stats.approved}
                    icon={HiOutlineShieldCheck}
                    color="text-emerald-600"
                    bg="bg-emerald-50"
                />
                <StatCard
                    label="Avg. Rating"
                    value={stats.avgRating}
                    icon={HiOutlineStar}
                    color="text-amber-600"
                    bg="bg-amber-50"
                />
            </div>

            <div className="grid grid-cols-1 gap-6 relative min-h-[160px]">
                {loading && (
                    <div className="absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center rounded-xl">
                        <div className="flex flex-col items-center gap-2">
                            <Loader2 className="h-8 w-8 text-primary animate-spin" />
                            <p className="ds-caption text-gray-500 font-medium">Loading reviews...</p>
                        </div>
                    </div>
                )}
                {!loading && reviews.length === 0 && (
                    <div className="px-6 py-20 text-center">
                        <div className="flex flex-col items-center gap-3">
                            <div className="p-4 bg-gray-50 rounded-full">
                                <HiOutlineChatBubbleBottomCenterText className="h-8 w-8 text-gray-300" />
                            </div>
                            <p className="ds-h4 text-gray-400">No reviews to moderate</p>
                        </div>
                    </div>
                )}
                {reviews.map((r) => (
                    <Card key={r.id} className="p-4 border-none shadow-xl ring-1 ring-slate-100 bg-white rounded-xl group overflow-hidden relative">
                        {/* Decorative background icon */}
                        <HiOutlineChatBubbleBottomCenterText className="absolute -top-6 -right-6 h-32 w-32 text-slate-50 opacity-[0.03] group-hover:scale-110 transition-transform duration-1000" />

                        <div className="flex flex-col lg:flex-row gap-4 relative z-10">
                            {/* User Info & Rating */}
                            <div className="lg:w-64 shrink-0 space-y-4">
                                <div className="flex items-center gap-4">
                                    <img
                                        src="https://cdn-icons-png.flaticon.com/512/149/149071.png"
                                        alt=""
                                        className="h-12 w-12 rounded-2xl bg-slate-50 ring-2 ring-white shadow-sm object-cover"
                                    />
                                    <div>
                                        <h4 className="text-sm font-black text-slate-900">{r.user}</h4>
                                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">{r.date}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-1">
                                    {[...Array(5)].map((_, i) => (
                                        <HiOutlineStar
                                            key={i}
                                            className={cn("h-4 w-4", i < r.rating ? "text-amber-400 fill-amber-400" : "text-slate-200")}
                                        />
                                    ))}
                                </div>
                                <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-slate-500">
                                        <HiOutlineBuildingStorefront className="h-4 w-4" />
                                        <span className="text-[11px] font-bold">{r.store}</span>
                                    </div>
                                    <p className="text-[10px] font-black text-primary uppercase tracking-tighter">Item: {r.item}</p>
                                </div>
                            </div>

                            {/* Comment & Status */}
                            <div className="flex-1 space-y-4">
                                <div className="flex items-center gap-2 flex-wrap">
                                    {r.status === 'flagged' && (
                                        <Badge variant="error" className="text-[8px] font-black uppercase tracking-widest flex items-center gap-1">
                                            <HiOutlineExclamationTriangle className="h-3 w-3" />
                                            FLAGGED BY SYSTEM
                                        </Badge>
                                    )}
                                    {r.tags.map((tag, i) => (
                                        <Badge key={i} variant="gray" className="text-[8px] font-bold text-slate-400 bg-slate-50 border-none px-2">{tag}</Badge>
                                    ))}
                                </div>
                                <blockquote className="text-sm font-medium text-slate-700 leading-relaxed bg-slate-50/50 p-5 rounded-2xl italic italic border-l-4 border-slate-100">
                                    "{r.comment}"
                                </blockquote>
                            </div>

                            {/* Actions */}
                            <div className="lg:w-48 flex lg:flex-col items-center justify-center gap-3">
                                {r.status !== 'approved' && (
                                    <button
                                        onClick={() => handleApprove(r.id)}
                                        className="ds-btn ds-btn-sm flex-1 w-full bg-brand-500 text-primary-foreground shadow-lg shadow-brand-200 hover:bg-black"
                                    >
                                        <HiOutlineShieldCheck className="ds-icon-sm" />
                                        APPROVE
                                    </button>
                                )}
                                <button
                                    onClick={() => handleDelete(r.id)}
                                    className="ds-btn ds-btn-sm flex-1 w-full bg-white text-rose-500 ring-1 ring-rose-100 hover:bg-rose-50"
                                >
                                    <HiOutlineTrash className="ds-icon-sm" />
                                    REMOVE
                                </button>
                                <button
                                    onClick={() => handleReplyClick(r)}
                                    className="ds-btn ds-btn-sm flex-1 w-full bg-slate-900 text-white shadow-xl hover:bg-slate-800"
                                >
                                    REPLY
                                </button>
                            </div>
                        </div>
                    </Card>
                ))}
            </div>
            <div className="mt-6 flex justify-center">
                <Pagination
                    page={page}
                    totalPages={Math.ceil(total / pageSize) || 1}
                    total={total}
                    pageSize={pageSize}
                    onPageChange={(p) => fetchReviews(p)}
                    onPageSizeChange={(newSize) => {
                        setPageSize(newSize);
                        setPage(1);
                    }}
                    loading={loading}
                />
            </div>

            <Modal
                isOpen={isReplyModalOpen}
                onClose={() => setIsReplyModalOpen(false)}
                title="Send Public Response"
            >
                <div className="space-y-4">
                    {selectedReview && (
                        <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100">
                            <p className="text-[10px] font-black text-slate-400 uppercase mb-2">Review from {selectedReview.user}</p>
                            <p className="text-xs font-medium text-slate-600 italic">"{selectedReview.comment}"</p>
                        </div>
                    )}
                    <textarea
                        value={replyText}
                        onChange={(e) => setReplyText(e.target.value)}
                        placeholder="Write your official response..."
                        className="w-full bg-slate-100 border-none rounded-2xl p-4 text-sm font-bold min-h-[120px] outline-none ring-1 ring-transparent focus:ring-primary/20"
                    />
                    <div className="flex gap-3">
                        <button
                            onClick={() => setIsReplyModalOpen(false)}
                            className="ds-btn ds-btn-md flex-1 bg-slate-100 text-slate-500 hover:bg-slate-200"
                        >
                            CANCEL
                        </button>
                        <button
                            onClick={submitReply}
                            className="ds-btn ds-btn-md flex-1 bg-primary text-primary-foreground shadow-lg shadow-primary/20"
                        >
                            PUBLISH REPLY
                        </button>
                    </div>
                </div>
            </Modal>
        </div>
    );
};

export default ReviewModeration;
