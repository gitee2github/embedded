# embedded

#### 1 介绍

支持嵌入式设备的openEuler版本，目前支持[aarch64|x86_64]两种CPU架构

#### 2 编译说明

编译入口build.sh，其用法如下

```Usage: 
Usage: 

./build.sh -a [aarch64|x86_64] -r [repo] -d [work dir] -p [live|virtual|disk|docker|devdocker] -t [rpm|image|all]
```

各参数作用说明如下：

1）-r，指定repo文件，格式为dnf/yum的配置文件格式，可参考[文档1](https://docs.openeuler.org/zh/docs/20.03_LTS/docs/Administration/%E4%BD%BF%E7%94%A8DNF%E7%AE%A1%E7%90%86%E8%BD%AF%E4%BB%B6%E5%8C%85.html "使用DNF管理软件包")。软件包仓应含gcc/make/rpm-build等完整编译工具链及其依赖

2）-d，指定编译过程使用的工作目录，所有中间文件以及结果都存放在该目录。由于编译过程需要使用较大磁盘空间，该目录应当位于具有**≥20G**剩余空间的磁盘中。

3）-p，指定编译所得镜像类型，目前稳定支持docker镜像和devdocker(开发者镜像）。

4）-t，指定编译类型，rpm是指根据源码和补丁编译得到rpm仓库；image是指根据给定repo编译指定镜像；all将会按顺序执行rpm和image指定的编译过程。

5）-a，无需指定，预留支持交叉编译的参数。

正常编译时的工作目录（-d参数指定）结构如下：

```
allsrcpath.list         // 根据package_conf.xml生成的待编译软件包列表
image/                  // 镜像及其描述文件存放位置
kiwiconfig/
logs_1.tar.gz           // 第1/2轮各软件包编译日志
logs_2.tar.gz           // 第2/2轮各软件包编译日志
openeuler.repo
rpms/                   // 各软件包编译所在rpm包存在目录，可作为一个repo源引用
src/                    // 根据配置文件下载和打补丁得到各软件包源码文件
```

**需注意，若起编译的session（登录终端）容易出现断连，请使用类似```nohup sh build.sh -r ... > log.txt 2>&1 &```的方式执行编译**，避免断连导致编译中断。

#### 3 配置文件说明

配置文件位于config目录下：

```
kiwiconf/
openeuler.repo
package_conf.xml
```

1） ```kiwiconf/```，存放kiwicompat命令所需配置文件。一般无需改动。

config.xml文件格式参考[文档2](https://documentation.suse.com/kiwi/9/single-html/kiwi/index.html#image-description-elements "image-description-elements")，[文档3](https://documentation.suse.com/kiwi/9/html/kiwi/image-description.html "image-description")。

kiwi创建完系统目录调用images.sh。该脚本可用于裁减根目录中不必要的文件或进行一些系统设置。该脚本可用的一些预定义函数和变量见[文档4](https://documentation.suse.com/kiwi/9/single-html/kiwi/index.html#script-template-for-config-sh-images-sh "script-template-for-config-sh-images-sh")。

2）```openeuler.repo```，预留的repo文件，一般用在build.sh的```-r```参数。

3）```package_conf.xml```，需对源码仓打git format-patch补丁并进行源码编译的软件包配置，以一个例子说明各tag作用

```
<packages>                                                      <!-- 主tag -->
    <package>                                                   <!-- 定义一个软件包 -->
        <name>argon2</name>                                     <!-- 软件包名 -->
        <url>https://gitee.com/openeuler-embedded/argon2</url>  <!-- 软件包git仓库地址 -->
        <branch>openEuler-20.03-LTS</branch>                    <!-- 仓库分支或tag -->
        <patch>../src/patch/argon2.patch</patch>                <!-- git formatpatch格式补丁所在路径，路径起点该配置文件所在路径 -->
        <enabled>1</enabled>                                    <!-- 使能源码编译 -->
    </package>                                                  <!-- 结束一个软件定义 -->
    <package>                                                   <!-- 定义一个软件包 -->
        <name>attr</name>
        <url>https://gitee.com/openeuler-embedded/attr</url>
        <branch>openEuler-20.03-LTS</branch>
        <patch>../src/patch/attr.patch</patch>
        <enabled>1</enabled>
    </package>
    ......
```

#### 4 镜像使用示例

以docker镜像为例，镜像位于工作目录的image路径下，名称为openEuler-embedded.xxx-xxx.docker.tar.xz。

```shell
docker load -i openEuler-embedded.xxx-xxx.docker.tar.xz
docker run --rm --privileged --name embedded-test -v `pwd`:/data -itd openeuler-embedded init
docker exec -it embedded-test bash
```

用户也可以使用openeuler-embedded-sig基于该仓库编译所得，托管在华为云的镜像，下载方式如下：
```
# 开发者docker镜像
docker pull swr.cn-east-3.myhuaweicloud.com/openeuler-embedded/openeuler-embedded:developer-x86_64
docker pull swr.cn-east-3.myhuaweicloud.com/openeuler-embedded/openeuler-embedded:developer-aarch64
# 嵌入式docker镜像
docker pull swr.cn-east-3.myhuaweicloud.com/openeuler-embedded/openeuler-embedded:aarch64
docker pull swr.cn-east-3.myhuaweicloud.com/openeuler-embedded/openeuler-embedded:x86_64
```

#### 5 依赖

1）kiwi >= 9.21

2）docker/chroot/createrepo/xmllint/openssl

#### 6 TODO

截至目前，rpm软件包编译和docker镜像制作能够稳定使用。

下一步将完善：

1）镜像多样化支持，例如虚拟机镜像和嵌入式设备镜像等。

2）rpm构建调度模块，基于自动识别的依赖关系进行所有软件包的正确构建。

3）支持交叉编译

#### 7 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

