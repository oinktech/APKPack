# 使用官方的 Python 镜像作为基础镜像
FROM python:3.9-slim

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV GRADLE_HOME /opt/gradle
ENV PATH "${PATH}:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/platform-tools:${GRADLE_HOME}/bin"

# 安装必要的系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# 安装 Android SDK
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    cd ${ANDROID_SDK_ROOT} && \
    curl -o sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip && \
    unzip sdk.zip && \
    rm sdk.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-30" "build-tools;30.0.3" "emulator" && \
    rm -rf ${ANDROID_SDK_ROOT}/cmdline-tools

# 安装 Gradle
RUN curl -s "https://downloads.gradle-dn.com/distributions/gradle-7.5-bin.zip" -o gradle.zip && \
    unzip gradle.zip -d /opt && \
    rm gradle.zip && \
    mv /opt/gradle-7.5 /opt/gradle

# 创建应用目录
WORKDIR /app

# 复制 Python 依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 设置默认命令
CMD ["python", "app.py"]
