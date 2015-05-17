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
RUN groupadd -r rvm

# install rvm, RVM 1.26.0+ has signed releases, source rvm for usage outside of package scripts
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    (curl -L http://get.rvm.io | bash -s stable) && \
    echo "source /etc/profile.d/rvm.sh" >> /etc/rubybashrc

ENV BASH_ENV /etc/rubybashrc

# install rubies
RUN bash -c " \
    for v in jruby 1.8.7-p374 1.9.3 2.0.0 2.1.6 2.2.2; do \
        rvm install \$v; \
    done && \
    rvm cleanup all && \
    chmod go+rwX /usr/local/rvm -R "

# Install rake-compiler and typical gems in all Rubies
# do not generate documentation for gems
RUN echo "gem: --no-ri --no-rdoc" >> ~/.gemrc && \
    bash -c "rvm all do gem install bundler rake-compiler hoe jeweler mini_portile rubygems-tasks"

# Install rake-compiler's cross rubies in global dir instead of /root
RUN mkdir -p /usr/local/rake-compiler && \
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
    rake-compiler cross-ruby VERSION=2.0.0-p645 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.0.0-p645 HOST=x86_64-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.1.6 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.1.6 HOST=x86_64-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.2.2 HOST=i686-w64-mingw32 && \
    rake-compiler cross-ruby VERSION=2.2.2 HOST=x86_64-w64-mingw32 && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN echo "export MAKE=\"make -j`nproc`\"" >> $HOME/.bashrc; \
    echo "source /etc/rubybashrc" >> $HOME/.bashrc; \
    sed -i -- "s:/root/.rake-compiler:/usr/local/rake-compiler:g" /usr/local/rake-compiler/config.yml

ADD src/sigfw.c /root/
RUN gcc $HOME/sigfw.c -o /usr/local/bin/sigfw
ADD src/runas /usr/local/bin/

ENV BASH_ENV ""

CMD bash
