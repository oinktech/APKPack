# 使用 Ubuntu 作為基礎映像
FROM ubuntu:20.04

# 環境設置
ENV DEBIAN_FRONTEND=noninteractive

# 安裝必要工具及依賴
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl wget unzip git openjdk-11-jdk python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 設置 Android SDK 環境變量
RUN mkdir -p /opt/android-sdk && \
    curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip && \
    unzip sdk-tools.zip -d /opt/android-sdk && \
    rm sdk-tools.zip && \
    # 確保 cmdline-tools 的目錄結構正確
    mv /opt/android-sdk/cmdline-tools /opt/android-sdk/cmdline-tools/latest

ENV ANDROID_HOME /opt/android-sdk
ENV PATH $ANDROID_HOME/cmdline-tools/latest/bin:$PATH

# 安裝 Gradle
RUN GRADLE_VERSION=7.6 && \
    wget -q "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" -O gradle.zip && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip && \
    mv /opt/gradle-$GRADLE_VERSION /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle

ENV PATH /opt/gradle/bin:$PATH

# 安裝 Android SDK 所需包
RUN yes | sdkmanager --licenses && \
    sdkmanager "platforms;android-30" "build-tools;30.0.3" "platform-tools"

# 複製你的 Flask 應用文件
WORKDIR /app
COPY . /app

# 安裝 Python 依賴
RUN pip3 install --no-cache-dir -r requirements.txt

# 啟動 Flask 應用
CMD ["python3", "app.py"]
