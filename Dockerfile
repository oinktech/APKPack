# 使用 Python 官方基礎映像
FROM python:3.9-slim

# 環境變數設定
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV GRADLE_VERSION=7.5.1
ENV ANDROID_CMDLINE_TOOLS_VERSION=latest

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-11-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Android SDK
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    cd ${ANDROID_SDK_ROOT} && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    unzip commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    rm commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip

# 設置 SDK 環境變數
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# 安裝 Android SDK 平台和構建工具
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "platforms;android-31" "build-tools;31.0.0"

# 安裝 Gradle
RUN wget https://downloads.gradle-dn.com/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip gradle-${GRADLE_VERSION}-bin.zip -d /opt/ && \
    rm gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle

# 設置工作目錄
WORKDIR /app

# 複製 requirements.txt 並安裝 Python 依賴
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 複製 Flask 應用程式
COPY . .

# 暴露應用的端口
EXPOSE 10000

# 啟動 Flask 應用
CMD ["python", "app.py"]
