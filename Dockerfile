# 使用官方的 Ubuntu 基础映像
FROM ubuntu:20.04

# 设置环境变量
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV GRADLE_HOME=/opt/gradle/gradle-7.6
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${GRADLE_HOME}/bin

# 更新系统并安装必要的工具
RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    openjdk-11-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建安装目录
RUN mkdir -p ${ANDROID_SDK_ROOT} ${GRADLE_HOME}

# 从 Gradle 官方网站下载最新版本的 Gradle
RUN wget -q -O /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-7.6-bin.zip" && \
    unzip -q /tmp/gradle.zip -d /opt && \
    rm /tmp/gradle.zip

# 确保 GRADLE_HOME 环境变量正确设置
RUN ln -s ${GRADLE_HOME}/bin/gradle /usr/local/bin/gradle

# 检查 Gradle 是否存在，列出目录内容，增加错误处理
RUN echo "Checking Gradle installation..." && \
    ls -l ${GRADLE_HOME} && \
    ls -l ${GRADLE_HOME}/bin || { echo "Gradle installation failed!"; exit 1; }

# 下载 Android Command Line Tools
RUN wget -q -O /tmp/android-tools.zip "https://www.dropbox.com/scl/fi/2z4xgbiivh496tbmm7qxb/commandlinetools-linux-8092744_latest.zip?rlkey=i0k715n8f20fa3a5faq3z4l9v&dl=1" && \
    unzip -q /tmp/android-tools.zip -d ${ANDROID_SDK_ROOT} && \
    rm /tmp/android-tools.zip

# 移动工具目录并设置权限
RUN mv ${ANDROID_SDK_ROOT}/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools-latest

# 确保所需的 SDK 组件已安装
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools-latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools-latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# 设置工作目录
WORKDIR /app

# 复制您的项目文件到容器中
COPY . .

# 使用完整路径执行 Gradle 以避免找不到问题
RUN /opt/gradle/gradle-7.6/bin/gradle build || { echo "Gradle build failed!"; exit 1; }

# 曝露端口（根据需要）
EXPOSE 8080

# 定义容器启动时运行的命令
CMD ["/opt/gradle/gradle-7.6/bin/gradle", "assembleDebug"]
