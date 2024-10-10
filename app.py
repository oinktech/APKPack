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

# 設置文件大小限制（100MB）
MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100 MB
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# 檢查伺服器空間
def check_server_capacity():
    total, used, free = shutil.disk_usage("/")
    return free > 1024 * 1024 * 1024 * 3 # 3 GB 容量限制

# 檢查是否允許上傳的文件類型
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() == 'zip'

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
    apk_name = request.form.get('apk_name', 'app-debug').strip()  # 默認名稱為 app-debug

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

    # 生成 build.xml
    build_xml_content = f"""<project name="APKPack" default="debug" basedir=".">
    <property name="src.dir" value="."/>
    <property name="bin.dir" value="bin"/>
    <property name="libs.dir" value="libs"/>

    <target name="clean">
        <delete dir="${{bin.dir}}"/>
    </target>

    <target name="compile">
        <mkdir dir="${{bin.dir}}"/>
        <copy todir="${{bin.dir}}">
            <fileset dir="${{src.dir}}"/>
        </copy>
    </target>

    <target name="debug" depends="clean, compile">
        <echo message="Building APK..."/>
        <exec executable="java" failonerror="true">
            <arg value="-jar"/>
            <arg value="apkbuilder.jar"/>
            <arg value="{secure_filename(apk_name)}.apk"/>
            <arg value="-f"/>
            <arg value="${{bin.dir}}"/>
            <arg value="-z"/>
            <arg value="${{libs.dir}}/{filename}"/> <!-- 使用上传的 ZIP 文件名 -->
        </exec>
    </target>
</project>
"""
    
    build_xml_path = os.path.join(BUILD_FOLDER, 'build.xml')
    with open(build_xml_path, 'w') as build_file:
        build_file.write(build_xml_content)

    # 执行 Ant 打包
    try:
        result = subprocess.run(['ant', 'debug'], cwd=BUILD_FOLDER, check=True, capture_output=True, text=True)
        print(result.stdout)  # 打印标准输出
        print(result.stderr)   # 打印标准错误

        apk_path = os.path.join(BUILD_FOLDER, 'bin', f'{secure_filename(apk_name)}.apk')

        if not os.path.exists(apk_path):
            return jsonify({'error': '打包失敗，無法生成 APK 文件'}), 500

        # 使用用户指定的 APK 名称
        custom_apk_name = f"{secure_filename(apk_name)}.apk"
        custom_apk_path = os.path.join(BUILD_FOLDER, custom_apk_name)
        os.rename(apk_path, custom_apk_path)

        return send_file(custom_apk_path, as_attachment=True, download_name=custom_apk_name)
    except subprocess.CalledProcessError as e:
        return jsonify({'error': f'APK 打包失敗: {e.stderr}'}), 500
    except Exception as e:
        return jsonify({'error': f'執行 Ant 打包失敗: {str(e)}'}), 500  # 捕获其他错误
    finally:
        # 清理上傳的文件和構建文件
        if os.path.exists(file_path):
            os.remove(file_path)
        shutil.rmtree(BUILD_FOLDER, ignore_errors=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000, debug=True)
