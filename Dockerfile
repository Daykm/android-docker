FROM ubuntu:16.04
# ------------------------------------------------------
# --- Base pre-installed tools
RUN apt-get update -qq
RUN apt-get install -y wget

# Generate proper EN US UTF-8 locale
# Install the "locales" package - required for locale-gen
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    locales \
# Do Locale gen
 && locale-gen en_US.UTF-8

ENV ANDROID_HOME /opt/android-sdk-linux

# Dependencies to execute Android builds
RUN dpkg --add-architecture i386
RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jdk libc6:i386 libstdc++6:i386 libgcc1:i386 libncurses5:i386 libz1:i386


# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_HOME

RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-3952940.zip -O android-sdk-tools.zip \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm -f android-sdk-tools.zip

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

# ------------------------------------------------------
# --- Install Android SDKs and other build packages

# Other tools and resources of Android SDK
#  you should only install the packages you need!
# To get a full list of available options you can use:
#  sdkmanager --list

# Accept "android-sdk-license" before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN mkdir -p ${ANDROID_HOME}/licenses
RUN echo 8933bad161af4178b1185d1a37fbf41ea5269c55 > ${ANDROID_HOME}/licenses/android-sdk-license

# Platform tools
RUN sdkmanager "platform-tools"

# Emulator
RUN sdkmanager "emulator"

# SDKs
# Please keep these in descending order!
RUN sdkmanager "platforms;android-26"
RUN sdkmanager "platforms;android-25"
RUN sdkmanager "platforms;android-24"
RUN sdkmanager "platforms;android-23"
RUN sdkmanager "platforms;android-22"
RUN sdkmanager "platforms;android-21"
RUN sdkmanager "platforms;android-20"
RUN sdkmanager "platforms;android-19"

# build tools
# Please keep these in descending order!
RUN sdkmanager "build-tools;26.0.1"
RUN sdkmanager "build-tools;26.0.0"
RUN sdkmanager "build-tools;25.0.3"
RUN sdkmanager "build-tools;25.0.2"

# Extras
RUN sdkmanager "extras;google;google_play_services"

# google apis
# Please keep these in descending order!
RUN sdkmanager "add-ons;addon-google_apis-google-23"

# ------------------------------------------------------
# --- Install Gradle from PPA

# Gradle PPA
RUN apt-get update
RUN apt-get -y install gradle
RUN gradle -v

# ------------------------------------------------------
# --- Install Google Cloud SDK
# https://cloud.google.com/sdk/downloads
#  Section: apt-get (Debian and Ubuntu only)
#
# E.g. for "Using Firebase Test Lab for Android from the gcloud Command Line":
#  https://firebase.google.com/docs/test-lab/command-line
#

RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk-`lsb_release -c -s` main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
RUN sudo apt-get update -qq
RUN sudo apt-get install -y -qq google-cloud-sdk

ENV GCLOUD_SDK_CONFIG /usr/lib/google-cloud-sdk/lib/googlecloudsdk/core/config.json

# gcloud config doesn't update config.json. See the official Dockerfile for details:
#  https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/master/Dockerfile
RUN /usr/bin/gcloud config set --installation component_manager/disable_update_check true
RUN sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' $GCLOUD_SDK_CONFIG

RUN /usr/bin/gcloud config set --installation core/disable_usage_reporting true
RUN sed -i -- 's/\"disable_usage_reporting\": false/\"disable_usage_reporting\": true/g' $GCLOUD_SDK_CONFIG

# ------------------------------------------------------
# --- Cleanup and rev num
# Cleaning
RUN apt-get clean