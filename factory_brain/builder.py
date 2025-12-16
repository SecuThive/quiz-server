import os
import subprocess
import time
import re

# ==========================================
# 🏭 앱 공장 설정 (여기만 바꾸면 앱이 바뀜)
# ==========================================
APP_TOPIC = "공포 심리 테스트"  # 주제
APP_NAME = "소름돋는 심리테스트"  # 폰에 설치될 이름
APP_ID_SUFFIX = "horror_test"  # 패키지명 뒤에 붙을 ID (영어, 소문자, 언더바만)
# ==========================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__)) # factory_brain 위치
PROJECT_DIR = os.path.join(BASE_DIR, "../master_quiz_app")
OUTPUT_DIR = os.path.join(BASE_DIR, "../output_apks")

def run_command(command, cwd=None):
    try:
        subprocess.run(command, check=True, shell=True, cwd=cwd)
    except subprocess.CalledProcessError as e:
        print(f"❌ 에러 발생: {e}")
        exit(1)

def step1_generate_content():
    print(f"\n🧠 1. 콘텐츠 생성 중... 주제: {APP_TOPIC}")
    
    gen_path = os.path.join(BASE_DIR, "generator.py")
    with open(gen_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # TOPIC 변수 바꿔치기
    new_content = re.sub(r'TOPIC = ".*?"', f'TOPIC = "{APP_TOPIC}"', content)
    
    with open(gen_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    run_command("python3 generator.py", cwd=BASE_DIR)

def step2_update_config():
    print(f"\n⚙️ 2. 앱 설정 변경 중... 이름: {APP_NAME}")
    
    # 2-1. 앱 이름 변경 (AndroidManifest.xml label)
    manifest_path = os.path.join(PROJECT_DIR, "android/app/src/main/AndroidManifest.xml")
    with open(manifest_path, 'r', encoding='utf-8') as f:
        xml = f.read()
    
    # android:label="어쩌구" 를 찾아서 바꿈
    new_xml = re.sub(r'android:label=".*?"', f'android:label="{APP_NAME}"', xml)
    
    with open(manifest_path, 'w', encoding='utf-8') as f:
        f.write(new_xml)

    # 2-2. 패키지 ID 변경 (build.gradle.kts) - ★여기가 수정됨★
    gradle_path = os.path.join(PROJECT_DIR, "android/app/build.gradle.kts")
    
    with open(gradle_path, 'r', encoding='utf-8') as f:
        gradle = f.read()
        
    # .kts 파일은 문법이 다릅니다 (applicationId = "..." 형태)
    # 기존: applicationId = "com.thive.master_quiz_app"
    # 변경: applicationId = "com.thive.horror_test"
    new_gradle = re.sub(r'applicationId\s*=\s*".*?"', f'applicationId = "com.thive.{APP_ID_SUFFIX}"', gradle)
    
    with open(gradle_path, 'w', encoding='utf-8') as f:
        f.write(new_gradle)

def step3_build_app():
    print(f"\n🔨 3. 앱 빌드 시작! (약 1~3분 소요)")
    # 플러터 빌드 명령어 (apk 생성)
    run_command("flutter build apk --release", cwd=PROJECT_DIR)

def step4_save_output():
    print(f"\n📦 4. 결과물 저장")
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    source = os.path.join(PROJECT_DIR, "build/app/outputs/flutter-apk/app-release.apk")
    dest_name = f"{APP_NAME.replace(' ', '_')}_v1.apk"
    dest = os.path.join(OUTPUT_DIR, dest_name)
    
    # 기존 파일이 있으면 덮어쓰기 위해 mv 대신 cp 사용하거나 체크
    if os.path.exists(dest):
        os.remove(dest)
        
    run_command(f"cp '{source}' '{dest}'")
    print(f"✨ 완성! 파일 위치: {dest}")
    # 맥 Finder에서 해당 폴더 열기
    run_command(f"open '{OUTPUT_DIR}'")

if __name__ == "__main__":
    print("🏭 === [앱 자동화 공장] 가동 ===")
    step1_generate_content()
    step2_update_config()
    step3_build_app()
    step4_save_output()