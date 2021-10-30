# embedded

#### 1. Introduction

This openEuler version supports embedded devices. Currently, two CPU architectures aarch64 and x86_64 are supported.

#### 2. Compilation Instructions

Compile the **build.sh** script.

```Usage: 
Usage: 

./build.sh -a [aarch64|x86_64] -r [repo] -d [work dir] -p [live|virtual|disk|docker] -t [rpm|image|all]
```

The parameters are described as follows:

- `-r`: repo file in DNF or YUM format. For details, see [Document 1](https://docs.openeuler.org/zh/docs/20.03_LTS/docs/Administration/%E4%BD%BF%E7%94%A8DNF%E7%AE%A1%E7%90%86%E8%BD%AF%E4%BB%B6%E5%8C%85.html "使用DNF管理软件包").

- `-d`: working directory used during compilation. All intermediate files and results are stored in this directory. The compilation process requires large disk space. Therefore, the directory must be located on a disk with **at least 20 GB** available space.
- `-p`: type of the compiled image. Currently, Docker images are supported.

- `-t`: compilation type. `rpm` indicates that the RPM repository is obtained by compiling the source code and patches. `image` indicates that the specified image is compiled based on the specified repo. `all` indicates that the compilation processes specified by `rpm` and `image` are executed in sequence.

- `-a`: parameter reserved for cross compilation.

The structure of the working directory (specified by the `-d` parameter) during normal compilation is as follows:

```
allsrcpath.list         // List of software packages to be compiled generated based on package_conf.xml
image/                  // Location where the image and its description file are stored
kiwiconfig/
logs_1.tar.gz           // Compilation log of each software package in round 1/2
logs_2.tar.gz           // Compilation log of each software package in round 2/2
openeuler.repo
rpms/                   // Directory of the RPM package where each software package is compiled. The RPM package can be referenced as a repo source.
src/                    // Source code file of each software package that is downloaded and patched based on the configuration file
```

**Note: If the compile session (login terminal) is frequently disconnected, use a method similar to ```nohup sh build.sh -r ... > log.txt 2>&1 &```** to avoid compilation interruption due to disconnection.

#### 3. Configuration File Description

The configuration files are stored in the **config** directory.

```
kiwiconf/
openeuler.repo
package_conf.xml
```

- `kiwiconf/`: stores the configuration files required by the `kiwicompat` command. Generally, no modification is required.

For the format of the **config.xml** file, see [Image Description Elements](https://documentation.suse.com/kiwi/9/single-html/kiwi/index.html#image-description-elements "image-description-elements") and [Image Description](https://documentation.suse.com/kiwi/9/html/kiwi/image-description.html "image-description").

KIWI invokes **images.sh** after creating the system directory. This script can be used to trim unnecessary files in the root directory or perform some system settings. For details about the predefined functions and variables that can be used in this script, see [Script Template for config.sh / images.sh](https://documentation.suse.com/kiwi/9/single-html/kiwi/index.html#script-template-for-config-sh-images-sh "script-template-for-config-sh-images-sh").

- ```openeuler.repo```: reserved repo file, which is generally used in the ```-r``` parameter of **build.sh**.

- `package_conf.xml`: The `git format-patch` patch needs to be installed in the source code repository and the software package for source code compilation needs to be configured. The following example describes the function of each tag.

```
<packages>                                                      <!-- Primary tag -->
    <package>                                                   <!-- Define a software package. -->
        <name>argon2</name>                                     <!-- Software package name -->
        <url>https://gitee.com/openeuler-embedded/argon2</url>  <!-- Git repository address of the software package -->
        <branch>openEuler-20.03-LTS</branch>                    <!-- Repository branch or tag -->
        <patch>../src/patch/argon2.patch</patch>                <!-- Path of the patch in the git format-patch format. The path starts from the path of the configuration file. -->
        <enabled>1</enabled>                                    <!-- Enable source code compilation. -->
    </package>                                                  <!-- End a software definition. -->
    <package>                                                   <!-- Define a software package. -->
        <name>attr</name>
        <url>https://gitee.com/openeuler-embedded/attr</url>
        <branch>openEuler-20.03-LTS</branch>
        <patch>../src/patch/attr.patch</patch>
        <enabled>1</enabled>
    </package>
    ......
```

#### 4. Image Usage Example

Take the docker image as an example. The image is stored in the **image** directory of the working directory and is named **openEuler-embedded.xxx-xxx.docker.tar.xz**.

```shell
docker load -i openEuler-embedded.xxx-xxx.docker.tar.xz
docker run --rm --privileged --name embedded-test -v `pwd`:/data -itd openeuler-embedded init
docker exec -it embedded-test bash
```

#### 5. Dependencies

- kiwi >= 9.21

- docker/chroot/createrepo/xmllint/openssl


#### 6. TODO

Up to now, RPM software package compilation and Docker image creation can be used stably.

The following features are coming soon:

- Supports various images, such as VM images and embedded device images.

- The RPM build scheduling module correctly builds all software packages based on the automatically identified dependencies.

- Supports cross compilation.


#### 7. Contribution

1.  Fork this repository.
2.  Create the Feat_xxx branch.
3.  Commit code.
4.  Create a pull request (PR).
