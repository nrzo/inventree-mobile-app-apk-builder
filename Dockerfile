#FROM fischerscode/flutter-sudo:stable
FROM ghcr.io/cirruslabs/flutter:stable
#USER root
# Set working directory
WORKDIR /app

ARG ALL_PROXY
ENV http_proxy=$ALL_PROXY
ENV HTTP_PROXY=$ALL_PROXY
ENV https_proxy=$ALL_PROXY
ENV HTTPS_PROXY=$ALL_PROXY

ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/
ENV PIP_TRUSTED_HOST=https://mirrors.aliyun.com

# Install dependencies
RUN sudo sed -i 's@http://archive.ubuntu.com/ubuntu/@https://mirrors.ustc.edu.cn/ubuntu/@g' /etc/apt/sources.list.d/ubuntu.sources \
    && sudo sed -i 's@http://security.ubuntu.com/ubuntu/@https://mirrors.ustc.edu.cn/ubuntu/@g' /etc/apt/sources.list.d/ubuntu.sources \
    && sudo apt-get update \
    && sudo apt-get install -y git python3 python3-pip unzip wget python3-venv android-sdk ninja-build \
    && sudo rm -rf /var/lib/apt/lists/*

# Create a virtual environment for Python dependencies
RUN sudo python3 -m venv /env
RUN sudo /env/bin/pip install --upgrade pip
RUN sudo /env/bin/pip install invoke

# Clean the app directory and clone the Git repository
# RUN rm -rf /app/* \
#     && git clone https://github.com/inventree/inventree-app.git /app
# RUN rm -rf /app/* \
#     && git clone git@github.com:nrzo/inventree-app.git /app
COPY inventree-app/ /app/

RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk
# Create a symlink for Python
RUN sudo ln -s /usr/bin/python3 /usr/bin/python

# Run localization before pub get using virtual environment's invoke
RUN /env/bin/invoke translate

# Upgrade flutter to latest stable so Dart SDK >= 3.8.1
#RUN flutter channel stable && flutter upgrade

# Install dependencies using flutter pub get with global flutter
RUN flutter pub get

RUN echo "storePassword=Secret123\nkeyPassword=Secret123\nkeyAlias=key\nstoreFile=/tmp/keys.jks" > /app/android/key.properties
RUN echo -ne "\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > /usr/lib/android-sdk/licenses/android-sdk-license && \
     keytool -genkeypair -v -keystore /tmp/keys.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key -storepass Secret123 -keypass Secret123 -dname "CN=Dummy, OU=Dummy, O=Dummy, L=Dummy, ST=Dummy, C=US"
#RUN /env/bin/invoke android
RUN mkdir -p /output

VOLUME ["/output"]

# Set the default command to build the APK
ENTRYPOINT ["/bin/bash", "-lc", "flutter build apk && mkdir -p /output && cp build/app/outputs/flutter-apk/app-release.apk /output/app.apk"]