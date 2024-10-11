# 使用 Ubuntu 作为基础映像
FROM ubuntu:20.04

# 设置时区和非交互模式以避免交互提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 更新包列表并安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    tzdata \
    openjdk-11-jdk \
    wget \
    unzip \
    ant \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js（使用 NodeSource）
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 安装 Cordova
RUN npm install -g cordova

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

# 安装需要的 SDK 组件
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# 安装 Flask 和其他 Python 依赖
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# 设置工作目录
WORKDIR /app

# 复制项目文件到容器中
COPY . .

# 暴露端口 10000
EXPOSE 10000

# 创建 src 目录（如果需要）
RUN mkdir -p /app/src

# 检查工具版本
RUN ant -version
RUN java -version
RUN cordova -v

# 执行 Flask 应用
CMD ["flask", "run", "--host=0.0.0.0", "--port=10000"]
