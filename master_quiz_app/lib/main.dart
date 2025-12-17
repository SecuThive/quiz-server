import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
// 날짜 비교를 위해 intl 패키지 사용 권장하지만, 간단히 String 비교로 처리함

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      textTheme: GoogleFonts.gowunDodumTextTheme(),
      scaffoldBackgroundColor: Colors.grey[100],
      primarySwatch: Colors.deepPurple,
    ),
    home: const SplashScreen(),
  ));
}

// 0. 스플래시 (기존 동일)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)])),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.psychology, size: 80, color: Colors.white), SizedBox(height: 20), Text("AI 심리연구소", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))])),
      ),
    );
  }
}

// =======================
// 1. 메인 홈 (구조 변경)
// =======================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<dynamic> _allTests = [];
  List<dynamic> _todayTests = [];
  bool _isLoading = true;
  late TabController _tabController;

  final String serverUrl = "https://raw.githubusercontent.com/SecuThive/quiz-server/main/master_quiz_app/assets/";
  final List<String> categories = ["전체", "연애", "성격", "공포", "재물", "직장", "기타"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    loadMenu();
  }

  Future<void> loadMenu() async {
    try {
      String jsonStr;
      if (serverUrl.isNotEmpty) {
        final res = await http.get(Uri.parse(serverUrl + "index.json"));
        if (res.statusCode == 200) jsonStr = utf8.decode(res.bodyBytes);
        else throw Exception("Server Error");
      } else {
        throw Exception("No URL");
      }
      final List<dynamic> data = json.decode(jsonStr);
      _processData(data);
    } catch (e) {
      try {
        final localStr = await rootBundle.loadString('assets/index.json');
        _processData(json.decode(localStr));
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ★★★ 여기가 수정되었습니다! (불량품 거르기) ★★★
  void _processData(List<dynamic> data) {
    String today = DateTime.now().toString().substring(0, 10);
    
    List<dynamic> cleanData = []; // 불량품을 걸러낸 깨끗한 전체 리스트
    List<dynamic> todayList = [];

    for (var item in data) {
      // 1. 데이터가 Map(사전) 형태가 아니면 무조건 버림 (에러 원인 차단)
      if (item is! Map) continue;
      
      // 2. 제목이 없는 경우도 버림
      if (item['title'] == null) continue;

      // 여기까지 통과하면 정상 데이터!
      cleanData.add(item);

      String itemDate = item['date'] ?? "2000-01-01";
      if (itemDate == today) todayList.add(item);
    }

    if (mounted) {
      setState(() {
        _allTests = cleanData; // ★ 원본(data) 대신 깨끗한 리스트(cleanData)를 넣음
        _todayTests = todayList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    String today = DateTime.now().toString().substring(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 심리연구소", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text("🔥 따끈따끈 신상", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text("TODAY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (_todayTests.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: const Center(child: Text("오늘의 신상 테스트가 준비 중입니다.", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _todayTests.length,
                          itemBuilder: (context, index) {
                            final item = _todayTests[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PsychTestPage(fileKey: item['key'], title: item['title'] ?? "제목 없음", serverUrl: serverUrl))),
                              child: Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 15),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                      child: const Text("NEW ✨", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(item['title'] ?? "제목 없음", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  indicatorColor: Colors.deepPurple,
                  tabs: categories.map((e) => Tab(text: e)).toList(),
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: categories.map((cat) {
            final list = cat == "전체" 
                ? _allTests 
                : _allTests.where((e) => (e['category'] ?? "기타") == cat).toList();

            if (list.isEmpty) return Center(child: Text("아직 '$cat' 테스트가 없어요!"));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                String title = item['title'] ?? "무제";
                String firstChar = title.isNotEmpty ? title.substring(0, 1) : "?";
                bool isNew = (item['date'] ?? "") == today;

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PsychTestPage(fileKey: item['key'], title: title, serverUrl: serverUrl))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Text(firstChar, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  if (isNew) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                                      child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ]
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['desc'] ?? "...", style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// 탭바 고정을 위한 델리게이트 클래스
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.grey[100], child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// =======================
// 2. 퀴즈 페이지 (기존 코드 그대로 사용)
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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', 
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (ad) => setState(() => _isAdLoaded = true), onAdFailedToLoad: (ad, err) => ad.dispose()),
    )..load();
  }

  Future<void> loadQuizData() async {
    try {
      String jsonStr;
      String url = "${widget.serverUrl}${widget.fileKey}.json";
      if (widget.serverUrl.isNotEmpty) {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) jsonStr = utf8.decode(res.bodyBytes);
        else throw Exception("Server Error");
      } else {
        jsonStr = await rootBundle.loadString('assets/${widget.fileKey}.json');
      }
      final data = json.decode(jsonStr);
      setState(() { _fullData = data; _questions = data['questions'] ?? []; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _questions = []; });
    }
  }

  void _onAnswer(int index) {
    setState(() => _userAnswers.add(index));
    if (_currentIndex < _questions.length - 1) setState(() => _currentIndex++);
    else _showResult();
  }

void _showResult() {
    // 1. 데이터가 아예 없는 경우 방어
    if (_fullData == null || _fullData!['results'] == null) return;
    
    final results = _fullData!['results'];
    if (results.isEmpty) return;

    // 2. 점수 계산 (기존과 동일)
    Map<int, int> counts = {};
    for (var a in _userAnswers) { counts[a] = (counts[a] ?? 0) + 1; }
    int maxIdx = 0, maxVal = 0;
    counts.forEach((k, v) { if (v > maxVal) { maxVal = v; maxIdx = k; } });

    // 3. 결과 선택
    final result = (maxIdx < results.length) ? results[maxIdx] : results[0];
    
    print("🎯 결과 데이터 확인: $result"); // 디버깅용 로그

    // 4. ★★★ 핵심 수정: 데이터가 Null이면 기본값("...")을 넣어줌 (?? 연산자)
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ResultPage(
        // title이 없으면 "결과"라고 띄움
        title: result['title']?.toString() ?? "결과", 
        
        // content가 없으면 desc를 찾고, 그것도 없으면 "내용 없음" 출력
        content: result['content']?.toString() ?? result['desc']?.toString() ?? "결과 내용이 없습니다.", 
        
        // type이 없으면 "Result"라고 띄움
        type: result['type']?.toString() ?? "Result"
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return Scaffold(appBar: AppBar(title: const Text("오류"), iconTheme: const IconThemeData(color: Colors.black), backgroundColor: Colors.white), body: const Center(child: Text("문제를 불러올 수 없습니다.")));

    final q = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 16)), elevation: 0, backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      body: Column(children: [
        LinearProgressIndicator(value: (_currentIndex+1)/_questions.length, backgroundColor: Colors.grey[100], valueColor: const AlwaysStoppedAnimation(Colors.deepPurple)),
        Expanded(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          const Spacer(),
          Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [Text("Q${_currentIndex+1}", style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(q['question'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
          const Spacer(),
          ...List.generate(q['options'].length, (i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () => _onAnswer(i), child: Text(q['options'][i], style: const TextStyle(fontSize: 16)))))),
          const Spacer(),
        ]))),
        if (_isAdLoaded) SizedBox(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!))
      ]),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String title;
  final String content;
  final String type;
  const ResultPage({super.key, required this.title, required this.content, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold 배경을 투명하게 하거나 아예 없앰
      body: Container(
        width: double.infinity,
        height: double.infinity, // ★ 화면 전체 채우기 필수
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)], 
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter
          )
        ),
        child: SafeArea( // ★ 배경 위에 SafeArea를 얹음
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      const Text("나의 결과는?", style: TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 20),
                      
                      // 결과 카드
                      Container(
                        width: double.infinity, // 가로 꽉 채우기
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95), 
                          borderRadius: BorderRadius.circular(30), 
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))]
                        ),
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
                    ],
                  ),
                ),
              ),
              
              // 하단 버튼 (화면 아래 고정)
              Padding(
                padding: const EdgeInsets.all(30),
                child: SizedBox(
                  width: double.infinity, 
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      foregroundColor: Colors.deepPurple, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text("처음으로", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}