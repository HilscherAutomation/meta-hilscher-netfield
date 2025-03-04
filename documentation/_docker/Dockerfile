FROM sphinxdoc/sphinx

ENV DEBIAN_FRONTEND noninteractive

# NOTE: The command 'pip install' should not run as root!
# RUN useradd -ms /bin/bash default-user
# USER default-user

RUN pip install --upgrade pip \
    && pip install sphinx_rtd_theme \
    && pip install sphinx-toolbox sphinxcontrib-spelling && mkdir /.cache && chmod 777 /.cache \
    && apt-get update \
    && apt-get install -y libenchant-2-2 \
    && apt-get install -y latexmk texlive-latex-extra

WORKDIR /docs
