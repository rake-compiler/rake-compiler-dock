Docker image with compilers for ruby platform x64-mingw-ucrt
------------------

This Dockerfile builds compilers for Windows UCRT target.
It takes the mingw compiler provided by Debian/Ubuntu and configures and compiles them for UCRT.
Outputs are *.deb files of binutils, gcc and g++.
Rake-compiler-dock reads them from this image as part of its build process for the x64-mingw-ucrt platform.

The image is provided for arm64 and amd64 architectures.
They are built by the following command:

```sh
docker buildx build . -t larskanis/mingw64-ucrt:20.04 --platform linux/arm64,linux/amd64 --push
```
