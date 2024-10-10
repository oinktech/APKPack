# 使用官方的 OpenJDK 11 作為基礎映像
FROM openjdk:11-jdk

# 設定環境變數
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV GRADLE_VERSION=7.4.2
ENV ANDROID_VERSION=29
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/${ANDROID_VERSION}:${ANDROID_SDK_ROOT}/emulator:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin

# 更新和安裝必要的包
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Android SDK
RUN mkdir -p ${ANDROID_SDK_ROOT} && cd ${ANDROID_SDK_ROOT} \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    && unzip commandlinetools-linux-7583922_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && rm commandlinetools-linux-7583922_latest.zip \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest

# 設置 Android SDK 的接受條款
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses

# 安裝所需的 SDK 和平台工具
RUN sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
    "platforms;android-${ANDROID_VERSION}" \
    "build-tools;${ANDROID_VERSION}" \
    "extras;google;m2repository" \
    "extras;android;m2repository" \
    "platform-tools" \
    "emulator"

# 下載和安裝 Gradle
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && unzip gradle-${GRADLE_VERSION}-bin.zip -d /opt/ \
    && rm gradle-${GRADLE_VERSION}-bin.zip \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/bin/gradle

# 創建工作目錄
WORKDIR /app

# 複製應用程序源代碼到容器中
COPY . .

# 進行 Gradle 構建
RUN gradle build

# 設定容器啟動命令
CMD ["gradle", "assembleDebug"]
