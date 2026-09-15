// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../../app/app_routes.dart';
// import '../../../../core/constants/api_endpoints.dart';
// import '../../../../core/di/injection.dart';
// import '../../../../core/network/api_client.dart';
import '../../../../core/services/platform_settings_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/theme/app_typography.dart';
// import '../../../../core/widgets/app_snackbar.dart';

// class ComplaintCategory {
//   final String id;
//   final String label;
//   final IconData icon;
//   final String subject;

//   const ComplaintCategory({required this.id, required this.label, required this.icon, required this.subject});
// }

// const List<ComplaintCategory> kComplaintCategories = [
//   ComplaintCategory(id: 'order', label: 'Order issue', icon: Icons.inventory_2_outlined, subject: 'Order complaint'),
//   ComplaintCategory(
//     id: 'parcel',
//     label: 'Parcel delivery',
//     icon: Icons.local_shipping_outlined,
//     subject: 'Parcel complaint',
//   ),
//   ComplaintCategory(
//     id: 'payment',
//     label: 'Payment / refund',
//     icon: Icons.credit_card_outlined,
//     subject: 'Payment complaint',
//   ),
//   ComplaintCategory(
//     id: 'delivery',
//     label: 'Delivery partner',
//     icon: Icons.delivery_dining_outlined,
//     subject: 'Delivery complaint',
//   ),
//   ComplaintCategory(
//     id: 'product',
//     label: 'Product quality',
//     icon: Icons.warning_amber_rounded,
//     subject: 'Product quality complaint',
//   ),
//   ComplaintCategory(id: 'refund', label: 'Refund request', icon: Icons.replay_rounded, subject: 'Refund request'),
//   ComplaintCategory(id: 'app', label: 'App / technical', icon: Icons.smartphone_rounded, subject: 'App issue'),
//   ComplaintCategory(id: 'other', label: 'Something else', icon: Icons.more_horiz_rounded, subject: 'General complaint'),
// ];

// class SupportPage extends StatefulWidget {
//   final VoidCallback? onBack;
//   final bool autoOpenComplaint;
//   final String? initialCategory;
//   final String? initialOrderId;
//   final String? initialParcelId;
//   final String? initialSubject;
//   final String? initialDescription;

//   const SupportPage({
//     super.key,
//     this.onBack,
//     this.autoOpenComplaint = false,
//     this.initialCategory,
//     this.initialOrderId,
//     this.initialParcelId,
//     this.initialSubject,
//     this.initialDescription,
//   });

//   @override
//   State<SupportPage> createState() => _SupportPageState();
// }

// class _SupportPageState extends State<SupportPage> {
//   late final ApiClient _apiClient;

//   bool _ticketsLoading = true;
//   List<Map<String, dynamic>> _myTickets = [];

//   bool _faqsLoading = false;
//   List<Map<String, String>> _faqs = [];
//   final Set<int> _expandedFaqIndices = {};

//   final String _supportEmail = 'support@sungguard.com';
//   final String _supportPhone = '+91 98765 43210';

//   @override
//   void initState() {
//     super.initState();
//     _apiClient = sl<ApiClient>();

//     _fetchMyTickets();
//     _fetchFaqs();

//     if (widget.autoOpenComplaint) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _openComplaintModal(
//           categoryId: widget.initialCategory ?? 'other',
//           orderId: widget.initialOrderId,
//           parcelId: widget.initialParcelId,
//           subject: widget.initialSubject,
//           description: widget.initialDescription,
//         );
//       });
//     }
//   }

//   void _handleBack() {
//     if (widget.onBack != null) {
//       widget.onBack!();
//     } else if (context.canPop()) {
//       context.pop();
//     } else {
//       context.go('/profile');
//     }
//   }

//   Future<void> _fetchMyTickets() async {
//     setState(() => _ticketsLoading = true);
//     try {
//       final res = await _apiClient.get(ApiEndpoints.myTickets);
//       List<dynamic> rawList = [];

//       if (res is List) {
//         rawList = res;
//       } else if (res is Map<String, dynamic>) {
//         if (res['result'] is List) {
//           rawList = res['result'] as List;
//         } else if (res['results'] is List) {
//           rawList = res['results'] as List;
//         } else if (res['data'] is List) {
//           rawList = res['data'] as List;
//         }
//       }

//       final parsed = rawList.whereType<Map<String, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList();

//       if (mounted) {
//         setState(() {
//           _myTickets = parsed;
//           _ticketsLoading = false;
//         });
//       }
//     } catch (_) {
//       if (mounted) {
//         setState(() {
//           _myTickets = [];
//           _ticketsLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _fetchFaqs() async {
//     setState(() => _faqsLoading = true);
//     try {
//       final res = await _apiClient.get(
//         '/public/faqs',
//         queryParameters: {'category': 'Customer', 'status': 'published'},
//       );

//       List<dynamic> rawList = [];
//       if (res is List) {
//         rawList = res;
//       } else if (res is Map<String, dynamic>) {
//         if (res['items'] is List) {
//           rawList = res['items'] as List;
//         } else if (res['results'] is List) {
//           rawList = res['results'] as List;
//         } else if (res['result'] is Map && res['result']['items'] is List) {
//           rawList = res['result']['items'] as List;
//         }
//       }

//       if (rawList.isNotEmpty) {
//         final parsed = rawList
//             .map((item) {
//               final map = item is Map ? item : {};
//               return {'question': (map['question'] ?? '').toString(), 'answer': (map['answer'] ?? '').toString()};
//             })
//             .where((e) => e['question']!.isNotEmpty)
//             .toList();

//         if (mounted && parsed.isNotEmpty) {
//           setState(() {
//             _faqs = parsed;
//             _faqsLoading = false;
//           });
//           return;
//         }
//       }
//     } catch (_) {}

//     // Fallback default FAQs
//     if (mounted) {
//       setState(() {
//         _faqs = _defaultFaqs;
//         _faqsLoading = false;
//       });
//     }
//   }

//   static const List<Map<String, String>> _defaultFaqs = [
//     {
//       'question': 'How do I track my live courier rider?',
//       'answer': 'SunGguard provides real-time GPS navigation and docket timeline tracking for all parcels. Open your active consignment docket to monitor your courier rider live.',
//     },
//     {
//       'question': 'What is the 4-digit handover code?',
//       'answer': 'A secure 4-digit OTP is required during pickup and handover. Share this code with the verified delivery partner only after receiving/giving the parcel.',
//     },
//     {
//       'question': 'What happens if the receiver is unavailable?',
//       'answer': 'Our rider will attempt to contact the receiver at the doorstep. If unreachable, the consignment is securely returned to base or rescheduled per your instructions.',
//     },
//     {
//       'question': 'How are parcel fares calculated?',
//       'answer': 'Fares are transparently calculated using distance, parcel weight category, speed tier, and applicable government taxes with zero hidden surcharges.',
//     },
//     {
//       'question': 'How do I request a refund?',
//       'answer': 'You can raise a refund ticket directly on this screen under "Refund request". Our customer support team reviews and processes refunds within 24 business hours.',
//     },
//   ];

//   void _openComplaintModal({
//     String categoryId = 'other',
//     String? orderId,
//     String? parcelId,
//     String? subject,
//     String? description,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (sheetContext) => _ComplaintModalSheet(
//         apiClient: _apiClient,
//         initialCategory: categoryId,
//         initialOrderId: orderId,
//         initialParcelId: parcelId,
//         initialSubject: subject,
//         initialDescription: description,
//         onSuccess: () {
//           _fetchMyTickets();
//         },
//       ),
//     );
//   }

//   Future<void> _callSupport() async {
//     final cleanPhone = _supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');
//     final uri = Uri.parse('tel:$cleanPhone');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       if (mounted) {
//         AppSnackBar.showInfo(context, 'Support line: $_supportPhone');
//       }
//     }
//   }

//   Future<void> _emailSupport() async {
//     final uri = Uri.parse('mailto:$_supportEmail?subject=Customer Support Inquiry');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       if (mounted) {
//         AppSnackBar.showInfo(context, 'Support Email: $_supportEmail');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF8FAFC),
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, size: 22.0, color: Color(0xFF0F172A)),
//           onPressed: _handleBack,
//         ),
//         titleSpacing: 0,
//         title: Text(
//           'Help & Support',
//           style: AppTypography.headingLarge.copyWith(
//             fontSize: 19.0,
//             fontWeight: FontWeight.w800,
//             color: const Color(0xFF0F172A),
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1.0),
//           child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
//         ),
//       ),
//       body: RefreshIndicator(
//         color: AppColors.primary,
//         onRefresh: () async {
//           await Future.wait([_fetchMyTickets(), _fetchFaqs()]);
//         },
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1. Primary Complaint Hero CTA
//               _buildPrimaryComplaintCta(),

//               const SizedBox(height: AppSpacing.xl),

//               // 2. Complaint Categories Section
//               _buildComplaintCategories(),

//               const SizedBox(height: AppSpacing.xl),

//               // 3. Contact Channels Grid
//               _buildContactChannels(),

//               const SizedBox(height: AppSpacing.xl),

//               // 4. My Complaints Section
//               _buildMyComplaintsSection(),

//               const SizedBox(height: AppSpacing.xl),

//               // 5. FAQ Section
//               _buildFaqSection(),

//               const SizedBox(height: AppSpacing.xl),

//               // 6. Legal Links Section
//               _buildLegalSection(),

//               const SizedBox(height: 60.0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 1. Primary Hero Card
//   Widget _buildPrimaryComplaintCta() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF071630), Color(0xFF0D2854)],
//         ),
//         borderRadius: BorderRadius.circular(20.0),
//         boxShadow: const [BoxShadow(color: Color(0x240C831F), blurRadius: 16.0, offset: Offset(0, 6))],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _openComplaintModal(categoryId: 'other'),
//           borderRadius: BorderRadius.circular(20.0),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'FILE A COMPLAINT',
//                         style: AppTypography.monoLabelLight.copyWith(
//                           fontSize: 10.0,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: 1.5,
//                           color: Colors.white.withValues(alpha: 0.75),
//                         ),
//                       ),
//                       const SizedBox(height: 6.0),
//                       Text(
//                         'Tell admin what went wrong',
//                         style: AppTypography.headingMedium.copyWith(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.white,
//                           letterSpacing: -0.3,
//                         ),
//                       ),
//                       const SizedBox(height: 6.0),
//                       Text(
//                         'Order, parcel, payment, delivery — anything. Admin will reply.',
//                         style: AppTypography.bodySmall.copyWith(
//                           fontSize: 12.0,
//                           color: Colors.white.withValues(alpha: 0.85),
//                           fontWeight: FontWeight.w500,
//                           height: 1.3,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 14.0),
//                 Container(
//                   width: 48.0,
//                   height: 48.0,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.18),
//                     borderRadius: BorderRadius.circular(16.0),
//                   ),
//                   child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26.0),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 2. Complaint Categories
//   Widget _buildComplaintCategories() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 2.0),
//           child: Text(
//             'Complaint type',
//             style: AppTypography.bodyBold.copyWith(
//               fontSize: 14.0,
//               fontWeight: FontWeight.w700,
//               color: const Color(0xFF1E293B),
//             ),
//           ),
//         ),
//         const SizedBox(height: AppSpacing.sm + 4),
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 4,
//             crossAxisSpacing: 10.0,
//             mainAxisSpacing: 10.0,
//             childAspectRatio: 0.85,
//           ),
//           itemCount: kComplaintCategories.length,
//           itemBuilder: (context, index) {
//             final cat = kComplaintCategories[index];
//             return Material(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12.0),
//               child: InkWell(
//                 onTap: () => _openComplaintModal(categoryId: cat.id),
//                 borderRadius: BorderRadius.circular(12.0),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12.0),
//                     border: Border.all(color: const Color(0xFFE2E8F0)),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 36.0,
//                         height: 36.0,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF1F5F9),
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Icon(cat.icon, size: 18.0, color: const Color(0xFF475569)),
//                       ),
//                       const SizedBox(height: 6.0),
//                       Text(
//                         cat.label,
//                         textAlign: TextAlign.center,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 10.5,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1E293B),
//                           height: 1.15,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // 3. Contact Channels
//   Widget _buildContactChannels() {
//     final emailDisplay = _supportEmail.length > 12 ? '${_supportEmail.substring(0, 12)}...' : _supportEmail;

//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 10.0,
//       mainAxisSpacing: 10.0,
//       childAspectRatio: 1.45,
//       children: [
//         _buildContactCard(
//           icon: Icons.chat_bubble_outline_rounded,
//           label: 'Chat Us',
//           sub: 'Live support',
//           onTap: () {
//             context.push(AppRoutes.chat);
//           },
//         ),
//         _buildContactCard(
//           icon: Icons.add_circle_outline_rounded,
//           label: 'New Complaint',
//           sub: 'Write details',
//           onTap: () => _openComplaintModal(categoryId: 'other'),
//         ),
//         _buildContactCard(icon: Icons.phone_outlined, label: 'Call Us', sub: '+91 98765...', onTap: _callSupport),
//         _buildContactCard(icon: Icons.mail_outline_rounded, label: 'Email Us', sub: emailDisplay, onTap: _emailSupport),
//       ],
//     );
//   }

//   Widget _buildContactCard({
//     required IconData icon,
//     required String label,
//     required String sub,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14.0),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14.0),
//         child: Container(
//           padding: const EdgeInsets.all(12.0),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(14.0),
//             border: Border.all(color: const Color(0xFFE2E8F0)),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 38.0,
//                 height: 38.0,
//                 decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10.0)),
//                 child: Icon(icon, size: 20.0, color: const Color(0xFF475569)),
//               ),
//               const SizedBox(height: 8.0),
//               Text(
//                 label,
//                 style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
//               ),
//               const SizedBox(height: 2.0),
//               Text(
//                 sub,
//                 style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 4. My Complaints
//   Widget _buildMyComplaintsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 2.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'My complaints',
//                 style: AppTypography.bodyBold.copyWith(
//                   fontSize: 14.0,
//                   fontWeight: FontWeight.w700,
//                   color: const Color(0xFF1E293B),
//                 ),
//               ),
//               InkWell(
//                 onTap: _fetchMyTickets,
//                 borderRadius: BorderRadius.circular(4.0),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
//                   child: Text(
//                     'REFRESH',
//                     style: AppTypography.monoLabel.copyWith(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w800,
//                       fontSize: 10.5,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: AppSpacing.sm + 2),
//         if (_ticketsLoading)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16.0),
//               border: Border.all(color: const Color(0xFFF1F5F9)),
//             ),
//             child: const Center(
//               child: Text('Loading…', style: TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8))),
//             ),
//           )
//         else if (_myTickets.isEmpty)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16.0),
//               border: Border.all(color: const Color(0xFFF1F5F9)),
//             ),
//             child: Column(
//               children: [
//                 const Text(
//                   'No complaints yet',
//                   style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
//                 ),
//                 const SizedBox(height: 4.0),
//                 const Text(
//                   'When you file one, it appears here and on Admin → Help Tickets.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
//                 ),
//               ],
//             ),
//           )
//         else
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _myTickets.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 10.0),
//             itemBuilder: (context, index) {
//               final ticket = _myTickets[index];
//               return _buildTicketCard(ticket);
//             },
//           ),
//       ],
//     );
//   }

//   Widget _buildTicketCard(Map<String, dynamic> ticket) {
//     final subject = (ticket['subject'] ?? 'Complaint').toString();
//     final description = (ticket['description'] ?? '').toString();
//     final status = (ticket['status'] ?? 'open').toString().toLowerCase();
//     final category = (ticket['category'] ?? '').toString();
//     final ticketId = (ticket['_id'] ?? ticket['id'] ?? '').toString();
//     final createdAtRaw = ticket['createdAt']?.toString();

//     String formattedDate = '';
//     if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
//       try {
//         final dt = DateTime.parse(createdAtRaw);
//         formattedDate = DateFormat('d MMM').format(dt);
//       } catch (_) {}
//     }

//     Color statusBg;
//     Color statusText;
//     String statusLabel;

//     if (status == 'closed') {
//       statusBg = const Color(0xFFF1F5F9);
//       statusText = const Color(0xFF475569);
//       statusLabel = 'CLOSED';
//     } else if (status == 'processing') {
//       statusBg = const Color(0xFFFEF3C7);
//       statusText = const Color(0xFF92400E);
//       statusLabel = 'IN PROGRESS';
//     } else {
//       statusBg = const Color(0xFFD1FAE5);
//       statusText = const Color(0xFF065F46);
//       statusLabel = status.toUpperCase();
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16.0),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {
//             if (ticketId.isNotEmpty) {
//               context.push('${AppRoutes.chat}?ticketId=$ticketId');
//             } else {
//               context.push(AppRoutes.chat);
//             }
//           },
//           borderRadius: BorderRadius.circular(16.0),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             subject,
//                             style: const TextStyle(
//                               fontSize: 14.0,
//                               fontWeight: FontWeight.w800,
//                               color: Color(0xFF0F172A),
//                             ),
//                           ),
//                           if (description.isNotEmpty) ...[
//                             const SizedBox(height: 4.0),
//                             Text(
//                               description,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B), height: 1.35),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 8.0),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                       decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12.0)),
//                       child: Text(
//                         statusLabel,
//                         style: TextStyle(
//                           fontSize: 9.5,
//                           fontWeight: FontWeight.w900,
//                           color: statusText,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10.0),
//                 Row(
//                   children: [
//                     if (category.isNotEmpty) ...[
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF8FAFC),
//                           borderRadius: BorderRadius.circular(12.0),
//                           border: Border.all(color: const Color(0xFFE2E8F0)),
//                         ),
//                         child: Text(
//                           category.toUpperCase(),
//                           style: const TextStyle(
//                             fontSize: 9.5,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF64748B),
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8.0),
//                     ],
//                     if (formattedDate.isNotEmpty) ...[
//                       const Icon(Icons.access_time_rounded, size: 12.0, color: Color(0xFF94A3B8)),
//                       const SizedBox(width: 4.0),
//                       Text(
//                         formattedDate,
//                         style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 12.0),
//                 Row(
//                   children: [
//                     const Icon(Icons.chat_bubble_outline_rounded, size: 13.0, color: AppColors.primary),
//                     const SizedBox(width: 5.0),
//                     Text(
//                       'Open chat with admin',
//                       style: AppTypography.bodyBold.copyWith(
//                         fontSize: 11.5,
//                         color: AppColors.primary,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 5. FAQ Section
//   Widget _buildFaqSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 2.0),
//           child: Text(
//             'Frequently Asked Questions',
//             style: AppTypography.bodyBold.copyWith(
//               fontSize: 15.0,
//               fontWeight: FontWeight.w700,
//               color: const Color(0xFF1E293B),
//             ),
//           ),
//         ),
//         const SizedBox(height: AppSpacing.sm + 2),
//         if (_faqsLoading)
//           const Center(
//             child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2.0)),
//           )
//         else
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _faqs.length,
//             separatorBuilder: (_, __) => const SizedBox(height: 10.0),
//             itemBuilder: (context, index) {
//               final faq = _faqs[index];
//               final isExpanded = _expandedFaqIndices.contains(index);

//               return Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14.0),
//                   border: Border.all(color: const Color(0xFFE2E8F0)),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(14.0),
//                   child: Column(
//                     children: [
//                       InkWell(
//                         onTap: () {
//                           setState(() {
//                             if (isExpanded) {
//                               _expandedFaqIndices.remove(index);
//                             } else {
//                               _expandedFaqIndices.add(index);
//                             }
//                           });
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   faq['question'] ?? '',
//                                   style: const TextStyle(
//                                     fontSize: 13.5,
//                                     fontWeight: FontWeight.w700,
//                                     color: Color(0xFF1E293B),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8.0),
//                               Icon(
//                                 isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
//                                 color: const Color(0xFF64748B),
//                                 size: 20.0,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       if (isExpanded)
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 14.0),
//                           decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
//                           child: Padding(
//                             padding: const EdgeInsets.only(top: 8.0),
//                             child: Text(
//                               faq['answer'] ?? '',
//                               style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//       ],
//     );
//   }

//   // 6. Legal Section
//   Widget _buildLegalSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14.0),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'LEGAL',
//             style: AppTypography.monoLabel.copyWith(
//               fontSize: 10.5,
//               fontWeight: FontWeight.w800,
//               color: const Color(0xFF64748B),
//               letterSpacing: 1.2,
//             ),
//           ),
//           const SizedBox(height: 12.0),
//           _buildLegalRow(
//             title: 'Terms & Conditions',
//             icon: Icons.description_outlined,
//             onTap: () {
//               context.push(AppRoutes.terms);
//             },
//           ),
//           const Divider(color: Color(0xFFF1F5F9), height: 20.0),
//           _buildLegalRow(
//             title: 'Privacy Policy',
//             icon: Icons.shield_outlined,
//             onTap: () {
//               context.push(AppRoutes.privacy);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegalRow({required String title, required IconData icon, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Row(
//         children: [
//           Icon(icon, size: 18.0, color: const Color(0xFF475569)),
//           const SizedBox(width: 10.0),
//           Text(
//             title,
//             style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==========================================
// // Bottom Sheet for Filing Complaints
// // ==========================================
// class _ComplaintModalSheet extends StatefulWidget {
//   final ApiClient apiClient;
//   final String initialCategory;
//   final String? initialOrderId;
//   final String? initialParcelId;
//   final String? initialSubject;
//   final String? initialDescription;
//   final VoidCallback onSuccess;

//   const _ComplaintModalSheet({
//     required this.apiClient,
//     required this.initialCategory,
//     this.initialOrderId,
//     this.initialParcelId,
//     this.initialSubject,
//     this.initialDescription,
//     required this.onSuccess,
//   });

//   @override
//   State<_ComplaintModalSheet> createState() => _ComplaintModalSheetState();
// }

// class _ComplaintModalSheetState extends State<_ComplaintModalSheet> {
//   late String _category;
//   late String _priority;
//   late final TextEditingController _subjectCtrl;
//   late final TextEditingController _orderIdCtrl;
//   late final TextEditingController _parcelIdCtrl;
//   late final TextEditingController _descCtrl;

//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     _category = widget.initialCategory;
//     _priority = (_category == 'payment' || _category == 'refund') ? 'high' : 'medium';

//     final categoryObj = kComplaintCategories.firstWhere(
//       (c) => c.id == _category,
//       orElse: () => kComplaintCategories.last,
//     );

//     _subjectCtrl = TextEditingController(text: widget.initialSubject ?? categoryObj.subject);
//     _orderIdCtrl = TextEditingController(text: widget.initialOrderId ?? '');
//     _parcelIdCtrl = TextEditingController(text: widget.initialParcelId ?? '');
//     _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
//   }

//   @override
//   void dispose() {
//     _subjectCtrl.dispose();
//     _orderIdCtrl.dispose();
//     _parcelIdCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   void _onSelectCategory(ComplaintCategory cat) {
//     setState(() {
//       _category = cat.id;
//       if (_subjectCtrl.text.trim().isEmpty || kComplaintCategories.any((c) => c.subject == _subjectCtrl.text.trim())) {
//         _subjectCtrl.text = cat.subject;
//       }
//       if (_category == 'payment' || _category == 'refund') {
//         _priority = 'high';
//       }
//     });
//   }

//   Future<void> _submitComplaint() async {
//     final subject = _subjectCtrl.text.trim();
//     final description = _descCtrl.text.trim();

//     if (subject.isEmpty) {
//       AppSnackBar.showError(context, 'Please enter a subject');
//       return;
//     }
//     if (description.isEmpty) {
//       AppSnackBar.showError(context, 'Please describe what happened');
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       final payload = {
//         'subject': subject,
//         'description': description,
//         'priority': _priority,
//         'category': _category,
//         if (_category == 'order' || _category == 'refund') 'relatedOrderId': _orderIdCtrl.text.trim(),
//         if (_category == 'parcel') 'relatedParcelId': _parcelIdCtrl.text.trim(),
//         'userType': 'User',
//       };

//       await widget.apiClient.post(ApiEndpoints.createTicket, data: payload);

//       if (mounted) {
//         AppSnackBar.showSuccess(context, 'Complaint sent to admin. We will respond soon.');
//         Navigator.pop(context);
//         widget.onSuccess();
//       }
//     } catch (e) {
//       if (mounted) {
//         AppSnackBar.showError(context, e.toString());
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final viewInsets = MediaQuery.of(context).viewInsets;

//     return Container(
//       constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
//       padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, viewInsets.bottom + 24.0),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
//       ),
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Handle Bar
//             Center(
//               child: Container(
//                 width: 36.0,
//                 height: 4.0,
//                 margin: const EdgeInsets.only(bottom: 16.0),
//                 decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2.0)),
//               ),
//             ),

//             // Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'File a complaint',
//                       style: AppTypography.headingMedium.copyWith(
//                         fontSize: 18.5,
//                         fontWeight: FontWeight.w800,
//                         color: const Color(0xFF0F172A),
//                       ),
//                     ),
//                     const SizedBox(height: 2.0),
//                     const Text(
//                       'Admin will see this and can reply',
//                       style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
//                     ),
//                   ],
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
//                   onPressed: () => Navigator.pop(context),
//                   visualDensity: VisualDensity.compact,
//                 ),
//               ],
//             ),

//             const SizedBox(height: 18.0),

//             // Category Chips
//             Text(
//               'CATEGORY',
//               style: AppTypography.monoLabel.copyWith(
//                 fontSize: 10.0,
//                 color: const Color(0xFF94A3B8),
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 8.0),
//             Wrap(
//               spacing: 6.0,
//               runSpacing: 6.0,
//               children: kComplaintCategories.map((cat) {
//                 final isSelected = _category == cat.id;
//                 return ChoiceChip(
//                   label: Text(
//                     cat.label,
//                     style: TextStyle(
//                       fontSize: 11.0,
//                       fontWeight: FontWeight.w700,
//                       color: isSelected ? Colors.white : const Color(0xFF475569),
//                     ),
//                   ),
//                   selected: isSelected,
//                   selectedColor: AppColors.primary,
//                   backgroundColor: Colors.white,
//                   showCheckmark: false,
//                   padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20.0),
//                     side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1)),
//                   ),
//                   onSelected: (_) => _onSelectCategory(cat),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 16.0),

//             // Subject
//             Text(
//               'SUBJECT',
//               style: AppTypography.monoLabel.copyWith(
//                 fontSize: 10.0,
//                 color: const Color(0xFF94A3B8),
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 6.0),
//             TextField(
//               controller: _subjectCtrl,
//               style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
//               decoration: InputDecoration(
//                 hintText: 'Short summary of your complaint',
//                 hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
//                 filled: true,
//                 fillColor: const Color(0xFFF8FAFC),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
//               ),
//             ),

//             // Optional Order ID
//             if (_category == 'order' || _category == 'refund') ...[
//               const SizedBox(height: 14.0),
//               Text(
//                 'ORDER ID (OPTIONAL)',
//                 style: AppTypography.monoLabel.copyWith(
//                   fontSize: 10.0,
//                   color: const Color(0xFF94A3B8),
//                   letterSpacing: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 6.0),
//               TextField(
//                 controller: _orderIdCtrl,
//                 style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
//                 decoration: InputDecoration(
//                   hintText: 'e.g. ORD-123456',
//                   hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
//                   filled: true,
//                   fillColor: const Color(0xFFF8FAFC),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 ),
//               ),
//             ],

//             // Optional Parcel ID
//             if (_category == 'parcel') ...[
//               const SizedBox(height: 14.0),
//               Text(
//                 'PARCEL ID (OPTIONAL)',
//                 style: AppTypography.monoLabel.copyWith(
//                   fontSize: 10.0,
//                   color: const Color(0xFF94A3B8),
//                   letterSpacing: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 6.0),
//               TextField(
//                 controller: _parcelIdCtrl,
//                 style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
//                 decoration: InputDecoration(
//                   hintText: 'Parcel ID ending digits are fine',
//                   hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
//                   filled: true,
//                   fillColor: const Color(0xFFF8FAFC),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 ),
//               ),
//             ],

//             const SizedBox(height: 14.0),

//             // Priority Selection
//             Text(
//               'PRIORITY',
//               style: AppTypography.monoLabel.copyWith(
//                 fontSize: 10.0,
//                 color: const Color(0xFF94A3B8),
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 6.0),
//             Row(
//               children: ['low', 'medium', 'high'].map((p) {
//                 final isSelected = _priority == p;
//                 return Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 3.0),
//                     child: Material(
//                       color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
//                       borderRadius: BorderRadius.circular(12.0),
//                       child: InkWell(
//                         onTap: () => setState(() => _priority = p),
//                         borderRadius: BorderRadius.circular(12.0),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(vertical: 11.0),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12.0),
//                             border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
//                           ),
//                           child: Center(
//                             child: Text(
//                               p.toUpperCase(),
//                               style: TextStyle(
//                                 fontSize: 10.5,
//                                 fontWeight: FontWeight.w800,
//                                 letterSpacing: 1.2,
//                                 color: isSelected ? Colors.white : const Color(0xFF64748B),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 14.0),

//             // Description
//             Text(
//               'WHAT HAPPENED?',
//               style: AppTypography.monoLabel.copyWith(
//                 fontSize: 10.0,
//                 color: const Color(0xFF94A3B8),
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 6.0),
//             TextField(
//               controller: _descCtrl,
//               maxLines: 4,
//               style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
//               decoration: InputDecoration(
//                 hintText: 'Explain your complaint clearly. Include order/parcel details if useful.',
//                 hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
//                 filled: true,
//                 fillColor: const Color(0xFFF8FAFC),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
//                 contentPadding: const EdgeInsets.all(16.0),
//               ),
//             ),

//             const SizedBox(height: 20.0),

//             // Submit Button
//             SizedBox(
//               width: double.infinity,
//               height: 52.0,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
//                 ),
//                 onPressed: _isSubmitting ? null : _submitComplaint,
//                 child: _isSubmitting
//                     ? const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: 18.0,
//                             height: 18.0,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2.0,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           ),
//                           SizedBox(width: 10.0),
//                           Text(
//                             'SUBMITTING...',
//                             style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, letterSpacing: 1.2),
//                           ),
//                         ],
//                       )
//                     : const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.send_rounded, size: 18.0),
//                           SizedBox(width: 8.0),
//                           Text(
//                             'SUBMIT TO ADMIN',
//                             style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, letterSpacing: 1.2),
//                           ),
//                         ],
//                       ),
//               ),
//             ),

//             const SizedBox(height: 10.0),

//             const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.check_circle_outline_rounded, size: 13.0, color: Color(0xFF94A3B8)),
//                 SizedBox(width: 4.0),
//                 Text(
//                   'Visible in Admin → Help Tickets',
//                   style: TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';

class ComplaintCategory {
  final String id;
  final String label;
  final IconData icon;
  final String subject;

  const ComplaintCategory({required this.id, required this.label, required this.icon, required this.subject});
}

const List<ComplaintCategory> kComplaintCategories = [
  ComplaintCategory(id: 'order', label: 'Order issue', icon: Icons.inventory_2_outlined, subject: 'Order complaint'),
  ComplaintCategory(
    id: 'parcel',
    label: 'Parcel delivery',
    icon: Icons.local_shipping_outlined,
    subject: 'Parcel complaint',
  ),
  ComplaintCategory(
    id: 'payment',
    label: 'Payment / refund',
    icon: Icons.credit_card_outlined,
    subject: 'Payment complaint',
  ),
  ComplaintCategory(
    id: 'delivery',
    label: 'Delivery partner',
    icon: Icons.delivery_dining_outlined,
    subject: 'Delivery complaint',
  ),
  ComplaintCategory(
    id: 'product',
    label: 'Product quality',
    icon: Icons.warning_amber_rounded,
    subject: 'Product quality complaint',
  ),
  ComplaintCategory(id: 'refund', label: 'Refund request', icon: Icons.replay_rounded, subject: 'Refund request'),
  ComplaintCategory(id: 'app', label: 'App / technical', icon: Icons.smartphone_rounded, subject: 'App issue'),
  ComplaintCategory(id: 'other', label: 'Something else', icon: Icons.more_horiz_rounded, subject: 'General complaint'),
];

class SupportPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool autoOpenComplaint;
  final String? initialCategory;
  final String? initialOrderId;
  final String? initialParcelId;
  final String? initialSubject;
  final String? initialDescription;

  const SupportPage({
    super.key,
    this.onBack,
    this.autoOpenComplaint = false,
    this.initialCategory,
    this.initialOrderId,
    this.initialParcelId,
    this.initialSubject,
    this.initialDescription,
  });

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  late final ApiClient _apiClient;

  bool _ticketsLoading = true;
  List<Map<String, dynamic>> _myTickets = [];

  /// Ticket model status enum: open | processing | closed. The API has always
  /// returned it and the list showed every ticket in one undifferentiated pile.
  String _ticketFilter = 'all';

  static const List<String> _ticketFilters = [
    'all',
    'open',
    'processing',
    'closed',
  ];

  List<Map<String, dynamic>> get _filteredTickets {
    if (_ticketFilter == 'all') return _myTickets;
    return _myTickets
        .where(
          (t) =>
              (t['status']?.toString().toLowerCase() ?? 'open') ==
              _ticketFilter,
        )
        .toList();
  }

  int _countForFilter(String filter) {
    if (filter == 'all') return _myTickets.length;
    return _myTickets
        .where(
          (t) => (t['status']?.toString().toLowerCase() ?? 'open') == filter,
        )
        .length;
  }

  bool _faqsLoading = false;
  List<Map<String, String>> _faqs = [];
  final Set<int> _expandedFaqIndices = {};

  // Seeded with the previous hardcoded values so the screen is usable before
  // GET /api/settings resolves, then overwritten with the real ones.
  String _supportEmail = PlatformSettingsService().current.supportEmail;
  String _supportPhone = PlatformSettingsService().current.supportPhone;

  Future<void> _loadPlatformSettings() async {
    final settings = await PlatformSettingsService().load();
    if (!mounted) return;
    setState(() {
      _supportEmail = settings.supportEmail;
      _supportPhone = settings.supportPhone;
    });
  }

  @override
  void initState() {
    super.initState();

    _apiClient = sl<ApiClient>();

    _fetchMyTickets();
    _fetchFaqs();
    _loadPlatformSettings();

    if (widget.autoOpenComplaint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openComplaintModal(
          categoryId: widget.initialCategory ?? 'other',
          orderId: widget.initialOrderId,
          parcelId: widget.initialParcelId,
          subject: widget.initialSubject,
          description: widget.initialDescription,
        );
      });
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _fetchMyTickets() async {
    setState(() => _ticketsLoading = true);

    try {
      final res = await _apiClient.get(ApiEndpoints.myTickets);

      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map<String, dynamic>) {
        if (res['result'] is List) {
          rawList = res['result'] as List;
        } else if (res['results'] is List) {
          rawList = res['results'] as List;
        } else if (res['data'] is List) {
          rawList = res['data'] as List;
        }
      }

      final parsed = rawList.whereType<Map<String, dynamic>>().map((item) => Map<String, dynamic>.from(item)).toList();

      if (mounted) {
        setState(() {
          _myTickets = parsed;
          _ticketsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _myTickets = [];
          _ticketsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFaqs() async {
    setState(() => _faqsLoading = true);

    try {
      final res = await _apiClient.get(
        '/public/faqs',
        queryParameters: {'category': 'Customer', 'status': 'published'},
      );

      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map<String, dynamic>) {
        if (res['items'] is List) {
          rawList = res['items'] as List;
        } else if (res['results'] is List) {
          rawList = res['results'] as List;
        } else if (res['result'] is Map && res['result']['items'] is List) {
          rawList = res['result']['items'] as List;
        }
      }

      if (rawList.isNotEmpty) {
        final parsed = rawList
            .map((item) {
              final map = item is Map ? item : {};

              return {'question': (map['question'] ?? '').toString(), 'answer': (map['answer'] ?? '').toString()};
            })
            .where((e) => e['question']!.isNotEmpty)
            .toList();

        if (mounted && parsed.isNotEmpty) {
          setState(() {
            _faqs = parsed;
            _faqsLoading = false;
          });

          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _faqs = _defaultFaqs;
        _faqsLoading = false;
      });
    }
  }

  static const List<Map<String, String>> _defaultFaqs = [
    {
      'question': 'How do I track my live courier rider?',
      'answer': 'SunGguard provides real-time GPS navigation and docket timeline tracking for all parcels. Open your active consignment docket to monitor your courier rider live.',
    },
    {
      'question': 'What is the 4-digit handover code?',
      'answer': 'A secure 4-digit OTP is required during pickup and handover. Share this code with the verified delivery partner only after receiving/giving the parcel.',
    },
    {
      'question': 'What happens if the receiver is unavailable?',
      'answer': 'Our rider will attempt to contact the receiver at the doorstep. If unreachable, the consignment is securely returned to base or rescheduled per your instructions.',
    },
    {
      'question': 'How are parcel fares calculated?',
      'answer': 'Fares are transparently calculated using distance, parcel weight category, speed tier, and applicable government taxes with zero hidden surcharges.',
    },
    {
      'question': 'How do I request a refund?',
      'answer': 'You can raise a refund ticket directly on this screen under "Refund request". Our customer support team reviews and processes refunds within 24 business hours.',
    },
  ];

  void _openComplaintModal({
    String categoryId = 'other',
    String? orderId,
    String? parcelId,
    String? subject,
    String? description,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ComplaintModalSheet(
        apiClient: _apiClient,
        initialCategory: categoryId,
        initialOrderId: orderId,
        initialParcelId: parcelId,
        initialSubject: subject,
        initialDescription: description,
        onSuccess: () {
          _fetchMyTickets();
        },
      ),
    );
  }

  Future<void> _callSupport() async {
    final cleanPhone = _supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppSnackBar.showInfo(context, '${AppLocalizations.of(context)!.supportCallUs}: $_supportPhone');
      }
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:$_supportEmail?subject=Customer Support Inquiry');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppSnackBar.showInfo(context, '${AppLocalizations.of(context)!.supportEmailUs}: $_supportEmail');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22.0, color: Color(0xFF0F172A)),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: Builder(
          builder: (context) {
            return Text(
              AppLocalizations.of(context)!.profileSupport,
              style: AppTypography.headingLarge.copyWith(
                fontSize: 19.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: () async {
          await Future.wait([_fetchMyTickets(), _fetchFaqs()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrimaryComplaintCta(),
              const SizedBox(height: AppSpacing.xl),
              _buildComplaintCategories(),
              const SizedBox(height: AppSpacing.xl),
              _buildContactChannels(),
              const SizedBox(height: AppSpacing.xl),
              _buildMyComplaintsSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildFaqSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildLegalSection(),
              const SizedBox(height: 60.0),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Primary Hero Card
  Widget _buildPrimaryComplaintCta() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071630), Color(0xFF0D2854)],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [BoxShadow(color: Color(0x240C831F), blurRadius: 16.0, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openComplaintModal(categoryId: 'other'),
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.supportHeroTag,
                        style: AppTypography.monoLabelLight.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        l10n.supportHeroTitle,
                        style: AppTypography.headingMedium.copyWith(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        l10n.supportHeroSub,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.0,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14.0),
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Complaint Categories
  Widget _buildComplaintCategories() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            l10n.supportComplaintType,
            style: AppTypography.bodyBold.copyWith(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.85,
          ),
          itemCount: kComplaintCategories.length,
          itemBuilder: (context, index) {
            final cat = kComplaintCategories[index];
            final localizedCatLabel = cat.label;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: () => _openComplaintModal(categoryId: cat.id),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(cat.icon, size: 18.0, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        localizedCatLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 3. Contact Channels
  Widget _buildContactChannels() {
    final emailDisplay = _supportEmail.length > 12 ? '${_supportEmail.substring(0, 12)}...' : _supportEmail;
    final l10n = AppLocalizations.of(context)!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
      childAspectRatio: 1.45,
      children: [
        _buildContactCard(
          icon: Icons.chat_bubble_outline_rounded,
          label: l10n.supportChatUs,
          sub: l10n.supportChatSub,
          onTap: () {
            context.push(AppRoutes.chat);
          },
        ),
        _buildContactCard(
          icon: Icons.add_circle_outline_rounded,
          label: l10n.supportNewComplaint,
          sub: l10n.supportWriteDetails,
          onTap: () => _openComplaintModal(categoryId: 'other'),
        ),
        _buildContactCard(
          icon: Icons.phone_outlined,
          label: l10n.supportCallUs,
          sub: '+91 98765...',
          onTap: _callSupport,
        ),
        _buildContactCard(
          icon: Icons.mail_outline_rounded,
          label: l10n.supportEmailUs,
          sub: emailDisplay,
          onTap: _emailSupport,
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10.0)),
                child: Icon(icon, size: 20.0, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2.0),
              Text(
                sub,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. My Complaints
  Widget _buildMyComplaintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.supportMyComplaints,
                style: AppTypography.bodyBold.copyWith(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: _fetchMyTickets,
                borderRadius: BorderRadius.circular(4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  child: Text(
                    'REFRESH',
                    style: AppTypography.monoLabel.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),

        // Status tabs. Nothing here changes what is fetched — the endpoint
        // returns every ticket in one call — so filtering is local.
        if (!_ticketsLoading && _myTickets.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ticketFilters.map((filter) {
                final isActive = _ticketFilter == filter;
                final count = _countForFilter(filter);
                final label = filter == 'all'
                    ? 'All'
                    : '${filter[0].toUpperCase()}${filter.substring(1)}';
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _ticketFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '$label ($count)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12.0),
        ],

        if (_ticketsLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Center(
              child: Text('Loading…', style: TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8))),
            ),
          )
        else if (_myTickets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const Text(
                  'No complaints yet',
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'When you file one, it appears here and on Admin → Help Tickets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else if (_filteredTickets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Center(
              child: Text(
                'No $_ticketFilter complaints',
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredTickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10.0),
            itemBuilder: (context, index) {
              return _buildTicketCard(_filteredTickets[index]);
            },
          ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final subject = (ticket['subject'] ?? 'Complaint').toString();

    final description = (ticket['description'] ?? '').toString();

    final status = (ticket['status'] ?? 'open').toString().toLowerCase();

    final category = (ticket['category'] ?? '').toString();

    final ticketId = (ticket['_id'] ?? ticket['id'] ?? '').toString();

    final createdAtRaw = ticket['createdAt']?.toString();

    String formattedDate = '';

    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtRaw);
        formattedDate = DateFormat('d MMM').format(dt);
      } catch (_) {}
    }

    Color statusBg;
    Color statusText;
    String statusLabel;

    if (status == 'closed') {
      statusBg = const Color(0xFFF1F5F9);
      statusText = const Color(0xFF475569);
      statusLabel = 'CLOSED';
    } else if (status == 'processing') {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFF92400E);
      statusLabel = 'IN PROGRESS';
    } else {
      statusBg = AppColors.navySoft;
      statusText = AppColors.navyText;
      statusLabel = status.toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (ticketId.isNotEmpty) {
              context.push('${AppRoutes.chat}?ticketId=$ticketId');
            } else {
              context.push(AppRoutes.chat);
            }
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B), height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12.0)),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: statusText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    if (category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    if (formattedDate.isNotEmpty) ...[
                      const Icon(Icons.access_time_rounded, size: 12.0, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4.0),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 13.0, color: AppColors.navy),
                    const SizedBox(width: 5.0),
                    Text(
                      'Open chat with admin',
                      style: AppTypography.bodyBold.copyWith(
                        fontSize: 11.5,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            'Frequently Asked Questions',
            style: AppTypography.bodyBold.copyWith(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        if (_faqsLoading)
          const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2.0)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10.0),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              final isExpanded = _expandedFaqIndices.contains(index);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedFaqIndices.remove(index);
                            } else {
                              _expandedFaqIndices.add(index);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['question'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF64748B),
                                size: 20.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 14.0),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              faq['answer'] ?? '',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGAL',
            style: AppTypography.monoLabel.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildLegalRow(
            title: 'Terms & Conditions',
            icon: Icons.description_outlined,
            onTap: () {
              context.push(AppRoutes.terms);
            },
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20.0),
          _buildLegalRow(
            title: 'Privacy Policy',
            icon: Icons.shield_outlined,
            onTap: () {
              context.push(AppRoutes.privacy);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalRow({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18.0, color: const Color(0xFF475569)),
          const SizedBox(width: 10.0),
          Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Bottom Sheet for Filing Complaints
// ============================================================

class _ComplaintModalSheet extends StatefulWidget {
  final ApiClient apiClient;
  final String initialCategory;
  final String? initialOrderId;
  final String? initialParcelId;
  final String? initialSubject;
  final String? initialDescription;
  final VoidCallback onSuccess;

  const _ComplaintModalSheet({
    required this.apiClient,
    required this.initialCategory,
    this.initialOrderId,
    this.initialParcelId,
    this.initialSubject,
    this.initialDescription,
    required this.onSuccess,
  });

  @override
  State<_ComplaintModalSheet> createState() => _ComplaintModalSheetState();
}

class _ComplaintModalSheetState extends State<_ComplaintModalSheet> {
  late String _category;
  late String _priority;

  late final TextEditingController _subjectCtrl;
  late final TextEditingController _orderIdCtrl;
  late final TextEditingController _parcelIdCtrl;
  late final TextEditingController _descCtrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _category = widget.initialCategory;

    _priority = (_category == 'payment' || _category == 'refund') ? 'high' : 'medium';

    final categoryObj = kComplaintCategories.firstWhere(
      (c) => c.id == _category,
      orElse: () => kComplaintCategories.last,
    );

    _subjectCtrl = TextEditingController(text: widget.initialSubject ?? categoryObj.subject);

    _orderIdCtrl = TextEditingController(text: widget.initialOrderId ?? '');

    _parcelIdCtrl = TextEditingController(text: widget.initialParcelId ?? '');

    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _orderIdCtrl.dispose();
    _parcelIdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onSelectCategory(ComplaintCategory cat) {
    setState(() {
      _category = cat.id;

      if (_subjectCtrl.text.trim().isEmpty || kComplaintCategories.any((c) => c.subject == _subjectCtrl.text.trim())) {
        _subjectCtrl.text = cat.subject;
      }

      if (_category == 'payment' || _category == 'refund') {
        _priority = 'high';
      }
    });
  }

  Future<void> _submitComplaint() async {
    final subject = _subjectCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (subject.isEmpty) {
      AppSnackBar.showError(context, AppLocalizations.of(context)!.complaintSubjectLabel);
      return;
    }

    if (description.isEmpty) {
      AppSnackBar.showError(context, AppLocalizations.of(context)!.complaintHappenedLabel);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'subject': subject,
        'description': description,
        'priority': _priority,
        'category': _category,
        if (_category == 'order' || _category == 'refund') 'relatedOrderId': _orderIdCtrl.text.trim(),
        if (_category == 'parcel') 'relatedParcelId': _parcelIdCtrl.text.trim(),
        'userType': 'User',
      };

      await widget.apiClient.post(ApiEndpoints.createTicket, data: payload);

      if (mounted) {
        AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.success);

        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, viewInsets.bottom + 24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2.0)),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.complaintFileTitle,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      l10n.complaintFileSub,
                      style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 18.0),

            Text(
              l10n.complaintCategoryLabel,
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.0,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 8.0),

            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: kComplaintCategories.map((cat) {
                final isSelected = _category == cat.id;
                final localizedCatLabel = cat.label;

                return ChoiceChip(
                  label: Text(
                    localizedCatLabel,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.navy,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(color: isSelected ? AppColors.navy : const Color(0xFFCBD5E1)),
                  ),
                  onSelected: (_) => _onSelectCategory(cat),
                );
              }).toList(),
            ),

            const SizedBox(height: 16.0),

            Text(
              l10n.complaintSubjectLabel,
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.0,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6.0),

            TextField(
              controller: _subjectCtrl,
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: l10n.complaintSubjectHint,
                hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              ),
            ),

            if (_category == 'order' || _category == 'refund') ...[
              const SizedBox(height: 14.0),

              Text(
                'ORDER ID (OPTIONAL)',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.0,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 6.0),

              TextField(
                controller: _orderIdCtrl,
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. ORD-123456',
                  hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ],

            if (_category == 'parcel') ...[
              const SizedBox(height: 14.0),

              Text(
                'PARCEL ID (OPTIONAL)',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.0,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 6.0),

              TextField(
                controller: _parcelIdCtrl,
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Parcel ID ending digits are fine',
                  hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ],

            const SizedBox(height: 14.0),

            Text(
              l10n.complaintPriorityLabel,
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.0,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6.0),

            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Material(
                      color: isSelected ? AppColors.navy : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.0),
                      child: InkWell(
                        onTap: () => setState(() => _priority = p),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: isSelected ? AppColors.navy : const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              p.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14.0),

            Text(
              l10n.complaintHappenedLabel,
              style: AppTypography.monoLabel.copyWith(
                fontSize: 10.0,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 6.0),

            TextField(
              controller: _descCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: l10n.complaintHappenedHint,
                hintStyle: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16.0),
              ),
            ),

            const SizedBox(height: 20.0),

            SizedBox(
              width: double.infinity,
              height: 52.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                ),
                onPressed: _isSubmitting ? null : _submitComplaint,
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.0,
                            height: 18.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Text(
                            'SUBMITTING...',
                            style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text(
                            l10n.complaintSubmitBtn,
                            style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 10.0),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 13.0, color: Color(0xFF94A3B8)),
                SizedBox(width: 4.0),
                Text(
                  'Visible in Admin → Help Tickets',
                  style: TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
