FROM ubuntu:14.04

RUN apt-get -y update && \
    apt-get install -y curl git-core mingw32 xz-utils build-essential openjdk-7-jdk

RUN mkdir -p /opt/mingw && \
    curl -SL http://sunet.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win32/Personal%20Builds/rubenvb/gcc-4.7-release/i686-w64-mingw32-gcc-4.7.2-release-linux64_rubenvb.tar.xz | \
    tar -xJC /opt/mingw && \
    echo "export PATH=\$PATH:/opt/mingw/mingw32/bin" >> /etc/rubybashrc && \
    ln -s /opt/mingw/mingw32/bin/* /usr/local/bin/

RUN mkdir -p /opt/mingw && \
    curl -SL http://softlayer-ams.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/rubenvb/gcc-4.7-release/x86_64-w64-mingw32-gcc-4.7.2-release-linux64_rubenvb.tar.xz | \
    tar -xJC /opt/mingw && \
    echo "export PATH=\$PATH:/opt/mingw/mingw64/bin" >> /etc/rubybashrc && \
    ln -s /opt/mingw/mingw64/bin/* /usr/local/bin/

# Add "rvm" as system group, to avoid conflicts with host GIDs typically starting with 1000
RUN groupadd -r rvm && useradd -r -g rvm -G sudo -p "" --create-home rvm && \
    echo "source /etc/profile.d/rvm.sh" >> /etc/rubybashrc
USER rvm

# install rvm, RVM 1.26.0+ has signed releases, source rvm for usage outside of package scripts
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    (curl -L http://get.rvm.io | sudo bash -s stable) && \
    bash -c " \
        source /etc/rubybashrc && \
        rvmsudo rvm cleanup all "

ENV BASH_ENV /etc/rubybashrc

# install rubies and fix permissions on
RUN bash -c " \
    for v in 1.8.7-p374 1.9.3 2.2.2 jruby ; do \
        rvm install \$v; \
    done && \
    rvm cleanup all && \
    find /usr/local/rvm -type d | sudo xargs chmod g+sw "

# Install rake-compiler and typical gems in all Rubies
# do not generate documentation for gems
RUN echo "gem: --no-ri --no-rdoc" >> ~/.gemrc && \
    bash -c " \
        rvm all do gem install bundler rake-compiler hoe mini_portile rubygems-tasks && \
        find /usr/local/rvm -type d | sudo xargs chmod g+sw "

# Install rake-compiler's cross rubies in global dir instead of /root
RUN sudo mkdir -p /usr/local/rake-compiler && \
    sudo chown rvm.rvm /usr/local/rake-compiler && \
    ln -s /usr/local/rake-compiler ~/.rake-compiler

# Build 1.8.7 with mingw32 compiler (GCC 4.2)
# Use just one CPU for building 1.8.7 and 1.9.3
RUN bash -c "rvm use 1.8.7-p374 && \
    rake-compiler cross-ruby VERSION=1.8.7-p374 HOST=i586-mingw32msvc && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN bash -c "rvm use 1.9.3 && \
    rake-compiler cross-ruby VERSION=1.9.3-p550 HOST=i586-mingw32msvc && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN bash -c "rvm use 2.2.2 --default && \
    export MAKE=\"make -j`nproc`\" && \
    rake-compiler cross-ruby VERSION=2.0.0-p645 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.0.0-p645 HOST=x86_64-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.1.6 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.1.6 HOST=x86_64-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.2.2 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.2.2 HOST=x86_64-w64-mingw32 && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources && \
    find /usr/local/rvm -type d | sudo xargs chmod g+sw "

RUN bash -c " \
    rvm alias create 1.8 1.8.7-p374 && \
    rvm alias create 1.9 1.9.3 && \
    rvm alias create 2.2 2.2.2 && \
    rvm alias create jruby jruby "

USER root

# Fix paths in rake-compiler/config.yml and add rvm to the global bashrc
RUN sed -i -- "s:/root/.rake-compiler:/usr/local/rake-compiler:g" /usr/local/rake-compiler/config.yml && \
    echo "source /etc/profile.d/rvm.sh" >> /etc/bash.bashrc

ADD src/sigfw.c /root/
RUN gcc $HOME/sigfw.c -o /usr/local/bin/sigfw
ADD src/runas /usr/local/bin/

CMD bash
