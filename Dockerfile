# Build nextsimdg model
FROM ghcr.io/nextsimhub/nextsimdg-dev-env:latest

RUN git clone https://github.com/nextsimhub/nextsimdg.git /nextsimdg

WORKDIR /nextsimdg/build

RUN . /opt/spack-environment/activate.sh && \
    cmake -DWITH_THREADS=ON -DCMAKE_BUILD_TYPE=Release -DENABLE_MPI=OFF -DENABLE_XIOS=OFF -Dxios_DIR=/xios .. && \
    make -j 1

# Install Python and create pyenv
RUN apt-get update && \
    apt-get install -y python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /pyenv
RUN echo '. /pyenv/bin/activate' > /python.src
ENV PATH=/pyenv/bin:$PATH

# Install NEDAS required libraries
RUN git clone https://github.com/nansencenter/NEDAS.git /NEDAS
WORKDIR /NEDAS
RUN git checkout -b develop origin/develop

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN pip3 install numba jupyter cmocean

####run notebook
WORKDIR /nextsim-workshop

CMD [ "/pyenv/bin/jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root" ]
