# Docker image demonstrating how to install the package on a jupyter server
FROM python:3.7.4-buster

RUN pip install jupyter

RUN pip install ipython_oidc_client

RUN    jupyter nbextension install --py ipython_oidc_client \
    && jupyter nbextension enable --py ipython_oidc_client --system \
    && jupyter serverextension enable --py ipython_oidc_client --system

# add non-root user
RUN useradd -u 8877 docker && mkdir -p /home/docker && chown -R docker:docker /home/docker
WORKDIR /home/docker
USER docker

EXPOSE 8888

CMD SHELL=/bin/bash jupyter notebook --port 8888 --ip=0.0.0.0
