from flask import Flask, request, jsonify, send_file, render_template
import os
import subprocess
import shutil
from werkzeug.utils import secure_filename

app = Flask(__name__)

# 設置上傳和構建的資料夾
UPLOAD_FOLDER = '/tmp/uploads'
BUILD_FOLDER = '/tmp/build'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(BUILD_FOLDER, exist_ok=True)

# 設置文件大小限制（10MB）
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10 MB
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# 檢查 Cordova 是否已安裝
def check_cordova_installed():
    try:
        subprocess.run(['cordova', '-v'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError:
        return False

# 安裝 Cordova
def install_cordova():
    try:
        subprocess.run(['npm', 'install', '-g', 'cordova'], check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f'安裝 Cordova 失敗: {str(e)}')
        return False

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': '沒有選擇文件'}), 400

    file = request.files['file']
    apk_name = request.form.get('apk_name', 'MyApp').strip()  # 從表單獲取應用名稱，默認為 'MyApp'

    if file.filename == '':
        return jsonify({'error': '文件名稱為空'}), 400

    filename = secure_filename(file.filename)
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    try:
        file.save(file_path)
    except Exception as e:
        return jsonify({'error': f'文件上傳失敗: {str(e)}'}), 500

    # 檢查和安裝 Cordova
    if not check_cordova_installed():
        if not install_cordova():
            return jsonify({'error': '未能安裝 Cordova，請手動安裝並重試'}), 500

    # 構建 Cordova 項目
    try:
        # 創建 Cordova 項目，使用安全文件名稱
        subprocess.run(['cordova', 'create', secure_filename(apk_name), 'com.example.myapp', apk_name], check=True, cwd=BUILD_FOLDER)
        os.chdir(os.path.join(BUILD_FOLDER, secure_filename(apk_name)))

        # 添加 Android 平台
        subprocess.run(['cordova', 'platform', 'add', 'android'], check=True)

        # 複製上傳的文件到 www 目錄
        shutil.copytree(UPLOAD_FOLDER, os.path.join(BUILD_FOLDER, secure_filename(apk_name), 'www'), dirs_exist_ok=True)

        # 構建 APK
        subprocess.run(['cordova', 'build', 'android'], check=True)

        apk_path = os.path.join(BUILD_FOLDER, secure_filename(apk_name), 'platforms', 'android', 'app', 'build', 'outputs', 'apk', 'debug', 'app-debug.apk')

        return send_file(apk_path, as_attachment=True, download_name=f'{secure_filename(apk_name)}.apk')
    except subprocess.CalledProcessError as e:
        return jsonify({'error': f'打包失敗: {str(e)}'}), 500
    finally:
        # 清理上傳的文件和構建文件
        shutil.rmtree(UPLOAD_FOLDER, ignore_errors=True)
        shutil.rmtree(BUILD_FOLDER, ignore_errors=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000, debug=True)
