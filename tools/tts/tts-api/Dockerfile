# Grab debian-bullseye-slim
FROM debian:bullseye-slim

# install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ffmpeg wget curl python3 python3-pip python3-dev build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Anaconda
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py310_22.11.1-1-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda create -n intel python=3.9 numba=0.55.1 ffmpeg -c conda-forge && conda clean --index-cache --tarballs --packages

# Use the python environment from now on.
SHELL ["conda", "run", "-n", "intel", "/bin/bash", "-c"]

# Setup python requirements
RUN pip install Flask &&\
    pip install waitress &&\
    pip install pysbd &&\
    pip install pydub &&\
    pip install requests &&\
    pip cache purge

COPY . /root
RUN mkdir /tts_files
WORKDIR /root

# fix: `libstdc++.so.6: version `GLIBCXX_3.4.29' not found`
RUN conda env config vars set TTS_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
RUN conda env config vars set LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_DIR/lib

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "intel", "python", "tts-api.py"]
