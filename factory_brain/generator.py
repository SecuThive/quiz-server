import ollama
import json
import os
import requests
import feedparser
import random
from datetime import datetime

# ==========================================
# ⚙️ 설정
# ==========================================
RSS_URL = "https://trends.google.com/trends/trendingsearches/daily/rss?geo=KR"
HISTORY_FILE = "../master_quiz_app/assets/history.json"
INDEX_FILE = "../master_quiz_app/assets/index.json"
MAX_HISTORY = 50

# 카테고리 정의
CATEGORIES = ["연애", "성격", "공포", "재물", "직장", "기타"]

# 100개의 마르지 않는 샘물 (기존과 동일, 생략)
BACKUP_TOPICS = [
    "짝사랑 성공 확률", "나의 연애 세포 등급", "헤어진 연인 재회 가능성", "운명의 상대 얼굴", "나쁜 남자/여자 구별법",
    "결혼 적령기 테스트", "내가 바람을 피운다면?", "질투심 레벨 테스트", "스킨십 선호도", "소개팅 필승 의상",
    "이상형 월드컵", "권태기 극복 스타일", "고백 성공률", "첫눈에 반할 확률", "연상 vs 연하",
    "MBTI 팩트 폭격", "숨겨진 사이코패스 본능", "나의 꼰대 지수", "유리멘탈 vs 강철멘탈", "결정장애 레벨",
    "리더십 유형 분석", "관종력 테스트", "게으름뱅이 지수", "분노 조절 능력", "나의 거짓말 탐지기",
    "자존감 측정기", "완벽주의 성향", "눈치 백단 테스트", "사교성 레벨", "고집불통 지수",
    "좀비 아포칼립스 생존일수", "무인도 생존 확률", "공포영화 속 나의 역할", "귀신을 본다면?", "살인마와 마주쳤을 때",
    "데스게임 우승 확률", "지구 멸망 1시간 전", "납치되었을 때 반응", "심령 스팟 체험", "전생의 나의 죽음",
    "미래의 내 연봉 예측", "로또 1등 당첨 후 행동", "나의 소비 요정 등급", "사업가 기질 테스트", "벼락부자 가능성",
    "평생 모을 재산", "주식 투자 성향", "짠돌이/짠순이 지수", "쇼핑 중독 테스트", "가난을 부르는 습관",
    "직장 내 빌런 유형", "퇴사 욕구 레벨", "나에게 맞는 직업", "조별과제 역할 분석", "면접 프리패스 관상",
    "사회생활 만렙 테스트", "워커홀릭 지수", "상사에게 사랑받는 법", "야근 때 나의 모습", "회식 자리 유형",
    "초능력이 생긴다면?", "호그와트 기숙사 배정", "동물로 태어난다면?", "타임머신 여행지", "투명인간이 된다면",
    "마법사가 된다면", "용사가 되어 마왕 잡기", "외계인과의 교신", "이세계 전생 트럭", "램프의 요정 소원",
    "탕수육 부먹 vs 찍먹", "민트초코 호불호", "깻잎 논쟁 판결", "야식 메뉴 추천", "여행 스타일 분석",
    "노래방 애창곡 스타일", "패션 테러리스트 지수", "다이어트 실패 원인", "집순이/집돌이 레벨", "스마트폰 중독",
    "나의 흑역사 생성기", "친구가 애인 뺏어감", "길에서 똥 밟았을 때", "화장실 휴지 없을 때", "엘리베이터 방귀",
    "지하철 쩍벌남 퇴치", "미용실 머리 망함", "택배 분실 사건", "와이파이 끊김", "배터리 1%"
]

def load_json(path, default=[]):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return default

def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def is_duplicate(keyword, history):
    for h in history:
        if keyword == h or (len(keyword) > 2 and keyword in h):
            return True
    return False

def get_keywords(count=2):
    print("📡 주제 선정 중...")
    history = load_json(HISTORY_FILE)
    candidates = []

    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        res = requests.get(RSS_URL, headers=headers, timeout=5)
        if res.status_code == 200:
            feed = feedparser.parse(res.content)
            for entry in feed.entries:
                if not is_duplicate(entry.title, history):
                    candidates.append(entry.title)
    except: pass

    random.shuffle(BACKUP_TOPICS)
    for topic in BACKUP_TOPICS:
        if len(candidates) >= count: break
        if not is_duplicate(topic, history) and topic not in candidates:
            candidates.append(topic)
            
    return candidates[:count]

def clean_json_text(text):
    try:
        if "```" in text: text = text.split("```json")[-1].split("```")[0].strip()
        start, end = text.find('{'), text.rfind('}') + 1
        if start != -1 and end != 0: return text[start:end]
    except: pass
    return text

def generate_quiz(keyword):
    print(f"🧠 [{keyword}] 생성 중...", end=" ")
    date_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_key = f"test_{date_str}_{random.randint(10,99)}"
    
    # ★ 프롬프트 수정: 카테고리(category) 추가 요청
    prompt = f"""
    주제: '{keyword}'
    심리테스트 5문제와 결과 4개(A,B,C,D)를 JSON으로 작성해.
    
    [추가 규칙]
    "category" 필드에 [연애, 성격, 공포, 재물, 직장, 기타] 중 가장 어울리는 하나를 골라 적어줘.
    
    {{
        "title": "{keyword} 테스트",
        "desc": "설명",
        "category": "연애",
        "questions": [ ...생략... ],
        "results": [ ...생략... ]
    }}
    """
    
    for _ in range(3):
        try:
            res = ollama.chat(model='gemma2', messages=[{'role': 'user', 'content': prompt}])
            data = json.loads(clean_json_text(res['message']['content']))
            
            save_path = f"../master_quiz_app/assets/{file_key}.json"
            os.makedirs(os.path.dirname(save_path), exist_ok=True)
            save_json(save_path, data)
            
            print("✅ 성공")
            return {
                "key": file_key,
                "title": data['title'],
                "desc": data['desc'],
                "category": data.get('category', '기타'), # 카테고리 저장
                "date": datetime.now().strftime("%Y-%m-%d"), # 생성 날짜 저장
            }, keyword
        except: pass
    
    print("❌ 실패")
    return None, None

def run_factory():
    print("🏭 === [카테고리형 공장] 가동 ===")
    
    current_menu = load_json(INDEX_FILE)
    history = load_json(HISTORY_FILE)
    
    keywords = get_keywords(2)
    new_items = []
    
    for kw in keywords:
        meta, word = generate_quiz(kw)
        if meta:
            new_items.append(meta)
            history.append(word)

    if len(history) > MAX_HISTORY:
        history = history[-MAX_HISTORY:]

    # 최신순 정렬
    updated_menu = new_items + current_menu
    save_json(INDEX_FILE, updated_menu)
    save_json(HISTORY_FILE, history)
    
    print(f"\n✨ 업데이트 완료.")

if __name__ == "__main__":
    run_factory()