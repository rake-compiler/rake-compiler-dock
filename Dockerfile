FROM ubuntu:14.04

RUN apt-get -y update && \
    apt-get install -y curl git-core mingw32 xz-utils build-essential

RUN mkdir -p ~/mingw && \
    curl -SL http://sunet.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win32/Personal%20Builds/rubenvb/gcc-4.7-release/i686-w64-mingw32-gcc-4.7.2-release-linux64_rubenvb.tar.xz | \
    tar -xJC ~/mingw && \
    echo "export PATH=\$PATH:$HOME/mingw/mingw32/bin" >> $HOME/.dockerbashrc

RUN mkdir -p ~/mingw && \
    curl -SL http://softlayer-ams.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/rubenvb/gcc-4.7-release/x86_64-w64-mingw32-gcc-4.7.2-release-linux64_rubenvb.tar.xz | \
    tar -xJC ~/mingw && \
    echo "export PATH=\$PATH:$HOME/mingw/mingw64/bin" >> $HOME/.dockerbashrc

# install rvm, RVM 1.26.0+ has signed releases, source rvm for usage outside of package scripts
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    (curl -L http://get.rvm.io | bash -s stable) && \
    echo "source /etc/profile.d/rvm.sh" >> $HOME/.dockerbashrc

ENV BASH_ENV /root/.dockerbashrc

# install rubies
RUN bash -c " \
    for v in jruby 1.8.7-p374 1.9.3 2.0.0 2.1.5 2.2.0; do \
        rvm install \$v; \
    done && \
    rvm cleanup all"

# Install rake-compiler in all Rubies
# do not generate documentation for gems
RUN echo "gem: --no-ri --no-rdoc" >> ~/.gemrc && \
    bash -c "rvm all do gem install bundler rake-compiler hoe"

# Build 1.8.7 with mingw32 compiler (GCC 4.2)
# Use just one CPU for building 1.8.7 and 1.9.3
RUN bash -c "rvm use 1.8.7-p374 && \
    rake-compiler cross-ruby VERSION=1.8.7-p374 HOST=i586-mingw32msvc && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN bash -c "rvm use 1.9.3 && \
    rake-compiler cross-ruby VERSION=1.9.3-p550 HOST=i586-mingw32msvc && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN bash -c "rvm use 2.2.0 --default && \
    rake-compiler cross-ruby VERSION=2.0.0-p598 HOST=i686-w64-mingw32 debugflags="-g" && \
    rake-compiler cross-ruby VERSION=2.0.0-p598 HOST=x86_64-w64-mingw32 debugflags="-g" && \
    rake-compiler cross-ruby VERSION=2.1.5 HOST=i686-w64-mingw32 debugflags="-g" && \
    rake-compiler cross-ruby VERSION=2.1.5 HOST=x86_64-w64-mingw32 debugflags="-g" && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

# Ruby-2.2 make install fails on one of the last steps, that isn't really required
RUN bash -c "rvm use 2.2.0 && \
    (rake-compiler cross-ruby VERSION=2.2.0 HOST=i686-w64-mingw32 debugflags="-g" || rake-compiler update-config) && \
    (rake-compiler cross-ruby VERSION=2.2.0 HOST=x86_64-w64-mingw32 debugflags="-g" || rake-compiler update-config) && \
    rm -rf ~/.rake-compiler/builds ~/.rake-compiler/sources"

RUN echo "export MAKE=\"make -j`nproc`\"" >> $HOME/.bashrc

RUN mkdir /extern
WORKDIR /extern
VOLUME /extern
CMD bash
