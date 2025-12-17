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

def infer_category(keyword, ai_category):
    if ai_category in CATEGORIES: return ai_category
    keyword = keyword.replace(" ", "")
    if any(x in keyword for x in ["연애", "사랑", "이별", "고백", "이상형", "재회"]): return "연애"
    if any(x in keyword for x in ["성격", "MBTI", "심리", "멘탈"]): return "성격"
    if any(x in keyword for x in ["공포", "귀신", "좀비", "납치", "살인"]): return "공포"
    if any(x in keyword for x in ["돈", "부자", "로또", "재산", "소비"]): return "재물"
    if any(x in keyword for x in ["직장", "회사", "업무", "면접"]): return "직장"
    return "기타"

# ★★★ 핵심 추가: 데이터 품질 검사 함수 ★★★
def validate_and_fix_data(data):
    # 1. 필수 키 확인
    if not all(k in data for k in ["title", "desc", "questions", "results"]):
        return None
    
    # 2. 질문 개수 확인 (최소 1개)
    if not data['questions']: return None

    # 3. 결과 데이터 보정 (content가 없으면 desc를 복사 등)
    for res in data['results']:
        # type이 없으면 A, B, C, D로 강제 할당 시도 (여기선 단순화)
        if 'type' not in res: res['type'] = "Result"
        
        # content가 없고 desc나 description이 있으면 옮겨줌
        if 'content' not in res:
            if 'desc' in res: res['content'] = res['desc']
            elif 'description' in res: res['content'] = res['description']
            else: return None # 내용이 아예 없으면 불량품

        # title이 없으면 type이라도 넣음
        if 'title' not in res: res['title'] = res['type']

    return data

def generate_quiz(keyword):
    print(f"🧠 [{keyword}] 생성 중...", end=" ")
    date_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_key = f"test_{date_str}_{random.randint(10,99)}"
    
    # ★ 프롬프트 강화: 필드명을 정확하게 명시
    prompt = f"""
    주제: '{keyword}'
    심리테스트 5문제와 결과 4개(A,B,C,D)를 JSON으로 작성해.
    
    [필수 형식 준수]
    {{
        "title": "테스트 제목",
        "desc": "테스트 설명",
        "category": "연애, 성격, 공포, 재물, 직장, 기타 중 택1",
        "questions": [
            {{ "question": "질문 내용", "options": ["선택지1", "선택지2", "선택지3", "선택지4"] }}
        ],
        "results": [
            {{ "type": "A", "title": "결과 제목", "content": "상세한 결과 내용(3문장 이상)" }},
            {{ "type": "B", "title": "결과 제목", "content": "상세한 결과 내용" }}
        ]
    }}
    """
    
    for i in range(3): # 3번까지 재시도
        try:
            res = ollama.chat(model='gemma2', messages=[{'role': 'user', 'content': prompt}])
            raw_data = json.loads(clean_json_text(res['message']['content']))
            
            # ★ 품질 검사 실행
            valid_data = validate_and_fix_data(raw_data)
            
            if valid_data:
                # 카테고리 보정
                raw_cat = valid_data.get('category', '기타')
                final_cat = infer_category(keyword, raw_cat)
                valid_data['category'] = final_cat

                save_path = f"../master_quiz_app/assets/{file_key}.json"
                os.makedirs(os.path.dirname(save_path), exist_ok=True)
                save_json(save_path, valid_data)
                
                print(f"✅ 성공 ({final_cat})")
                return {
                    "key": file_key,
                    "title": valid_data['title'],
                    "desc": valid_data['desc'],
                    "category": final_cat, 
                    "date": datetime.now().strftime("%Y-%m-%d"),
                    "is_new": True
                }, keyword
            else:
                print(f"⚠️ 불량 데이터 발생 (재시도 {i+1}/3)")
        except: 
            print(f"⚠️ JSON 파싱 실패 (재시도 {i+1}/3)")
            pass
    
    print("❌ 최종 실패")
    return None, None

def run_factory():
    print("🏭 === [QC 강화된 공장] 가동 ===")
    
    current_menu = load_json(INDEX_FILE)
    history = load_json(HISTORY_FILE)
    
    for item in current_menu:
        if 'is_new' in item: del item['is_new']

    # ★ 초기화 하실 거면 여기 10으로, 아니면 2로 설정
    keywords = get_keywords(3) 
    new_items = []
    
    for kw in keywords:
        meta, word = generate_quiz(kw)
        if meta:
            new_items.append(meta)
            history.append(word)

    if len(history) > MAX_HISTORY:
        history = history[-MAX_HISTORY:]

    updated_menu = new_items + current_menu
    save_json(INDEX_FILE, updated_menu)
    save_json(HISTORY_FILE, history)
    
    print(f"\n✨ 업데이트 완료. 불량품은 자동 폐기되었습니다.")

if __name__ == "__main__":
    run_factory()
