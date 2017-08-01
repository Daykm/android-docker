FROM ubuntu:16.04


# ------------------------------------------------------
# --- Environments and base directories

# Environments
# - Language
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
# - CI
    CI="true" \
    BITRISE_IO="true" \
# - main dirs
    BITRISE_SOURCE_DIR="/bitrise/src" \
    BITRISE_BRIDGE_WORKDIR="/bitrise/src" \
    BITRISE_DEPLOY_DIR="/bitrise/deploy" \
    BITRISE_CACHE_DIR="/bitrise/cache" \
    BITRISE_PREP_DIR="/bitrise/prep" \
    BITRISE_TMP_DIR="/bitrise/tmp" \

# Configs - tool versions
    TOOL_VER_BITRISE_CLI="1.7.0" \
    TOOL_VER_RUBY="2.4.1" \
    TOOL_VER_GO="1.8.3" \
    TOOL_VER_DOCKER="17.03.1" \
    TOOL_VER_DOCKER_COMPOSE="1.11.2"

# create base dirs
RUN mkdir -p ${BITRISE_SOURCE_DIR} \
 && mkdir -p ${BITRISE_DEPLOY_DIR} \
 && mkdir -p ${BITRISE_CACHE_DIR} \
 && mkdir -p ${BITRISE_TMP_DIR} \
# prep dir
 && mkdir -p ${BITRISE_PREP_DIR}

# switch to temp/prep workdir, for the duration of the provisioning
WORKDIR ${BITRISE_PREP_DIR}


# ------------------------------------------------------
# --- Base pre-installed tools
RUN apt-get update -qq

# Generate proper EN US UTF-8 locale
# Install the "locales" package - required for locale-gen
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    locales \
# Do Locale gen
 && locale-gen en_US.UTF-8


RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
# Requiered for Bitrise CLI
    git \
    mercurial \
    curl \
    wget \
    rsync \
    sudo \
    expect \
# Python
    python \
    python-dev \
    python-pip \
# Common, useful
    build-essential \
    zip \
    unzip \
    tree \
    imagemagick \
# For PPAs
    software-properties-common



# ------------------------------------------------------
# --- Pre-installed but not through apt-get

# Install docker
#  as described at: https://docs.docker.com/engine/installation/linux/ubuntu/
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apt-transport-https \
    ca-certificates
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
 && DEBIAN_FRONTEND=noninteractive apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-cache policy docker-ce \
# For available docker-ce versions
#  you can run `sudo apt-get update && sudo apt-cache policy docker-ce`
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce=${TOOL_VER_DOCKER}~ce-0~ubuntu-$(lsb_release -cs)


# docker-compose
RUN wget -q https://github.com/docker/compose/releases/download/${TOOL_VER_DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose \
 && docker-compose --version

# ------------------------------------------------------
# --- SSH config

COPY ./ssh/config /root/.ssh/config

# ------------------------------------------------------
# --- Git config

RUN git config --global user.email daykm@email.com\
 && git config --global user.name "Day bot"


# ------------------------------------------------------
# --- Git LFS

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git-lfs \
 && git lfs install


# ------------------------------------------------------
# --- Cleanup, Workdir and revision

WORKDIR $BITRISE_SOURCE_DIR

ENV BITRISE_DOCKER_REV_NUMBER_BASE v2017_07_11_1
CMD bitrise --version

ENV ANDROID_HOME /opt/android-sdk-linux


# ------------------------------------------------------
# --- Install required tools

RUN apt-get update -qq

# Base (non android specific) tools
# -> should be added to bitriseio/docker-bitrise-base

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

ENV BITRISE_DOCKER_REV_NUMBER_ANDROID v2017_07_26_1
CMD bitrise -version