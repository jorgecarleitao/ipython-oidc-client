FROM python:3.7.4-buster

# install jupyter notebooks
RUN pip install jupyter

EXPOSE 8888

# add non-root user
#RUN useradd -u 8877 docker && mkdir -p /home/docker && chown -R docker:docker /home/docker
#WORKDIR /home/docker
#USER docker

CMD SHELL=/bin/bash \
    && cd project \
    && pip install -e . \
    && jupyter nbextension install ipython_oidc_client/client/ --symlink --user \
    && jupyter nbextension enable client/main \
    && jupyter serverextension enable --py ipython_oidc_client \
    && jupyter notebook --allow-root --port 8888 --ip=0.0.0.0

#CMD SHELL=/bin/bash ls project
