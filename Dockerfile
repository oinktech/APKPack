# 使用官方的 Ubuntu 基礎映像
FROM ubuntu:20.04

# 設置環境變數
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV GRADLE_HOME=/opt/gradle
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${GRADLE_HOME}/bin

# 更新系統並安裝必要的工具
RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    openjdk-11-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 創建安裝目錄
RUN mkdir -p ${ANDROID_SDK_ROOT} ${GRADLE_HOME}

# 從 Dropbox 下載 Android Command Line Tools 和 Gradle
# 使用提供的下載鏈接
# 下載 Gradle
RUN wget -q -O /tmp/gradle.zip "https://www.dropbox.com/scl/fi/a8lgyc4qfx8sgrh96y140/gradle-7.6-bin.zip?rlkey=gzefvbqrz942qf3tf13w5gk3m&dl=1" && \
    unzip -q /tmp/gradle.zip -d /opt && \
    mv /opt/gradle-* ${GRADLE_HOME} && \
    rm /tmp/gradle.zip

# 下載 Android Command Line Tools
RUN wget -q -O /tmp/android-tools.zip "https://www.dropbox.com/scl/fi/2z4xgbiivh496tbmm7qxb/commandlinetools-linux-8092744_latest.zip?rlkey=i0k715n8f20fa3a5faq3z4l9v&dl=1" && \
    unzip -q /tmp/android-tools.zip -d ${ANDROID_SDK_ROOT} && \
    rm /tmp/android-tools.zip

# 移動工具目錄並設置權限
RUN mv ${ANDROID_SDK_ROOT}/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools-latest

# 確保所需的 SDK 組件已安裝
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools-latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools-latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# 設置工作目錄
WORKDIR /app

# 複製您的專案文件到容器中
COPY . .

# 安裝 Gradle 依賴
RUN gradle build

# 曝露端口（根據需要）
EXPOSE 10000

# 定義容器啟動時運行的命令
CMD ["gradle", "assembleDebug"]
