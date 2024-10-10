# 使用 Ubuntu 作为基础映像
FROM ubuntu:20.04

# 设置时区环境变量，避免交互式选择
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

# 更新包列表并安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    tzdata \
    openjdk-11-jdk \
    wget \
    unzip \
    ant \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 安装 Flask 和其他 Python 依赖
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# 设置 Android SDK 相关环境变量
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# 下载 Android SDK
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip -O /tmp/android-tools.zip && \
    mkdir -p $ANDROID_HOME && \
    unzip /tmp/android-tools.zip -d $ANDROID_HOME && \
    rm /tmp/android-tools.zip && \
    yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses

# 安装需要的 SDK 组件
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# 设置工作目录
WORKDIR /app

# 复制项目文件到容器中
COPY . .

# 执行 Flask 应用
CMD ["flask", "run", "--host=0.0.0.0"]
