import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_9cyyl8i4.json',
      headline: 'Welcome to AI Daily Tips!',
      description:
          'Get smarter every day with personalized, AI-powered tips delivered right to your device.',
    ),
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json',
      headline: 'Choose Your Interests',
      description:
          'Add topics you care about—like productivity, coding, wellness, and more. The app will generate tips just for you.',
    ),
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_2ks3pjua.json',
      headline: 'Never Miss a Tip',
      description:
          'Set up custom notification schedules. Get tips at the perfect time, even when the app is closed.',
    ),
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json',
      headline: 'Learn, Save, and Share',
      description:
          'View your tip history, mark favorites, and share insights with friends.',
    ),
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json',
      headline: 'Your Data, Your Control',
      description:
          'Your topics and tips are private. You control your notifications and data.',
    ),
    _OnboardingPageData(
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_1pxqjqps.json',
      headline: 'Enable Notifications',
      description:
          'To deliver daily tips, please allow notification permissions.',
    ),
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // On finish: set hasSeenWelcome and go to home (no permission dialog here)
      final settings = Hive.box('settings');
      await settings.put('hasSeenWelcome', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => _buildDot(i)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: CupertinoButton.filled(
                child:
                    Text(_currentPage == _pages.length - 1 ? 'Finish' : 'Next'),
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int i) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _currentPage == i
            ? CupertinoColors.activeBlue
            : CupertinoColors.inactiveGray,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OnboardingPageData {
  final String lottieUrl;
  final String headline;
  final String description;
  const _OnboardingPageData(
      {required this.lottieUrl,
      required this.headline,
      required this.description});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              child: Lottie.network(
                data.lottieUrl,
                repeat: true,
                animate: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              data.headline,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              data.description,
              style: const TextStyle(
                  fontSize: 18, color: CupertinoColors.secondaryLabel),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
