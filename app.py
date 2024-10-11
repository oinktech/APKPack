from flask import Flask, request, jsonify, send_file, render_template
import os
import subprocess
import shutil

app = Flask(__name__)

# 設置上傳和構建的資料夾
UPLOAD_FOLDER = '/tmp/uploads'
BUILD_FOLDER = '/tmp/build'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(BUILD_FOLDER, exist_ok=True)

# 設置文件大小限制（100MB）
MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100 MB
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# 檢查伺服器空間
def check_server_capacity():
    total, used, free = shutil.disk_usage("/")
    return free > 1024 * 1024 * 1024 * 3  # 3 GB 容量限制

# 檢查是否允許上傳的文件類型
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() == 'zip'

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    print("開始處理文件上傳...")
    
    if not check_server_capacity():
        print("伺服器空間不足")
        return jsonify({'error': '伺服器空間不足，請稍後再試'}), 507

    if 'file' not in request.files:
        print("沒有選擇文件")
        return jsonify({'error': '沒有選擇文件'}), 400

    file = request.files['file']
    app_name = request.form.get('app_name', 'MyApp').strip()  # 默認名稱為 MyApp

    if file.filename == '':
        print("文件名稱為空")
        return jsonify({'error': '文件名稱為空'}), 400

    if not allowed_file(file.filename):
        print("不允許的文件類型")
        return jsonify({'error': '不允許的文件類型，只允許 ZIP 檔案'}), 400

    filename = secure_filename(file.filename)
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    try:
        print(f"儲存文件到 {file_path}")
        file.save(file_path)
    except Exception as e:
        print(f"文件上傳失敗: {str(e)}")
        return jsonify({'error': f'文件上傳失敗: {str(e)}'}), 500

    # 解壓文件
    try:
        print(f"解壓文件到 {BUILD_FOLDER}")
        shutil.unpack_archive(file_path, BUILD_FOLDER)
    except Exception as e:
        print(f"解壓縮失敗: {str(e)}")
        return jsonify({'error': f'解壓縮失敗: {str(e)}'}), 500

    # 在 BUILD_FOLDER 中初始化 Cordova 项目
    try:
        print("初始化 Cordova 項目...")
        subprocess.run(['cordova', 'create', BUILD_FOLDER, app_name, app_name], check=True)
        
        # 將網站文件複製到 Cordova 的 www 資料夾
        shutil.copytree(BUILD_FOLDER, os.path.join(BUILD_FOLDER, 'www'), dirs_exist_ok=True)

        # 添加 Android 平台
        print("添加 Android 平台...")
        subprocess.run(['cordova', 'platform', 'add', 'android'], cwd=BUILD_FOLDER, check=True)

        # 構建 APK 文件
        print("構建 APK...")
        subprocess.run(['cordova', 'build', 'android'], cwd=BUILD_FOLDER, check=True)

        apk_path = os.path.join(BUILD_FOLDER, 'platforms', 'android', 'app', 'build', 'outputs', 'apk', 'debug', f'{app_name}-debug.apk')

        if not os.path.exists(apk_path):
            print("打包失敗，無法生成 APK 文件")
            return jsonify({'error': '打包失敗，無法生成 APK 文件'}), 500

        print(f"打包成功，APK 路徑為: {apk_path}")
        return send_file(apk_path, as_attachment=True)
    except subprocess.CalledProcessError as e:
        print(f"APK 打包失敗: {e.stderr}")
        return jsonify({'error': f'APK 打包失敗: {e.stderr}'}), 500
    except Exception as e:
        print(f"執行打包失敗: {str(e)}")
        return jsonify({'error': f'執行打包失敗: {str(e)}'}), 500
    finally:
        # 清理上傳的文件和構建文件
        print("清理上傳和構建文件...")
        if os.path.exists(file_path):
            os.remove(file_path)
        shutil.rmtree(BUILD_FOLDER, ignore_errors=True)

if __name__ == '__main__':
    print("伺服器啟動中...")
    app.run(host='0.0.0.0', port=10000, debug=True)
