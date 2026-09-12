import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CourseItem {
  final String id;
  final String platform;
  final String title;
  final String subtitle;
  final String instructor;
  final String duration;
  final int lessonsCount;
  final String level;
  final String badgeText;
  final String statusText;
  final String price;
  final double rating;
  final int enrolledCount;
  final String description;
  final String thumbnail;
  final IconData platformIcon;
  final Color platformColor;
  final List<Color> gradientColors;
  final List<String> features;
  final String? titleAr;
  final String? titleEn;
  final String? descriptionAr;

  const CourseItem({
    required this.id,
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.instructor,
    required this.duration,
    required this.lessonsCount,
    required this.level,
    required this.badgeText,
    required this.statusText,
    required this.price,
    required this.rating,
    required this.enrolledCount,
    required this.description,
    required this.thumbnail,
    required this.platformIcon,
    required this.platformColor,
    required this.gradientColors,
    required this.features,
    this.titleAr,
    this.titleEn,
    this.descriptionAr,
  });
}

class CoursesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CoursesScreen({super.key, this.onBack});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const Color brandRed = Color(0xFFE50914);
  String _selectedCategory = 'All';
  final Set<String> _notifiedCourseIds = {};

  final List<String> _categories = [
    'All',
    'Facebook',
    'Instagram',
    'TikTok',
  ];

  late final List<CourseItem> _courses = [
    const CourseItem(
      id: 'facebook_course',
      platform: 'Facebook',
      title: 'LEADS CAMPAIGN FACEBOOK',
      subtitle: 'Meta Ads & Real Estate Lead Generation',
      instructor: 'Orientation Media Lab • Meta Ads Specialists',
      duration: '1 Hour',
      lessonsCount: 4,
      level: 'All Levels',
      badgeText: 'FACEBOOK • META',
      statusText: 'UPLOAD SOON',
      price: '300 LE',
      rating: 4.9,
      enrolledCount: 380,
      description:
          'An intensive 4-episode masterclass on launching high-converting Meta Leads Campaigns for real estate agencies and brokers, targeting high-net-worth buyers and slashing cost per lead.',
      thumbnail: 'assets/courses/facebook.PNG',
      platformIcon: Icons.facebook,
      platformColor: Color(0xFF1877F2),
      gradientColors: [Color(0xFF0D254C), Color(0xFF091426), Color(0xFF060B14)],
      features: [
        'Episode 1: Business Manager setup & building high-converting Instant Forms',
        'Episode 2: Precision targeting for investors & high-net-worth buyers',
        'Episode 3: Writing persuasive ad copy & visual creatives for projects',
        'Episode 4: Lead qualification workflows & instant CRM closing tactics',
      ],
    ),
    const CourseItem(
      id: 'instagram_course',
      platform: 'Instagram',
      title: 'LEADS CAMPAIGN INSTAGRAM',
      subtitle: 'Instagram Growth & Direct Lead Generation',
      instructor: 'Orientation Creative Studio • Real Estate Creators',
      duration: '1 Hour',
      lessonsCount: 3,
      level: 'All Levels',
      badgeText: 'INSTAGRAM • REELS',
      statusText: 'UPLOAD SOON',
      price: '300 LE',
      rating: 4.9,
      enrolledCount: 420,
      description:
          'A specialized 3-episode course on leveraging Instagram DMs, Stories, and Reels to capture qualified property buyers and turn engagements into booked site visits.',
      thumbnail: 'assets/courses/instagram.PNG',
      platformIcon: Icons.camera_alt_outlined,
      platformColor: Color(0xFFE1306C),
      gradientColors: [Color(0xFF4A1028), Color(0xFF260814), Color(0xFF120309)],
      features: [
        'Episode 1: Designing Stories & Reels that stop the property buyer scroll',
        'Episode 2: Direct message ad campaigns & native Instagram Lead Forms',
        'Episode 3: Automated DM response workflows to secure phone numbers & visits',
      ],
    ),
    const CourseItem(
      id: 'tiktok_course',
      platform: 'TikTok',
      title: 'LEADS CAMPAIGN TIKTOK',
      subtitle: 'TikTok Viral Ads & Instant Lead Forms',
      instructor: 'Orientation Growth Team • TikTok Marketing Experts',
      duration: '1 Hour',
      lessonsCount: 4,
      level: 'All Levels',
      badgeText: 'TIKTOK • VIRAL',
      statusText: 'UPLOAD SOON',
      price: '300 LE',
      rating: 4.8,
      enrolledCount: 310,
      description:
          'A 4-episode blueprint for dominating TikTok with instant lead generation forms, creating compelling hooks in the first 3 seconds, and turning views into serious buyer inquiries.',
      thumbnail: 'assets/courses/tiktok.PNG',
      platformIcon: Icons.play_arrow_rounded,
      platformColor: Color(0xFF00F2FE),
      gradientColors: [Color(0xFF0B3338), Color(0xFF071B1E), Color(0xFF030D0F)],
      features: [
        'Episode 1: The 3-second property hook & crafting engaging ad creatives',
        'Episode 2: Launching and optimizing TikTok Instant Lead Generation Forms',
        'Episode 3: Budget bidding strategies to eliminate wasted ad spend',
        'Episode 4: Rapid response workflows to book qualified sales meetings',
      ],
    ),
  ];

  List<CourseItem> get _filteredCourses {
    if (_selectedCategory == 'All') return _courses;
    return _courses
        .where((c) => c.platform.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _showComingSoonModal(BuildContext context, CourseItem course) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isNotified = _notifiedCourseIds.contains(course.id);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  top: 12,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF121214).withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: course.platformColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: course.platformColor.withValues(alpha: 0.2),
                      blurRadius: 35,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pull bar
                      Container(
                        width: 44,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // Thumbnail Preview in Modal
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: course.platformColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.193,
                            child: Image.asset(
                              course.thumbnail,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Badges Row: Upload Soon & Price
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'UPLOAD SOON',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              course.price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Course Titles
                      Text(
                        course.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        course.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Info bar: Episodes & Duration
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.video_library_rounded, size: 16, color: course.platformColor),
                                const SizedBox(width: 6),
                                Text(
                                  '${course.lessonsCount} Episodes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 16, color: Colors.white24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  course.duration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 16, color: Colors.white24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.signal_cellular_alt_rounded, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  course.level,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Course summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          course.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Episodes Breakdown
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Course Curriculum & Episodes:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Column(
                        children: course.features.map((feat) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: course.platformColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: course.platformColor,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    feat,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Action Button (Notify Me)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (_notifiedCourseIds.contains(course.id)) {
                              _notifiedCourseIds.remove(course.id);
                            } else {
                              _notifiedCourseIds.add(course.id);
                            }
                          });
                          setModalState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: isNotified
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF1B5E20),
                                      Color(0xFF2E7D32),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      course.platformColor,
                                      course.platformColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isNotified
                                        ? const Color(0xFF2E7D32)
                                        : course.platformColor)
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isNotified
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isNotified
                                      ? 'Alert Enabled! We will notify you on launch'
                                      : 'Notify Me When Launched',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Dismiss button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: canPop
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  )
                : null,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: brandRed.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: brandRed.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: brandRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Orientation Academy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            centerTitle: !canPop,
          ),

          // Hero Banner
          SliverToBoxAdapter(
            child: _buildHeroBanner(),
          ),

          // Platform Filter Chips
          SliverToBoxAdapter(
            child: _buildCategoryChips(),
          ),

          // Courses List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = _filteredCourses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildCourseCard(course),
                  );
                },
                childCount: _filteredCourses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E0709),
            Color(0xFF121214),
            Colors.black,
          ],
        ),
        border: Border.all(
          color: brandRed.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: brandRed.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: brandRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'LEADS CAMPAIGNS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '300 LE / Course',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Master Real Estate Leads Marketing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '3 specialized masterclasses teaching you how to generate qualified property buyers and close deals across Facebook, Instagram, and TikTok.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Wrap ensures responsive badges without any RenderFlex overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureBadge(Icons.facebook, 'Facebook Leads', const Color(0xFF1877F2)),
              _buildFeatureBadge(Icons.camera_alt_outlined, 'Instagram Leads', const Color(0xFFE1306C)),
              _buildFeatureBadge(Icons.play_arrow_rounded, 'TikTok Leads', const Color(0xFF00F2FE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? brandRed : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? brandRed
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat == 'All' ? 'All Courses' : cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(CourseItem course) {
    return GestureDetector(
      onTap: () => _showComingSoonModal(context, course),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121214),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: course.platformColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Visual Banner
            _buildCourseThumbnail(course),

            // Details Container
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform Badge & Price Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: course.platformColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: course.platformColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(course.platformIcon, size: 13, color: course.platformColor),
                            const SizedBox(width: 5),
                            Text(
                              course.platform,
                              style: TextStyle(
                                color: course.platformColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Price Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE50914),
                              Color(0xFFB81D24),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          course.price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Titles
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Bottom Action Bar: Episodes, Duration, Upload Soon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${course.lessonsCount} Episodes',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.duration,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.statusText,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseThumbnail(CourseItem course) {
    return AspectRatio(
      aspectRatio: 1.193, // Exact aspect ratio of the 2938x2463 / 940x788 images
      child: Image.asset(
        course.thumbnail,
        fit: BoxFit.cover,
      ),
    );
  }
}
