# 使用 Ubuntu 作为基础映像
FROM ubuntu:20.04

# 设置时区和非交互模式以避免交互提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 更新包列表并安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    tzdata \
    wget \
    unzip \
    ant \
    curl \
    python3 \
    python3-pip \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# 安装 OpenJDK 17
RUN apt-add-repository ppa:openjdk-r/ppa -y && \
    apt-get update && \
    apt-get install -y openjdk-17-jdk

# 安装 Node.js（使用 NodeSource）
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 安装 Cordova
RUN npm install -g cordova

# 安装 Gradle
RUN wget https://services.gradle.org/distributions/gradle-7.4.2-bin.zip -P /tmp \
    && unzip -d /opt/gradle /tmp/gradle-7.4.2-bin.zip \
    && rm /tmp/gradle-7.4.2-bin.zip

# 设置 Gradle 环境变量
ENV GRADLE_HOME=/opt/gradle/gradle-7.4.2
ENV PATH=${PATH}:${GRADLE_HOME}/bin

# 设置 Android SDK 相关环境变量
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# 下载 Android SDK 命令行工具并解压到正确的路径
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/android-tools.zip && \
    mkdir -p $ANDROID_HOME/cmdline-tools && \
    unzip /tmp/android-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    rm /tmp/android-tools.zip && \
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# 同意 SDK 管理器的许可证
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses

# 安装需要的 SDK 组件，包括推荐版本的构建工具
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 安装 Flask 和其他 Python 依赖
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# 设置工作目录
WORKDIR /app

# 复制项目文件到容器中
COPY . .

# 确认文件是否正确复制
RUN ls -la /app

# 设置 FLASK_APP 和 FLASK_ENV 环境变量
ENV FLASK_APP=app.py
ENV FLASK_ENV=development

# 暴露端口 10000
EXPOSE 10000

# 创建 uploads 目录
RUN mkdir uploads

# 执行 Flask 应用
CMD ["python3", "app.py"]
