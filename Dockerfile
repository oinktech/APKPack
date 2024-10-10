# 使用 Ubuntu 作為基礎映像
FROM ubuntu:20.04

# 安裝必要的工具和依賴
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    unzip \
    ant \
    && rm -rf /var/lib/apt/lists/*

# 設定環境變量
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# 下載 Android SDK
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip -O /tmp/android-tools.zip && \
    mkdir -p $ANDROID_HOME && \
    unzip /tmp/android-tools.zip -d $ANDROID_HOME && \
    rm /tmp/android-tools.zip && \
    yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses

# 安裝需要的 SDK 組件
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# 設定工作目錄
WORKDIR /app

# 複製你的專案文件到容器中
COPY . .

# 執行 Ant 指令
CMD ["ant", "debug"]
