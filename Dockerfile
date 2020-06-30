FROM python:3.7.4-buster

RUN pip install jupyter

COPY dist dist
RUN pip install dist/ipython_oidc_client-0.1.0-py2.py3-none-any.whl

RUN    jupyter nbextension install --py ipython_oidc_client \
    && jupyter nbextension enable ipython_oidc_client/main \
    && jupyter serverextension enable --py ipython_oidc_client

# add non-root user
RUN useradd -u 8877 docker && mkdir -p /home/docker && chown -R docker:docker /home/docker
WORKDIR /home/docker
USER docker

EXPOSE 8888

CMD SHELL=/bin/bash jupyter notebook --port 8888 --ip=0.0.0.0
