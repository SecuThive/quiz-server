import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // 광고 초기화
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      textTheme: GoogleFonts.gowunDodumTextTheme(),
      scaffoldBackgroundColor: Colors.white,
      primarySwatch: Colors.deepPurple,
    ),
    home: const SplashScreen(),
  ));
}

// =======================
// 0. 스플래시 화면
// =======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MenuPage(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text("AI 심리연구소", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================
// 1. 메뉴 페이지 (서버 연동 + NEW 뱃지)
// =======================
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<dynamic> _menuList = [];
  bool _isLoading = true;

  // ★ 나중에 본인의 GitHub 주소로 바꾸세요! (지금은 비워두면 로컬 파일 읽음)
  final String serverUrl = ""; 
  // 예: "[https://raw.githubusercontent.com/아이디/리포지토리/main/assets/](https://raw.githubusercontent.com/아이디/리포지토리/main/assets/)";

  @override
  void initState() {
    super.initState();
    loadMenu();
  }

  Future<void> loadMenu() async {
    try {
      // 1. 서버 시도
      if (serverUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(serverUrl + "index.json"));
        if (response.statusCode == 200) {
          setState(() {
            _menuList = json.decode(utf8.decode(response.bodyBytes));
            _isLoading = false;
          });
          return;
        }
      }
      throw Exception("서버 없음");
    } catch (e) {
      // 2. 실패 시 로컬 파일 로드 (백업)
      try {
        final String localData = await rootBundle.loadString('assets/index.json');
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _menuList = json.decode(localData);
          _isLoading = false;
        });
      } catch (e) {
         setState(() => _isLoading = false);
      }
    }
  }

  final List<List<Color>> gradients = [
    [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
    [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
    [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("오늘의 테스트", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuList.isEmpty
              ? const Center(child: Text("데이터가 없습니다."))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _menuList.length,
                  itemBuilder: (context, index) {
                    final item = _menuList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PsychTestPage(
                            fileKey: item['key'], 
                            title: item['title'],
                            serverUrl: serverUrl // 주소 전달
                          )));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(colors: gradients[index % gradients.length]),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(child: Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        if (item['is_new'] == true) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                                            child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(item['desc'], style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13), maxLines: 1),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// =======================
// 2. 퀴즈 페이지 (광고 + 로직)
// =======================
class PsychTestPage extends StatefulWidget {
  final String fileKey;
  final String title;
  final String serverUrl;
  const PsychTestPage({super.key, required this.fileKey, required this.title, required this.serverUrl});
  @override
  State<PsychTestPage> createState() => _PsychTestPageState();
}

class _PsychTestPageState extends State<PsychTestPage> {
  Map<String, dynamic>? _fullData;
  List<dynamic> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final List<int> _userAnswers = [];
  
  // 광고 관련
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    loadQuizData();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ★ 테스트용 ID (출시 전 진짜 ID로 교체)
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  Future<void> loadQuizData() async {
    try {
      String jsonString;
      if (widget.serverUrl.isNotEmpty) {
        // 서버에서 로드
        final res = await http.get(Uri.parse("${widget.serverUrl}${widget.fileKey}.json"));
        jsonString = utf8.decode(res.bodyBytes);
      } else {
        // 로컬에서 로드
        jsonString = await rootBundle.loadString('assets/${widget.fileKey}.json');
      }
      
      final data = json.decode(jsonString);
      setState(() {
        _fullData = data;
        _questions = data['questions'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onAnswer(int index) {
    setState(() => _userAnswers.add(index));
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showResult();
    }
  }

  void _showResult() {
    // 최빈값 계산 (A,B,C,D 중 가장 많이 나온 것)
    Map<int, int> counts = {};
    for (var a in _userAnswers) { counts[a] = (counts[a] ?? 0) + 1; }
    int maxIdx = 0, maxVal = 0;
    counts.forEach((k, v) { if (v > maxVal) { maxVal = v; maxIdx = k; } });

    final result = _fullData!['results'][maxIdx]; // 결과가 없으면 에러날 수 있으니 주의

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ResultPage(title: result['title'], content: result['content'], type: result['type'])
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 16)), elevation: 0, backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentIndex+1)/_questions.length, backgroundColor: Colors.grey[100], valueColor: const AlwaysStoppedAnimation(Colors.deepPurple)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
                    child: Column(
                      children: [
                         Text("Q${_currentIndex+1}", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 10),
                         Text(q['question'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ...List.generate(q['options'].length, (i) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: () => _onAnswer(i),
                          child: Text(q['options'][i], style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    )
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_isAdLoaded) SizedBox(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!))
        ],
      ),
    );
  }
}

// =======================
// 3. 결과 페이지 (예쁘게)
// =======================
class ResultPage extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  const ResultPage({super.key, required this.title, required this.content, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text("나의 결과는?", style: TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(
                    children: [
                      Chip(label: Text("Type $type", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.deepPurple),
                      const SizedBox(height: 20),
                      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text(content, style: const TextStyle(fontSize: 16, height: 1.6), textAlign: TextAlign.justify),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text("처음으로", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}