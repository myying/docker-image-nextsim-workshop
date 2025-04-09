# Build nextsimdg model
FROM ghcr.io/nextsimhub/nextsimdg-dev-env:latest

RUN git clone https://github.com/nextsimhub/nextsimdg.git /nextsimdg

WORKDIR /nextsimdg/build

RUN . /opt/spack-environment/activate.sh && \
    cmake -DWITH_THREADS=ON -DCMAKE_BUILD_TYPE=Release -DENABLE_MPI=OFF -DENABLE_XIOS=OFF -Dxios_DIR=/xios .. && \
    make -j 1

# Install basic build tools, MPICH, FFTW3, and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gnupg2 ca-certificates build-essential \
    mpich libmpich-dev libfftw3-dev \
    python3 python3-pip python3-dev python3-venv && \
    rm -rf /var/lib/apt/lists/*

# add user
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=yingyue
RUN groupadd -g ${GROUP_ID} ${USER_NAME} && \
    useradd -u ${USER_ID} -g ${USER_NAME} -m ${USER_NAME} && \
    mkdir -p /app && chown ${USER_NAME}:${USER_NAME} /app
USER ${USER_NAME}
WORKDIR /app

# Python environment
RUN python3 -m venv /app/pyenv
RUN echo '. /app/pyenv/bin/activate' > /app/python.src
ENV PATH=/app/pyenv/bin:$PATH

# Install NEDAS required libraries
RUN git clone https://github.com/nansencenter/NEDAS.git /app/NEDAS
WORKDIR /app/NEDAS
RUN git checkout -b develop origin/develop
ENV PYTHONPATH=/app/NEDAS:$PYTHONPATH

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt && \
    pip3 install numba pyFFTW cmocean jupyter && \
    MPICC=mpicc pip3 install --no-binary=mpi4py mpi4py

####run notebook
WORKDIR /nextsim-workshop

CMD [ "/pyenv/bin/jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root" ]
