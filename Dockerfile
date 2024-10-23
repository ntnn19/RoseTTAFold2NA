# Use an official base image with Conda and CUDA support (modify as needed)
ARG CUDA_VERSION=11.8.0
FROM nvidia/cuda:${CUDA_VERSION}-base-ubuntu22.04

# Set environment variables to avoid interactive installation prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN apt-get update && apt-get install -y wget parallel cuda-nvcc-$(echo $CUDA_VERSION | cut -d'.' -f1,2 | tr '.' '-') --no-install-recommends --no-install-suggests && rm -rf /var/lib/apt/lists/* && \
    wget -qnc https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Mambaforge-24.7.1-0-Linux-x86_64.sh && \
    bash Mambaforge-24.7.1-0-Linux-x86_64.sh -bfp /usr/local && \
    conda config --set auto_update_conda false && \
    rm -f Mambaforge-24.7.1-0-Linux-x86_64.sh

# Set conda path
ENV PATH=/opt/conda/bin:$PATH

# Copy environment YAML file for RoseTTAFold2NA
COPY RF2na-linux.yml /app/RF2na-linux.yml

# Create the conda environment
RUN conda env create -f /app/RF2na-linux.yml

# Activate the environment
SHELL ["conda", "run", "-n", "RF2NA", "/bin/bash", "-c"]

# Copy the local SE3Transformer directory into the container
COPY . /app

# Set working directory to SE3Transformer
WORKDIR /app/SE3Transformer

# Install SE(3)-Transformer dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install SE(3)-Transformer
RUN python setup.py install

# Change the working directory back to the root directory ("/app")
WORKDIR /app

# Set the default command to activate the conda environment
CMD ["conda", "run", "-n", "RF2NA", "/bin/bash"]
