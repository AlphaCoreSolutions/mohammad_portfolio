import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for LogicalKeyboardKey
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

const _bgTop = Color(0xFFE9F0F3);
const _bgBottom = Color(0xFFA2A5AC);

List<Color> _pageGradientColors(int index, int total) {
  final t = (total <= 1) ? 1.0 : (index.clamp(0, total - 1)) / (total - 1);
  // Top color gradually morphs toward bottom; bottom stays bottom.
  final topNow = Color.lerp(_bgTop, _bgBottom, t)!;
  return [topNow, Color(0xFF153466).withOpacity(0.45)];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF153466); // logo color
    const slogan = Color(0xFF4B4B4B); // slogan color
    const ink = Color(0xFF1A1A1A); // touches

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: slogan),
        bodyLarge: TextStyle(height: 1.35, color: ink),
        bodyMedium: TextStyle(color: slogan),
      ),
    );

    return Theme(data: theme, child: const PortfolioShell());
  }
}

Future<void> _safeLaunch(Uri uri, {LaunchMode? mode}) async {
  try {
    final ok = await launchUrl(uri, mode: mode ?? LaunchMode.platformDefault);
    if (!ok) {
      debugPrint('Could not launch: $uri');
      // Optional: show a SnackBar for UX
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open $uri')));
    }
  } catch (e, st) {
    debugPrint('launch error: $e\n$st');
  }
}

/// SHELL: full-bleed content + overlay tabs (no side chunks)
class PortfolioShell extends StatefulWidget {
  const PortfolioShell({super.key});
  @override
  State<PortfolioShell> createState() => _PortfolioShellState();
}

class _PortfolioShellState extends State<PortfolioShell> {
  final PageController _pageCtrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FocusableActionDetector(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.arrowDown): ScrollIntent(
            direction: AxisDirection.down,
          ),
          LogicalKeySet(LogicalKeyboardKey.pageDown): ScrollIntent(
            direction: AxisDirection.down,
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): ScrollIntent(
            direction: AxisDirection.up,
          ),
          LogicalKeySet(LogicalKeyboardKey.pageUp): ScrollIntent(
            direction: AxisDirection.up,
          ),
        },
        actions: <Type, Action<Intent>>{
          ScrollIntent: CallbackAction<ScrollIntent>(
            onInvoke: (intent) {
              final dir = intent.direction;
              if (dir == AxisDirection.down && _index < _sections.length - 1)
                _goTo(_index + 1);
              if (dir == AxisDirection.up && _index > 0) _goTo(_index - 1);
              return null;
            },
          ),
        },
        child: Stack(
          children: [
            // Background gradient that evolves per tab
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _pageGradientColors(_index, _sections.length),
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _sections.length,
              physics: const PageScrollPhysics(),
              itemBuilder: (context, i) {
                final isCurrent = i == _index;
                final nearby = (i - _index).abs() <= 1;

                final child = nearby
                    ? _sections[i].builder(context)
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 1.4),
                      );

                // Disable tickers when the page isn't current
                return TickerMode(enabled: isCurrent, child: child);
              },
            ),

            // Thin top progress line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: LinearProgressIndicator(
                  value: (_index + 1) / _sections.length,
                  minHeight: 2,
                  color: scheme.primary.withOpacity(.7),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

            // RIGHT TABS — overlay (doesn't push content)
            Positioned(
              right: size.width < 700 ? 8 : 18,
              top: size.height * 0.24,
              child: _RightTabs(current: _index, onTap: _goTo),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------- Sections -------

class SectionSpec {
  final String id;
  final WidgetBuilder builder;
  const SectionSpec(this.id, this.builder);
}

final List<SectionSpec> _sections = [
  SectionSpec('hero', (c) => const _HeroSection()),
  SectionSpec('metrics', (c) => const _MetricsSection()),
  SectionSpec('products', (c) => const _ProductsSection()),
  SectionSpec('ethos', (c) => const _EthosSection()),
  SectionSpec('contact', (c) => const _ContactSection()),
];

/// 1) HERO — flush to the right & top (like your first design)
class _HeroSection extends StatefulWidget {
  const _HeroSection();
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _inCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _inCtrl,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _inCtrl.stop();
    _inCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // gentle float for the hero image
    final t = (DateTime.now().millisecondsSinceEpoch / 2200) % (2 * math.pi);
    final floatY = math.sin(t) * 6;

    // ---- Keep the image exactly like your original look ----
    // We’ll size the image first, then place the chips UNDER it as a separate widget.
    // To avoid bottom overflow, we compute a dynamic image height that leaves room for chips.
    // Estimate the chip block height (2 rows worst-case + spacing).
    const baseChipBlock = 112.0; // ~ two rows of chips + spacing
    final extraBottom = size.height < 760
        ? 20.0
        : 28.0; // breathing room on short screens
    final reservedForChips = baseChipBlock + extraBottom;

    // compute image height so the whole hero (image + chips) fits the viewport
    final computedImageH = (size.height - reservedForChips).clamp(
      size.height * 0.58,
      size.height * 0.78,
    );
    final isWide = size.width >= 1100;
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        return SizedBox(
          height: size.height,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGE AREA (flush to top & right; only left corners rounded)
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  height: computedImageH,
                  width: isWide ? 1800 : 450,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: _fade.value,
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(5),
                              bottomLeft: Radius.circular(63),
                            ),
                            child: SizedBox.expand(
                              child: Image.asset(
                                'lib/assets/mohammad.jpg',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Info box on top of the image (unchanged)
                      Positioned(
                        left: size.width < 900 ? -40 : -70,
                        bottom: 25,
                        child: const _InfoBox(
                          title: 'Mohammad Abu Jalboush',
                          subtitle: 'CEO — VISION CIT',
                          blurb:
                              'Speed without compromise. Enterprise systems, elegant UX, and measurable outcomes.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // SPACE between image and chips
              const SizedBox(height: 14),

              // CHIPS AREA — use full width so they form fewer rows
              Padding(
                padding: EdgeInsets.symmetric(
                  // smaller side padding = more usable width
                  horizontal: size.width >= 1400
                      ? 24
                      : size.width >= 1000
                      ? 18
                      : 8,
                ),
                child: SizedBox(
                  width: double.infinity, // let chips occupy the whole row
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 7,
                    alignment:
                        WrapAlignment.spaceEvenly, // spread across the row
                    children: const [
                      _HeroChip(
                        label: 'Cross-Platform Apps (Flutter • Web • Mobile)',
                      ),
                      _HeroChip(label: 'Robust APIs & Integrations (.NET)'),
                      _HeroChip(label: 'Secure Auth & Data Protection'),
                      _HeroChip(label: 'Performance, Monitoring & Analytics'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }
}

/// SECTION SHELL with built-in overflow handling (no layout overflow)
class _SectionReveal extends StatefulWidget {
  const _SectionReveal({
    required this.title,
    required this.subtitle,
    required this.body,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final String? footnote;

  @override
  State<_SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<_SectionReveal>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slideTitle =
      Tween(begin: const Offset(0, .18), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(.05, .55, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<Offset> _slideBody =
      Tween(begin: const Offset(0, .12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(.25, 1, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _ctrl.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = math.min(48.0, size.width * .04);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 40, horizontal, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slideTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.displayMedium!
                            .copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1A1A1A),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: const Color(0xFF4B4B4B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slideBody,
                    child: ScrollConfiguration(
                      behavior: _NoGlowBehavior(),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: size.height * 0.02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            widget.body,
                            if (widget.footnote != null) ...[
                              const SizedBox(height: 20),
                              Opacity(
                                opacity: .8,
                                child: Text(
                                  widget.footnote!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(.22)),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x14000000))],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF153466), // brand primary
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // remove glow on all platforms
  }
}

/// 2) METRICS — responsive cards (wrap nicely, no overflow)
class _MetricsSection extends StatelessWidget {
  const _MetricsSection();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 840;

    return _SectionReveal(
      title: 'Vision in Numbers',
      subtitle: 'Signals that matter. Outcomes you can measure.',
      body: Wrap(
        alignment: WrapAlignment.start,
        spacing: 16,
        runSpacing: 16,
        children: const [
          _MetricCard(
            kpi: '15',
            label: 'Enterprise Clients',
            note: '+5 this quarter',
          ),
          _MetricCard(
            kpi: '14',
            label: 'Products & Platforms',
            note: 'Core + Labs',
          ),
          _MetricCard(
            kpi: '99.96%',
            label: 'Uptime SLO',
            note: 'Last 12 months',
            /*
                      kpi: 99.96% → your service was available 99.96% of the time.

          label: Uptime SLO → that number is your Service Level Objective (target you aim to meet).

          note: Last 12 months → measured over a rolling 12-month window.

          What 99.96% means in downtime

          99.96% uptime = 0.04% downtime (your “error budget”).

          Per year (365d): ~ 210 minutes (~ 3h 30m) of total downtime

          Per 30-day month: ~ 17.3 minutes

          Per week: ~ 4.0 minutes

          Per day: ~ 35 seconds

          Quick glossary (useful if you show more KPIs)

          SLI (Service Level Indicator): the raw measurement (e.g., % of requests under 300ms, or % uptime).

          SLO (Service Level Objective): your target (e.g., 99.96%).

          SLA (Service Level Agreement): a contract with customers, usually with penalties if breached.
                      */
          ),
          _MetricCard(
            kpi: '4.9★',
            label: 'Avg. NPS / CSAT',
            note: 'Across projects',
          ),
        ],
      ),
      footnote: isNarrow
          ? 'Tip: rotate your device for more KPIs per row.'
          : 'Velocity, reliability, retention — measured continuously.',
    );
  }
}

/// 3) PRODUCTS — compact product cards in a responsive wrap (no overflow)
class _ProductsSection extends StatelessWidget {
  const _ProductsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionReveal(
      title: 'Flagship Systems',
      subtitle: 'From POS to AI-powered Fraud Analytics — built for scale.',
      body: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          // FEATURED: ERP (wider card)
          _ProductCard(
            title: 'Vision ERP (Enterprise Suite)',
            bullets: [
              'Finance • Inventory • HR/Payroll',
              'Multi-branch • Multi-currency • VAT',
              'Workflow engine • Roles & approvals',
            ],
          ),

          _ProductCard(
            title: 'ServicesRQ Rent',
            bullets: [
              'heavy machinery renting',
              'Smart availability',
              'Conflict resolver',
              'Reviews + SLA',
            ],
          ),
          _ProductCard(
            title: 'Vision POS+',
            bullets: [
              'Omnichannel',
              'Modular receipts & HW',
              'Offline-first sync',
              'full wireless integration',
            ],
          ),
          // CRM
          _ProductCard(
            title: 'Vision CRM',
            bullets: [
              'Leads → Deals pipeline',
              'Omnichannel: WhatsApp/Email/SMS',
              'Dashboards • Segmentation • Automations',
            ],
          ),
        ],
      ),
      footnote:
          'Every product ships with clean APIs and “no dead-ends” customization.',
    );
  }
}

/// 4) CASE STUDIES — compact, responsive
/* 
class _CaseStudiesSection extends StatelessWidget {
  const _CaseStudiesSection();

  @override
  Widget build(BuildContext context) {
    return _SectionReveal(
      title: 'Impact Stories',
      subtitle: 'Selected results across fintech, retail, and logistics.',
      body: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          _CaseCard(
            client: 'Zain Jordan — eShop',
            headline: 'Chargebacks −37% in 90 days',
            details:
                'Deployed risk rules + pipelines; stabilized SLOs under peak load.',
          ),
          _CaseCard(
            client: 'Arafat Sweets (KSA)',
            headline: 'POS rollout in 12 stores / 4 weeks',
            details:
                'Centralized inventory + cloud sync; cashier training in 2 days.',
          ),
          _CaseCard(
            client: 'Nirvana Chalets',
            headline: 'Bookings ↑22% with dynamic availability',
            details: 'Blocking logic, pricing tiers, faster checkout.',
          ),
        ],
      ),
      footnote: 'Ask for PDF dossiers with KPIs, timelines, stack, and team.',
    );
  }
}
*/
/// 5) ETHOS
class _EthosSection extends StatelessWidget {
  const _EthosSection();
  @override
  Widget build(BuildContext context) {
    return _SectionReveal(
      title: 'Build Ethos',
      subtitle:
          'Speed without compromise. Design that ages well. Code you can trust.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Bullet(
            'Micro-animations on every interaction — nothing feels static.',
          ),
          _Bullet(
            'Adaptive design systems: layouts morph \nacross devices instantly.',
          ),
          _Bullet('Sub-second load budgets: every screen aims for <400ms TTI.'),
          _Bullet(
            'Design with motion: transitions tell a story, \nnot just swap screens.',
          ),
          _Bullet('Pixel-perfect typography tuned for readability and impact.'),
          _Bullet('Realtime data by default — no “refresh” button needed.'),
          _Bullet(
            'Edge + Cloud first: deployments \noptimized for latency & uptime.',
          ),
          _Bullet('Accessibility baked-in (contrast, voice, AR/VR readiness).'),
          _Bullet(
            'Dark mode, glassmorphism, and gradient fluency — not afterthoughts.',
          ),
          _Bullet(
            'Obsessed with detail: custom cursors, hover states, tactile feedback.',
          ),
          _Bullet(
            'AI-augmented workflows — predictive dashboards, smart defaults.',
          ),
          _Bullet(
            'No templates reused — every client gets a bespoke design system.',
          ),
        ],
      ),
      footnote:
          'Every pixel, every frame, every millisecond — engineered for impact.',
    );
  }
}

/// 6) CONTACT
class _ContactSection extends StatelessWidget {
  const _ContactSection();
  @override
  Widget build(BuildContext context) {
    return _SectionReveal(
      title: 'Let’s build something unmistakable.',
      subtitle: 'Partnering on high-impact builds across MENA and beyond.',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 920,
          ), // keeps it tidy on wide screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'CEO - Client Success Manager',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 1),
                    Container(
                      height: 2,
                      width: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF153466), Color(0xFFA2A5AC)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'mohammad@visioncit.com',
                        );
                        await Clipboard.setData(
                          const ClipboardData(text: 'mohammad@visioncit.com'),
                        );
                        await _safeLaunch(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Text(
                        'mohammad@visioncit.com',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 60,
                      child: Divider(thickness: 1.5, color: Colors.black26),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: '+962776110639');
                        await _safeLaunch(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Text(
                        '+962 7 7611 0639',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final whatsapp = Uri.parse(
                          'https://wa.me/962776110639',
                        );
                        await _safeLaunch(
                          whatsapp,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Text(
                        'Tap here to connect instantly via WhatsApp for professional inquiries.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HQ', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Al-Hashmi Al-Shamali, Amman, Jordan',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),

                    // ⬇️ Use the groups directly; don't put it inside another Wrap.
                    const _CapabilityGroups(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      footnote: 'Response in 24h. NDAs welcomed.',
    );
  }

  /*
  Widget _Chip(ColorScheme scheme, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: scheme.primaryContainer.withOpacity(.45),
      border: Border.all(color: scheme.primary.withOpacity(.25)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  */
}

/// ------- Right Tabs (overlay) -------
class _RightTabs extends StatelessWidget {
  const _RightTabs({required this.current, required this.onTap});
  final int current;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        width: 52,
        margin: const EdgeInsets.only(bottom: 12), // extra room for tab 6
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.36),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_sections.length, (i) {
            final isActive = i == current;

            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.fromLTRB(
                  8,
                  i == _sections.length - 1 ? 8 : 6,
                  8,
                  6,
                ),
                height: isActive ? 40 : 36,
                width: isActive ? 40 : 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.white : Colors.white,
                  border: Border.all(
                    width: isActive ? 3 : 1.2,
                    color: isActive
                        ? scheme.primary.withOpacity(.85)
                        : scheme.primary.withOpacity(.25),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: scheme.primary.withOpacity(.28),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(.7),
                            blurRadius: 2,
                            spreadRadius: -1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                    color: isActive ? scheme.primary : scheme.primary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ------- Building blocks -------
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.kpi,
    required this.label,
    required this.note,
  });
  final String kpi;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Compact card to avoid overflow
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kpi,
              style: Theme.of(
                context,
              ).textTheme.displayMedium!.copyWith(letterSpacing: -1.4),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              note,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.title, required this.bullets});
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: bullets.map((b) => _Tag(b)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/*
class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.client,
    required this.headline,
    required this.details,
  });
  final String client;
  final String headline;
  final String details;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              headline,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(details),
          ],
        ),
      ),
    );
  }
}
*/
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(.35),
        border: Border.all(color: scheme.primary.withOpacity(.2)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    // ignore: unused_element_parameter
    this.width,
    // ignore: unused_element_parameter
    this.height,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}

/// Your original InfoBox (kept)
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.subtitle, this.blurb});

  final String title;
  final String subtitle;

  final String? blurb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      shadowColor: scheme.primary.withOpacity(.35),
      child: Container(
        height: 190,
        width: 409,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withOpacity(.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4B4B4B),
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                    ),
                  ),
                  if (blurb != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      blurb!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4B4B4B), // slogan color
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Capabilities Section (grouped, responsive, animated) ---
/*
class _CapabilitiesSection extends StatelessWidget {
  const _CapabilitiesSection();

  @override
  Widget build(BuildContext context) {
    return _SectionReveal(
      title: 'Capabilities',
      subtitle: 'From discovery to delivery — end-to-end execution.',
      body: const _CapabilityGroups(),
      footnote: 'Built for reliability, speed, and maintainability.',
    );
  }
}
*/

class _CapabilityGroups extends StatelessWidget {
  const _CapabilityGroups();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cols = size.width >= 1200
        ? 3
        : size.width >= 820
        ? 2
        : 1;
    final maxGroupWidth = 420.0;

    final groups = <_CapabilityGroupData>[
      _CapabilityGroupData(
        title: 'Business',
        icon: Icons.business_center_outlined,
        items: const [
          'Business Development',
          'Requirements & Scoping',
          'Project Management',
          'Agile Delivery',
          'QA & UAT',
        ],
      ),
      _CapabilityGroupData(
        title: 'Engineering',
        icon: Icons.integration_instructions_outlined,
        items: const [
          'Flutter (iOS • Android • Web)',
          '.NET APIs & Services',
          'REST & JSON APIs',
          'Secure Auth (JWT/OAuth)',
          'Performance Tuning',
        ],
      ),
      _CapabilityGroupData(
        title: 'Platform',
        icon: Icons.cloud_outlined,
        items: const [
          'Firebase (Auth • FCM • Analytics)',
          'App Releases (Google Play • App Store)',
          'Monitoring & Crash Reports',
          'Google Maps (Places • Routes)',
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (_, __) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: groups.map((g) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: cols == 1 ? double.infinity : maxGroupWidth,
                minWidth: 260,
              ),
              child: _CapabilityGroupCard(data: g),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CapabilityGroupData {
  final String title;
  final IconData icon;
  final List<String> items;
  const _CapabilityGroupData({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _CapabilityGroupCard extends StatelessWidget {
  const _CapabilityGroupCard({required this.data});
  final _CapabilityGroupData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                data.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < data.items.length; i++)
                _CapabilityPill(
                  label: data.items[i],
                  // staggered entrance
                  delayMs: 40 * i,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityPill extends StatefulWidget {
  const _CapabilityPill({required this.label, this.delayMs = 0});
  final String label;
  final int delayMs;

  @override
  State<_CapabilityPill> createState() => _CapabilityPillState();
}

class _CapabilityPillState extends State<_CapabilityPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, .12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delayMs == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 160),
            tween: Tween(begin: 0, end: 1),
            builder: (context, t, child) {
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {}, // optional: open a case study / detail later
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.58),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: scheme.primary.withOpacity(.22)),
                    boxShadow: const [
                      BoxShadow(blurRadius: 10, color: Color(0x14000000)),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF153466),
                      letterSpacing: .2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
