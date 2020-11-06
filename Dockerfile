# 1: Runtime Stage =============================================================
FROM ruby:2.7-slim AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    openssl \
    libpq5 \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# 2: Testing Stage =============================================================

FROM runtime AS testing

# Receive the developer user's ID and username:
ARG DEVELOPER_UID=1000
ARG DEVELOPER_USERNAME=you

# Replicate the developer user in the development image:
RUN addgroup --gid ${DEVELOPER_UID} ${DEVELOPER_USERNAME} \
 ;  useradd -r -m -u ${DEVELOPER_UID} --gid ${DEVELOPER_UID} \
    --shell /bin/bash -c "Developer User,,," ${DEVELOPER_USERNAME}

RUN apt-get update && apt-get install -y --no-install-recommends gnupg

# Install the app build system dependency packages:
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libpq-dev \
    sudo

# Add the developer to the sudoers list:
RUN echo "${DEVELOPER_USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${DEVELOPER_USERNAME}"

# Receive the app path as argument:
ARG APP_PATH=/srv/last-n-of-each-demo

# Create the working directory
RUN mkdir -p ${APP_PATH} && chown ${DEVELOPER_UID}:${DEVELOPER_UID} ${APP_PATH}

# Set the developer user as the current user:
USER ${DEVELOPER_USERNAME}

# Set the working directory
WORKDIR ${APP_PATH}

# Add the app "bin/" directory to PATH:
ENV PATH=${APP_PATH}/bin:$PATH

# Copy the project's Gemfile + lock:
COPY --chown=${DEVELOPER_USERNAME} Gemfile* ${APP_PATH}/

# Install the gems in the Gemfile, except for the ones in the "development"
# group, which shouldn't be required in order to run the tests with the leanest
# Docker image possible:
RUN bundle install --jobs=4 --retry=3 --without="development"

# 3: Development Stage =========================================================

FROM testing AS development

# Install development-stage tools you might want to use:
# RUN sudo apt-get install -y --no-install-recommends vim

# Install the current project gems - they can be safely changed later during the
# development session via `bundle install` or `bundle update`:
RUN bundle install --jobs=4 --retry=3 --with="development"