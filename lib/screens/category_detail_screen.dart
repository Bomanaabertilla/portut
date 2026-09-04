import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/initials_avatar.dart';
import 'blog_post_screen.dart';
import 'create_post_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryTag; // e.g. '📱 Flutter', '⚛️ React', '🚀 Startups'

  const CategoryDetailScreen({
    super.key,
    required this.categoryTag,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  bool _isJoined = false;
  String? _currentUserId;
  Set<String> _bookmarkedPostIds = {};
  List<Post> _customCategoryPosts = [];

  Future<void> _addNewCategoryPost(Post newPost) async {
    try {
      final categoryHashtag = '#${_cleanName.toLowerCase()}';
      final updatedDescription = newPost.description.contains('#')
          ? newPost.description
          : '${newPost.description}\n\n$categoryHashtag';
      final categoryPost = newPost.copyWith(description: updatedDescription);

      await _postService.savePost(
        _currentUserId ?? categoryPost.authorId,
        categoryPost.toMap(),
      );

      if (mounted) {
        setState(() {
          _customCategoryPosts.insert(0, categoryPost);
        });
        _tabController.animateTo(2); // Automatically switch to Discussions tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posted in $categoryHashtag!'),
            backgroundColor: const Color(0xFF8B4513),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding category post: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final user = await _authService.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user.username;
        _isJoined = prefs.getBool('joined_category_${widget.categoryTag}_${user.username}') ?? false;
        final savedBookmarks = prefs.getStringList('bookmarks_${user.username}') ?? [];
        _bookmarkedPostIds = savedBookmarks.toSet();
      });
    }
  }

  Future<void> _toggleJoin() async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final newState = !_isJoined;
    setState(() {
      _isJoined = newState;
    });
    await prefs.setBool('joined_category_${widget.categoryTag}_$_currentUserId', newState);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Joined ${widget.categoryTag} community!' : 'Left ${widget.categoryTag} community',
          ),
          backgroundColor: const Color(0xFF8B4513),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Extract clean category name without emoji
  String get _cleanName {
    final parts = widget.categoryTag.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return widget.categoryTag;
  }

  // Extract emoji
  String get _emoji {
    final parts = widget.categoryTag.split(' ');
    if (parts.isNotEmpty && parts.first.runes.length <= 4) {
      return parts.first;
    }
    return '🌟';
  }

  // Get curated category information
  Map<String, dynamic> _getCategoryInfo() {
    final name = _cleanName.toLowerCase();
    if (name.contains('flutter')) {
      return {
        'tagline': 'Cross-Platform App Development with Expressive UI',
        'about': 'Build gorgeous, natively compiled applications for mobile, web, desktop, and embedded devices from a single codebase using Dart & Impeller.',
        'members': '54.2K members',
        'postsToday': '1,420 posts today',
        'gradient': [const Color(0xFF02569B), const Color(0xFF0175C2)],
        'topics': ['Impeller Engine', 'State Management', 'Riverpod vs Bloc', 'Custom Shaders'],
        'articles': [
          {
            'title': '10 Flutter 3.24 Performance Hacks You Need in 2026',
            'readTime': '5 min read',
            'author': 'Alex Rivera',
            'handle': 'arivera_flutter',
            'summary': 'Master RepaintBoundary, const constructors, isolate compute methods, and Impeller shader warmup to achieve smooth 120 FPS performance.',
            'likes': 342,
            'comments': 48,
            'reposts': 89,
            'tag': '#flutter #dart',
          },
          {
            'title': 'State Management Battleground: Riverpod 3.0 vs Signals vs Bloc',
            'readTime': '8 min read',
            'author': 'Sarah Jenkins',
            'handle': 'sjenkins_dev',
            'summary': 'Comprehensive benchmark testing reactivity, memory overhead, code boilerplate, and devtool support across production Flutter apps.',
            'likes': 512,
            'comments': 94,
            'reposts': 135,
            'tag': '#state #architecture',
          },
          {
            'title': 'Building Pixel-Perfect Micro-Animations with Flutter Canvas & Rive',
            'readTime': '6 min read',
            'author': 'David Chen',
            'handle': 'dchen_ui',
            'summary': 'Step-by-step guide to integrating interactive 2D vector animations with zero lag using CustomPainter and Rive runtime.',
            'likes': 289,
            'comments': 31,
            'reposts': 67,
            'tag': '#design #animation',
          },
        ],
        'tips': [
          '💡 Use "const" everywhere possible to let Flutter reuse Widget instances during rebuilds.',
          '🔥 Test Impeller engine rendering with "flutter run --enable-impeller" for seamless 120Hz smooth scrolling.',
          '⚡ Use Isolate.run() for expensive JSON parsing tasks to keep the UI main thread smooth.',
        ],
      };
    } else if (name.contains('react')) {
      return {
        'tagline': 'Modern Web & Mobile Interfaces with React & Next.js',
        'about': 'Explore React Server Components, Next.js App Router, Concurrent Mode, and React Native New Architecture.',
        'members': '89.1K members',
        'postsToday': '3,110 posts today',
        'gradient': [const Color(0xFF20232A), const Color(0xFF61DAFB)],
        'topics': ['Next.js 15', 'Server Components', 'React Native Fabric', 'Zustand State'],
        'articles': [
          {
            'title': 'React Server Components: Deep Dive into Zero-Bundle-Size Architecture',
            'readTime': '7 min read',
            'author': 'Dan Abramov Fan',
            'handle': 'react_insider',
            'summary': 'How RSC streams HTML directly from servers to client devices, eliminating heavy client-side JavaScript bundles.',
            'likes': 620,
            'comments': 112,
            'reposts': 204,
            'tag': '#react #nextjs',
          },
          {
            'title': 'Optimizing React Native App Launch Time by 45%',
            'readTime': '4 min read',
            'author': 'Elena Rostova',
            'handle': 'elena_rn',
            'summary': 'Migrating to Hermes engine, enabling Lazy Bundle loading, and optimizing TurboModules for instant app startup.',
            'likes': 415,
            'comments': 56,
            'reposts': 98,
            'tag': '#reactnative #mobile',
          },
        ],
        'tips': [
          '💡 Wrap heavy computations in useMemo() and callbacks in useCallback() to prevent unnecessary renders.',
          '🚀 Use Next.js dynamic imports for below-the-fold components to slash initial page load time.',
        ],
      };
    } else if (name.contains('startup')) {
      return {
        'tagline': 'Indie Hackers, Product Builders & Venture Creators',
        'about': 'From 0 to 1: Sharing product launches, growth playbooks, SaaS metrics, and fundraising stories.',
        'members': '41.8K members',
        'postsToday': '890 posts today',
        'gradient': [const Color(0xFFD84315), const Color(0xFFFF6F00)],
        'topics': ['Indie Hacking', 'YC Playbook', 'Bootstrapping', 'SaaS Growth'],
        'articles': [
          {
            'title': 'From 0 to \$10,000 MRR in 90 Days: Our Indie Hacker Playbook',
            'readTime': '6 min read',
            'author': 'Marc Lou',
            'handle': 'marclou_build',
            'summary': 'The exact tech stack, pricing model, viral launch strategy, and Cold DM sequence we used to get 200 paying SaaS customers.',
            'likes': 890,
            'comments': 167,
            'reposts': 340,
            'tag': '#saas #indiehacker',
          },
          {
            'title': 'How We Pitched Y Combinator & Got Accepted on Our 2nd Attempt',
            'readTime': '9 min read',
            'author': 'Samantha Wu',
            'handle': 'sam_founder',
            'summary': 'Key lessons learned from our failed interview, how we pivoted our pitch deck, and how we proved product-market fit.',
            'likes': 740,
            'comments': 103,
            'reposts': 210,
            'tag': '#yc #fundraising',
          },
        ],
        'tips': [
          '💡 Talk to 10 potential customers before writing a single line of code to validate real pain points.',
          '📈 Launch early and iterate fast. If you are not embarrassed by your v1, you launched too late.',
        ],
      };
    } else if (name.contains('ui') || name.contains('ux')) {
      return {
        'tagline': 'Human-Centered Design, Systems & Dark Aesthetics',
        'about': 'Mastering color theory, typography scale, responsive layouts, glassmorphism, and seamless micro-interactions.',
        'members': '38.4K members',
        'postsToday': '950 posts today',
        'gradient': [const Color(0xFF8E24AA), const Color(0xFFD81B60)],
        'topics': ['Design Systems', 'Figma Tokens', 'Micro-interactions', 'Accessibility'],
        'articles': [
          {
            'title': 'The 2026 Micro-Animation Guidelines for Mobile UI Design',
            'readTime': '5 min read',
            'author': 'Chloe Bennett',
            'handle': 'chloe_design',
            'summary': 'Why subtle haptic feedback and spring physics (300ms easing) double user engagement and delight.',
            'likes': 530,
            'comments': 72,
            'reposts': 142,
            'tag': '#ui #ux',
          },
          {
            'title': 'Building Accessible Dark Mode Color Palettes in Figma',
            'readTime': '7 min read',
            'author': 'Marcus Vance',
            'handle': 'mvance_ui',
            'summary': 'Avoiding pure #000000 blacks, implementing elevation-based surface grays, and ensuring WCAG AAA contrast ratios.',
            'likes': 410,
            'comments': 45,
            'reposts': 99,
            'tag': '#darkmode #accessibility',
          },
        ],
        'tips': [
          '💡 Always maintain an 8pt grid system for predictable padding, margins, and component sizing.',
          '✨ Use subtle elevation shadows instead of harsh black borders for a premium, modern feel.',
        ],
      };
    } else if (name.contains('ai') || name.contains('ml')) {
      return {
        'tagline': 'Artificial Intelligence, GenAI & Neural Architectures',
        'about': 'Exploring Large Language Models, Vision Transformers, Autonomous AI Agents, RAG pipelines, and Ollama embeddings.',
        'members': '67.3K members',
        'postsToday': '2,890 posts today',
        'gradient': [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
        'topics': ['LLMs & RAG', 'AI Agents', 'PyTorch 2.5', 'Ollama Local'],
        'articles': [
          {
            'title': 'Building Local Autonomous AI Agents with Ollama & LangChain',
            'readTime': '8 min read',
            'author': 'Dr. Aris Thorne',
            'handle': 'athorne_ai',
            'summary': 'Run Llama 3 8B locally on your laptop with zero API cost, vector database memory indexing, and function calling tools.',
            'likes': 980,
            'comments': 142,
            'reposts': 410,
            'tag': '#ai #llm',
          },
          {
            'title': 'Prompt Engineering Masterclass: Chain of Thought & Few-Shot RAG',
            'readTime': '6 min read',
            'author': 'Priya Patel',
            'handle': 'priya_ml',
            'summary': 'How structured JSON schema output and system prompt constraints eliminate LLM hallucinations in production apps.',
            'likes': 670,
            'comments': 88,
            'reposts': 195,
            'tag': '#prompting #genai',
          },
        ],
        'tips': [
          '💡 Use chunking sizes of 512 tokens with 10% overlap when building RAG vector embeddings.',
          '🤖 Quantize models to 4-bit GGUF format to run 70B parameter models smoothly on consumer GPUs.',
        ],
      };
    } else if (name.contains('history')) {
      return {
        'tagline': 'Ancient Civilizations, World Events & Cultural Legacies',
        'about': 'Delve into human history from ancient Rome, Egypt, and Greece to medieval empires, world conflicts, and archaeological discoveries.',
        'members': '62.4K members',
        'postsToday': '1,840 posts today',
        'gradient': [const Color(0xFF4A2E1C), const Color(0xFF8D5B4C)],
        'topics': ['Ancient Rome', 'World War II', 'Archaeology', 'Industrial Era'],
        'articles': [
          {
            'title': 'The Rise and Fall of the Roman Republic: Lessons for Modern Democracy',
            'readTime': '9 min read',
            'author': 'Prof. Marcus Vance',
            'handle': 'mvance_history',
            'summary': 'An analysis of political polarization, agrarian reforms, and military expansion that led to the transition from Republic to Empire.',
            'likes': 740,
            'comments': 112,
            'reposts': 230,
            'tag': '#history #rome',
          },
          {
            'title': 'Deciphering the Rosetta Stone: How Champollion Unlocked Ancient Egypt',
            'readTime': '6 min read',
            'author': 'Dr. Evelyn Carter',
            'handle': 'ecarter_arch',
            'summary': 'The 1822 breakthroughs in linguistic decoding that opened three millennia of Egyptian hieroglyphic records to the world.',
            'likes': 520,
            'comments': 64,
            'reposts': 145,
            'tag': '#egypt #archaeology',
          },
        ],
        'tips': [
          '📜 Read primary historical source documents to gain unvarnished insights into historical perspectives.',
          '🏛️ Explore digital museum archives (e.g. British Museum, Smithsonian) to inspect 3D scans of ancient artifacts.',
        ],
      };
    } else if (name.contains('medicine') || name.contains('health')) {
      return {
        'tagline': 'Clinical Research, Medical Science & Human Physiology',
        'about': 'Explore breakthrough clinical trials, pharmacology, surgical innovations, genetics, neuroscience, and evidence-based wellness.',
        'members': '78.9K members',
        'postsToday': '2,450 posts today',
        'gradient': [const Color(0xFF00695C), const Color(0xFF00897B)],
        'topics': ['CRISPR Gene Therapy', 'Neuroscience', 'Immunology', 'Clinical Trials'],
        'articles': [
          {
            'title': 'CRISPR 3.0: Gene Editing Breakthroughs in Hereditary Disease Therapies',
            'readTime': '8 min read',
            'author': 'Dr. Maya Lin, MD',
            'handle': 'mayalin_med',
            'summary': 'How targeted base editing is curing sickle cell anemia and ushering in a new era of personalized genetic medicine.',
            'likes': 890,
            'comments': 135,
            'reposts': 310,
            'tag': '#medicine #genetics',
          },
          {
            'title': 'The Science of Circadian Rhythms: Optimizing Sleep & Cognitive Endurance',
            'readTime': '7 min read',
            'author': 'Dr. Robert Sterling',
            'handle': 'rsterling_neuro',
            'summary': 'Understanding Adenosine buildup, REM sleep cycles, and morning light exposure to maximize daily focus and longevity.',
            'likes': 950,
            'comments': 168,
            'reposts': 420,
            'tag': '#health #neuroscience',
          },
        ],
        'tips': [
          '🩺 Cross-reference medical claims with peer-reviewed literature on PubMed and Europe PMC before drawing conclusions.',
          '💤 Aim for 7-9 hours of consistent sleep nightly to facilitate glymphatic brain detox and memory consolidation.',
        ],
      };
    } else if (name.contains('football') || name.contains('sport')) {
      return {
        'tagline': 'Tactical Breakdowns, Match Analysis & Transfer Insights',
        'about': 'The beautiful game! In-depth match tactics, European leagues, Champions League analysis, expected goals (xG), and player scouting.',
        'members': '95.3K members',
        'postsToday': '4,120 posts today',
        'gradient': [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        'topics': ['High Pressing', 'Expected Goals (xG)', 'Tactical Analysis', 'Transfers'],
        'articles': [
          {
            'title': 'Tactical Masterclass: How Inverted Full-backs Overload Central Midfield',
            'readTime': '6 min read',
            'author': 'Gabriel Silva',
            'handle': 'gsilva_tactics',
            'summary': 'Deconstructing Pep Guardiola and Mikel Arteta\'s tactical build-up structures in modern European football.',
            'likes': 1120,
            'comments': 240,
            'reposts': 510,
            'tag': '#football #tactics',
          },
          {
            'title': 'Data Analytics in Football Scouting: Finding Undervalued Talent with Metric Models',
            'readTime': '8 min read',
            'author': 'Liam O\'Connor',
            'handle': 'liam_analytics',
            'summary': 'How progressive passes, pressure success rates, and xA models transformed transfer window strategies for elite clubs.',
            'likes': 780,
            'comments': 110,
            'reposts': 290,
            'tag': '#football #analytics',
          },
        ],
        'tips': [
          '⚽ Observe off-the-ball runs and defensive positioning rather than just following the ball during live matches.',
          '📊 Analyze expected goals (xG) and expected threat (xT) metrics to evaluate performance beyond raw scorelines.',
        ],
      };
    } else if (name.contains('finance') || name.contains('market') || name.contains('money')) {
      return {
        'tagline': 'Wealth Building, Markets, Macroeconomics & Investing',
        'about': 'Master personal finance, passive index fund investing, stock market valuation, macroeconomic interest rates, and financial independence.',
        'members': '83.1K members',
        'postsToday': '3,410 posts today',
        'gradient': [const Color(0xFF1A237E), const Color(0xFF283593)],
        'topics': ['Index Funds', 'Macroeconomics', 'FIRE Movement', 'Stock Valuation'],
        'articles': [
          {
            'title': 'The Boglehead Strategy: Automating Index Fund Wealth Creation in 2026',
            'readTime': '7 min read',
            'author': 'Nathaniel Cross',
            'handle': 'ncross_finance',
            'summary': 'Why low-cost S&P 500 and Total World index funds outperform 92% of actively managed Wall Street funds over 15+ years.',
            'likes': 1240,
            'comments': 215,
            'reposts': 580,
            'tag': '#finance #investing',
          },
          {
            'title': 'Understanding Interest Rates, Inflation & Federal Reserve Monetary Policy',
            'readTime': '9 min read',
            'author': 'Claire Vance',
            'handle': 'cvance_econ',
            'summary': 'How yield curves, central bank balance sheets, and quantitative easing impact real estate, stocks, and bond yields.',
            'likes': 830,
            'comments': 142,
            'reposts': 320,
            'tag': '#economics #markets',
          },
        ],
        'tips': [
          '💰 Build a liquid emergency fund covering 3-6 months of essential living expenses before taking market risks.',
          '📈 Harness compound interest early: regular dollar-cost averaging in broad market index funds builds long-term wealth.',
        ],
      };
    } else if (name.contains('gaming')) {
      return {
        'tagline': 'Game Design, Graphics Engines, Esports & Game Culture',
        'about': 'Unreal Engine 5 shaders, Unity C# scripting, AAA game development, speedrunning, and competitive esports strategies.',
        'members': '71.5K members',
        'postsToday': '2,980 posts today',
        'gradient': [const Color(0xFF311B92), const Color(0xFF4527A0)],
        'topics': ['Unreal Engine 5', 'Esports', 'Game Mechanics', 'Shader Magic'],
        'articles': [
          {
            'title': 'Unreal Engine 5.5 Nanite & Lumen Shader Optimization for 60 FPS Console Games',
            'readTime': '8 min read',
            'author': 'Kaito Tanaka',
            'handle': 'kaito_gamedev',
            'summary': 'Managing geometry budgets, ray-traced global illumination, and virtual shadow maps in large open-world games.',
            'likes': 890,
            'comments': 128,
            'reposts': 340,
            'tag': '#gamedev #unrealengine',
          },
        ],
        'tips': [
          '🎮 Balance frame rate stability and visual fidelity by tuning shadow resolution and volumetric fog settings.',
        ],
      };
    } else if (name.contains('music')) {
      return {
        'tagline': 'Audio Production, Composition, Music Theory & Arts',
        'about': 'Sound synthesis, mixing & mastering, digital audio workstations (Ableton, Logic), acoustics, and musical composition.',
        'members': '39.7K members',
        'postsToday': '1,120 posts today',
        'gradient': [const Color(0xFF880E4F), const Color(0xFFAD1457)],
        'topics': ['Ableton Live', 'Sound Synthesis', 'Mixing & Mastering', 'Music Theory'],
        'articles': [
          {
            'title': 'Mixing & Mastering Masterclass: Achieving Commercial Audio Punch & Clarity',
            'readTime': '7 min read',
            'author': 'Leo Soundworks',
            'handle': 'leosound_prod',
            'summary': 'Subtractive EQ, multiband compression, gain staging, and stereo imaging techniques for professional audio masters.',
            'likes': 640,
            'comments': 82,
            'reposts': 190,
            'tag': '#music #audio',
          },
        ],
        'tips': [
          '🎵 Use high-pass filtering on non-bass tracks at 80Hz to clear up muddy low-end frequencies in your mix.',
        ],
      };
    } else if (name.contains('travel')) {
      return {
        'tagline': 'Global Travel, Digital Nomad Guides & Cultures',
        'about': 'Budget travel hacks, remote work destinations, cultural immersion, solo travel safety, and landscape photography.',
        'members': '45.1K members',
        'postsToday': '1,380 posts today',
        'gradient': [const Color(0xFF004D40), const Color(0xFF00695C)],
        'topics': ['Digital Nomad', 'Solo Travel', 'Budget Hacks', 'World Photography'],
        'articles': [
          {
            'title': 'The Ultimate 2026 Digital Nomad Guide to Remote Work Hotspots',
            'readTime': '6 min read',
            'author': 'Sophia Martinez',
            'handle': 'sophia_travels',
            'summary': 'Top cities with fast internet, co-working communities, affordable living costs, and favorable nomad visas.',
            'likes': 790,
            'comments': 105,
            'reposts': 280,
            'tag': '#travel #nomad',
          },
        ],
        'tips': [
          '✈️ Use travel credit cards without foreign transaction fees and always pay in local currency at ATMs.',
        ],
      };
    } else if (name.contains('science')) {
      return {
        'tagline': 'Physics, Astronomy, Biotechnology & Scientific Discovery',
        'about': 'Exploring astrophysics, quantum mechanics, synthetic biology, space exploration, and groundbreaking scientific research.',
        'members': '61.2K members',
        'postsToday': '1,980 posts today',
        'gradient': [const Color(0xFF1A237E), const Color(0xFF311B92)],
        'topics': ['Astrophysics', 'Quantum Computing', 'James Webb Telescope', 'BioTech'],
        'articles': [
          {
            'title': 'James Webb Telescope Deep Space Discoveries: Unveiling Early Galaxies',
            'readTime': '8 min read',
            'author': 'Dr. Neil Vane',
            'handle': 'neil_astro',
            'summary': 'How infrared spectroscopy is observing cosmic dawn and analyzing atmospheric compositions of habitable exoplanets.',
            'likes': 1050,
            'comments': 189,
            'reposts': 460,
            'tag': '#science #astronomy',
          },
        ],
        'tips': [
          '🔬 Follow open-access research repositories like arXiv and bioRxiv for cutting-edge preprints.',
        ],
      };
    } else if (name.contains('cloud')) {
      return {
        'tagline': 'Cloud Computing, Serverless & Infrastructure as Code',
        'about': 'Architecting resilient cloud systems, Kubernetes clusters, Terraform IaC, AWS Lambda, and Cloudflare Workers.',
        'members': '31.2K members',
        'postsToday': '720 posts today',
        'gradient': [const Color(0xFF00838F), const Color(0xFF00ACC1)],
        'topics': ['Kubernetes', 'Serverless', 'Terraform', 'AWS vs Cloudflare'],
        'articles': [
          {
            'title': 'Kubernetes Production Best Practices for High Availability in 2026',
            'readTime': '7 min read',
            'author': 'Victor Hugo',
            'handle': 'vhugo_devops',
            'summary': 'Pod disruption budgets, horizontal pod autoscaling metrics, and zero-downtime rolling upgrades.',
            'likes': 380,
            'comments': 54,
            'reposts': 87,
            'tag': '#k8s #devops',
          },
        ],
        'tips': [
          '💡 Set memory and CPU resource limits on all Docker containers to avoid OOMKills in Kubernetes.',
        ],
      };
    } else {
      // Careers / Default
      return {
        'tagline': 'Engineering Career Growth, Leadership & Remote Work',
        'about': 'Navigating tech career milestones, Staff Engineer pathways, system design interviews, and remote team productivity.',
        'members': '49.6K members',
        'postsToday': '1,150 posts today',
        'gradient': [const Color(0xFF3E2723), const Color(0xFF8B4513)],
        'topics': ['System Design', 'Staff Engineer', 'Remote Work', 'Salary Negotiation'],
        'articles': [
          {
            'title': 'How to Pass System Design Interviews at Top Tech Companies',
            'readTime': '10 min read',
            'author': 'Gaurav Sen Fan',
            'handle': 'sys_design_pro',
            'summary': 'A step-by-step framework for estimating traffic, selecting database engines, caching layers, and load balancers under pressure.',
            'likes': 810,
            'comments': 124,
            'reposts': 290,
            'tag': '#careers #interviews',
          },
          {
            'title': 'The Remote Developer Productivity Playbook: Deep Work Routines',
            'readTime': '5 min read',
            'author': 'Hannah Abbott',
            'handle': 'hannah_remote',
            'summary': 'Async communication rules, blocking focus hours, and preventing burnout when working across timezones.',
            'likes': 490,
            'comments': 67,
            'reposts': 115,
            'tag': '#remotework #productivity',
          },
        ],
        'tips': [
          '💡 Document your technical achievements weekly in a "Brag Doc" for seamless performance reviews.',
          '🎯 Focus on high-leverage architectural impact to transition from Senior to Staff Engineer.',
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF1D9BF0) : const Color(0xFF8B4513);
    final theme = Theme.of(context);
    final info = _getCategoryInfo();
    final List<Color> gradientColors = info['gradient'] as List<Color>;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF424242)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _cleanName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF424242),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : const Color(0xFF424242)),
            onPressed: () {
              Share.share('Check out the latest discussions in ${widget.categoryTag} on PorTuT!');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: isDark ? Colors.white : const Color(0xFF424242),
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Pro Tips'),
            Tab(text: 'Discussions'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result != null && result is Post && mounted) {
            await _addNewCategoryPost(result);
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note, size: 22),
        label: Text('Post in #${_cleanName.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                        ),
                        ElevatedButton.icon(
                          onPressed: _toggleJoin,
                          icon: Icon(
                            _isJoined ? Icons.check_circle : Icons.add_circle_outline,
                            size: 18,
                            color: _isJoined ? Colors.white : gradientColors.first,
                          ),
                          label: Text(
                            _isJoined ? 'Joined' : 'Join Community',
                            style: TextStyle(
                              color: _isJoined ? Colors.white : gradientColors.first,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isJoined ? Colors.white24 : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.categoryTag,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info['tagline'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      info['about'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatBadge(Icons.people, info['members'] as String),
                        const SizedBox(width: 10),
                        _buildStatBadge(Icons.bar_chart, info['postsToday'] as String),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (info['topics'] as List<String>).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '# $t',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Articles & Tutorials
            _buildArticlesTab(info['articles'] as List<Map<String, dynamic>>, isDark, primaryColor),

            // Tab 2: Pro Tips
            _buildTipsTab(info['tips'] as List<String>, isDark, primaryColor),

            // Tab 3: Discussions
            _buildDiscussionsTab(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesTab(List<Map<String, dynamic>> articles, bool isDark, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final art = articles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: isDark ? 0 : 1.5,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          InitialsAvatar(name: art['author'] as String, size: 28, fontSize: 12),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              art['author'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF424242),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 13, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        art['readTime'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  art['title'] as String,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF14171A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  art['summary'] as String,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  art['tag'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildArticleAction(Icons.favorite_border, '${art['likes']}'),
                    _buildArticleAction(Icons.mode_comment_outlined, '${art['comments']}'),
                    _buildArticleAction(Icons.repeat, '${art['reposts']}'),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      onPressed: () {
                        Share.share('Read "${art['title']}" on PorTuT!');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticleAction(IconData icon, String count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 17, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsTab(List<String> tips, bool isDark, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2C) : primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tips[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF333333),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscussionsTab(bool isDark, Color primaryColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _postService.getAllPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _customCategoryPosts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        final postsData = snapshot.data ?? [];
        final List<Post> savedPosts = postsData
            .map((p) => Post.fromMap(p, p['authorId'] ?? 'user'))
            .toList();

        // Merge newly created category posts with saved posts (avoid duplicates by ID)
        final Map<String, Post> postMap = {};
        for (final p in _customCategoryPosts) {
          postMap[p.id] = p;
        }
        for (final p in savedPosts) {
          if (!postMap.containsKey(p.id)) {
            postMap[p.id] = p;
          }
        }

        final List<Post> posts = postMap.values.toList();
        posts.sort((a, b) {
          final aTime = DateTime.tryParse(a.timestamp) ?? DateTime.now();
          final bTime = DateTime.tryParse(b.timestamp) ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No discussions yet in $_cleanName. Be the first!',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: posts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          itemBuilder: (context, index) {
            final post = posts[index];
            final isLiked = _currentUserId != null && post.likedUsers.contains(_currentUserId);
            final isBookmarked = _bookmarkedPostIds.contains(post.id);

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BlogPostScreen(post: post)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsAvatar(name: post.authorName, size: 38, fontSize: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF424242),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '@${post.authorId}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF14171A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLiked ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.comments}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 16,
                                color: isBookmarked ? primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
  }
}
