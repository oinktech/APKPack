from flask import Flask, request, jsonify, send_file, render_template
import os
import subprocess
import zipfile
from werkzeug.utils import secure_filename
import shutil

app = Flask(__name__)

# 設置上傳和構建的資料夾
UPLOAD_FOLDER = '/tmp/uploads'
BUILD_FOLDER = '/tmp/build'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(BUILD_FOLDER, exist_ok=True)

# 設置文件大小限制（10MB）
MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10 MB
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# 檢查伺服器空間
def check_server_capacity():
    total, used, free = shutil.disk_usage("/")
    return free > 100 * 1024 * 1024  # 100 MB 容量限制

# 檢查是否允許上傳的文件類型
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() == 'zip'

# 檢查是否已安裝 Cordova
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
    except subprocess.CalledProcessError:
        return False

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if not check_server_capacity():
        return jsonify({'error': '伺服器空間不足，請稍後再試'}), 507

    if 'file' not in request.files:
        return jsonify({'error': '沒有選擇文件'}), 400

    file = request.files['file']
    apk_name = request.form.get('apk_name', 'MyApp').strip()  # 從表單獲取應用名稱，默認為 'MyApp'

    if file.filename == '':
        return jsonify({'error': '文件名稱為空'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': '不允許的文件類型，只允許 ZIP 檔案'}), 400

    filename = secure_filename(file.filename)
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    try:
        file.save(file_path)
    except Exception as e:
        return jsonify({'error': f'文件上傳失敗: {str(e)}'}), 500  # 更详细的错误信息

    # 解壓文件
    try:
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            zip_ref.extractall(BUILD_FOLDER)
    except zipfile.BadZipFile:
        return jsonify({'error': '無法解壓縮該文件，請確認文件是否正確'}), 400
    except Exception as e:
        return jsonify({'error': f'解壓縮失敗: {str(e)}'}), 500  # 捕获其他解压缩异常

    # 檢查和安裝 Cordova
    if not check_cordova_installed():
        if not install_cordova():
            return jsonify({'error': '未能安裝 Cordova，請手動安裝並重試'}), 500

    # 構建 Cordova 項目
    try:
        subprocess.run(['cordova', 'create', secure_filename(apk_name), 'com.example.myapp', apk_name], check=True, cwd=BUILD_FOLDER)
        os.chdir(os.path.join(BUILD_FOLDER, secure_filename(apk_name)))

        # 添加 Android 平台
        subprocess.run(['cordova', 'platform', 'add', 'android'], check=True)

        # 複製上傳的文件到 www 目錄
        shutil.copytree(BUILD_FOLDER, os.path.join(BUILD_FOLDER, secure_filename(apk_name), 'www'), dirs_exist_ok=True)

        # 構建 APK
        subprocess.run(['cordova', 'build', 'android'], check=True)

        apk_path = os.path.join(BUILD_FOLDER, secure_filename(apk_name), 'platforms', 'android', 'app', 'build', 'outputs', 'apk', 'debug', 'app-debug.apk')

        return send_file(apk_path, as_attachment=True, download_name=f'{secure_filename(apk_name)}.apk')
    except subprocess.CalledProcessError as e:
        return jsonify({'error': f'打包失敗: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'error': f'發生錯誤: {str(e)}'}), 500  # 捕获其他错误
    finally:
        # 清理上傳的文件和構建文件
        if os.path.exists(file_path):
            os.remove(file_path)
        shutil.rmtree(BUILD_FOLDER, ignore_errors=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000, debug=True)
