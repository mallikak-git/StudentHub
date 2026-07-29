import 'package:flutter/material.dart';
import 'screens/tasks_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/events_screen.dart';
import 'screens/timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }
  final List<Widget> _screens = const [
    _DashboardTab(),
    TasksScreen(),
    BudgetScreen(),
    EventsScreen(),
    TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF6C63FF).withValues(alpha:0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Timer'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
         child: CustomScrollView(
            slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$greeting! \u{1F44B}',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: const [
                    _QuickCard(title: 'Tasks', icon: Icons.task_alt, color: Color(0xFFFF6584), index: 1),
                    _QuickCard(title: 'Budget', icon: Icons.account_balance_wallet, color: Color(0xFF43E97B), index: 2),
                    _QuickCard(title: 'Events', icon: Icons.event, color: Color(0xFFF7971E), index: 3),
                    _QuickCard(title: 'Study Timer', icon: Icons.timer, color: Color(0xFF6C63FF), index: 4),
                  ],
                ),
                const SizedBox(height: 20),
                _TipCard(),
              ]),
            ),
          ),
        ],
       )
      ),
    )
      );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int index;
  const _QuickCard({required this.title, required this.icon, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Switch to the tab via the parent
        final state = context.findAncestorStateOfType<_HomeScreenState>();
        if (state != null) {
    state.switchTab(index);
  }
},
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha:0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final List<String> tips = const [
    'Break big tasks into smaller ones to stay focused.',
    'Use the Pomodoro technique: 25 min focus, 5 min break.',
    'Track every expense — small ones add up fast!',
    'Review your week every Sunday to plan ahead.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = tips[DateTime.now().weekday % tips.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tip of the Day', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
