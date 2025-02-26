
# Use a base image that supports multiple runtimes
FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl gnupg supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for API, UI, Handler
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs build-essential

COPY . /app

# Set up working directories
WORKDIR /app

RUN npm install -g npm@9.5.1

RUN npm install -g pm2 typescript tsc-watch

RUN npm install

# Install MongoDB
RUN apt-get install -y mongodb && mkdir -p /data/db

RUN apt update && \
    apt-get update && apt-get upgrade -y
    
RUN apt-get install -y parallel python3 python3-pip tree curl unzip git jq python libgl-dev python-numpy bc

RUN pip3 install numpy==1.23.0 nibabel==4.0.0 pandas matplotlib pyyaml==5.4.1 pydicom==2.3.1 natsort pydeface rdflib==6.3.2 && \
    pip3 install quickshear mne mne-bids && \
    pip3 install conversiontelemetry

# Install pypet2bids
RUN git clone https://github.com/openneuropet/PET2BIDS && \
    cd PET2BIDS && make installpoetry buildpackage installpackage

RUN apt-get install -y pkg-config cmake git pigz rename zstd libopenjp2-7 libgdcm-tools wget libopenblas-dev && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y


RUN touch /.pet2bidsconfig && chown 1001:1001 /.pet2bidsconfig
RUN echo "DEFAULT_METADATA_JSON=/usr/local/lib/python3.8/dist-packages/pypet2bids/template_json.json" > /.pet2bidsconfig

#this is the most tedious that's why it's one of the first layers installed
#install fsl, and get rid of src
# RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
#       python fslinstaller.py -d /usr/local/fsl -V 6.0.6 && rm -rf /usr/local/fsl/src

RUN mkdir -p /usr/local/fsl && \
    git clone https://github.com/dlevitas/FSL_binaries /usr/local/fsl && \
    rm -rf /usr/local/fsl/README.md && \
    mkdir -p /usr/local/fsl/data/standard && \
    mv /usr/local/fsl/bin/MNI152_T1_2mm_brain.nii.gz /usr/local/fsl/data/standard

ENV FSLDIR=/usr/local/fsl
ENV PATH=$PATH:$FSLDIR/bin
# ENV LD_LIBRARY_PATH=$FSLDIR/lib
# RUN . $FSLDIR/etc/fslconf/fsl.sh

ENV FSLOUTPUTTYPE=NIFTI_GZ

# #make sure fslpython is properly installed
# RUN which imcp

# # certs have expired for nodesource use the hack below to get around that for install
# #### HACK Warning ####
# # unfortuanetly this seems to work the most reliably
# # see https://github.com/nodesource/distributions/issues/1266#issuecomment-938408547 and
# RUN echo "insecure" > $HOME/.curlrc \
#     && echo "Acquire::https::Verify-Peer false;" >> /etc/apt/apt.conf.d/80ssl-exceptions \ 
#     && echo "Acquire::https::Verify-Host false;" >> /etc/apt/apt.conf.d/80ssl-exceptions \
#     && curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
#     && apt install -y nodejs \ 
#     && rm -f $HOME/.curlrc \
#     && rm -f /etc/apt/apt.conf.d/80ssl-exceptions \
#     && npm --version

RUN apt-get update \
    && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

ARG NODE_MAJOR=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list



RUN cd /tmp && curl -fLO https://github.com/rordenlab/dcm2niix/releases/latest/download/dcm2niix_lnx.zip \
    && unzip /tmp/dcm2niix_lnx.zip \
    && mv dcm2niix /usr/local/bin

# Don't need, unless there's a reason for having the development branch ahead of scheduled release
# RUN git clone --branch development https://github.com/rordenlab/dcm2niix.git \
#     && cd dcm2niix/console \
#     && make \
#     && mv dcm2niix /usr/local/bin

# Get bids-specification from github
RUN cd && git clone https://github.com/bids-standard/bids-specification

#install ROBEX
ADD https://www.nitrc.org/frs/download.php/5994/ROBEXv12.linux64.tar.gz//?i_agree=1&download_now=1 /
RUN tar -xzf /ROBEXv12.linux64.tar.gz
ENV PATH /app/ROBEX:$PATH

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/v$NODE_VERSION/bin:$PATH

#install bids-validator
RUN npm install -g bids-validator@1.14.8
RUN git clone https://github.com/bids-standard/bids-validator

# Install Python for Telemetry
# RUN apt-get install -y python3 python3-pip
# COPY ./telemetry/requirements.txt /app/telemetry/requirements.txt
# RUN pip3 install -r /app/telemetry/requirements.txt

RUN npm run prepare-husky

# Set the shared authentication environment variable
ENV BRAINLIFE_AUTHENTICATION=false
ENV VITE_BRAINLIFE_AUTHENTICATION=false
ENV MONGO_CONNECTION_STRING=mongodb://localhost:27017/ezbids
ENV VITE_APIHOST=http://localhost:8082
ENV MONGO_DB_USE='telemetry'
ENV MONGO_DB_NAME='telemetry'
ENV MONGO_DB_ADDRESS=127.0.0.1:27017
ENV MONGO_DB_COLLECTION='telemetry'
ENV TELEMETRY_RATE_LIMITING=false

RUN chmod +x /app/generate_keys.sh
RUN /app/generate_keys.sh

# Install dependencies
RUN cd /app/api && npm install && tsc
RUN cd /app/ui && npm install
RUN cd /app/handler

# Copy Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY telemetry/telemetry.env /root/.telemetry.env

# Expose necessary ports
EXPOSE 27017 8082 3000 8000

# Start all services using Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]