# 使用 Ubuntu 作为基础映像
FROM ubuntu:20.04

# 环境设置
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要工具及依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl unzip git openjdk-11-jdk python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置 Android SDK 环境变量
ENV ANDROID_HOME /opt/android-sdk
ENV PATH $ANDROID_HOME/cmdline-tools/latest/bin:$PATH

# 下载 Android SDK 工具
RUN mkdir -p /opt/android-sdk && \
    echo "Downloading Android SDK command line tools..." && \
    curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip && \
    echo "Unzipping Android SDK command line tools..." && \
    unzip sdk-tools.zip -d /opt/android-sdk && \
    rm sdk-tools.zip && \
    echo "Renaming cmdline-tools directory..." && \
    mv /opt/android-sdk/cmdline-tools /opt/android-sdk/cmdline-tools/latest

# 安装 Gradle
RUN GRADLE_VERSION=7.6 && \
    echo "Downloading Gradle..." && \
    curl -o gradle.zip "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" && \
    echo "Unzipping Gradle..." && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip && \
    mv /opt/gradle-$GRADLE_VERSION /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle

ENV PATH /opt/gradle/bin:$PATH

# 安装 Android SDK 所需包
RUN yes | sdkmanager --licenses && \
    sdkmanager "platforms;android-30" "build-tools;30.0.3" "platform-tools"

# 复制你的 Flask 应用文件
WORKDIR /app
COPY . /app

# 安装 Python 依赖
RUN pip3 install --no-cache-dir -r requirements.txt

# 启动 Flask 应用
CMD ["python3", "app.py"]
