#### 介绍

根据配置文件中指定的仓库、分支，以及patch目录下的相应补丁，编译得到裁减后的rpm包。

原理是：

1）根据配置文件中的仓库地址、分支名，下软件包仓库代码，将对应的patch加载到仓库。

2）使用工具makerootfs制作包含有dnf/rpm-build/gcc等软件包及其依赖可用于编译的基础镜像baseroot（可指定）。

3）在baseroot容器中安装软件包spec文件的编译依赖，进行第一次软件包编译。

4）编译所得rpm包存放在工作目录的rpms下，该目录也会作为第二次编译的依赖包下载源

5）进行第二次编译，第二次编译的原因是，为了确保存在相互依赖的软件包能够相互更新

#### 使用方式

入口：build.sh

```
Usage: ./buildrpm.sh -a [aarch64|x86_64] -r [repo] -d [work dir] -j [max parallel] -t [image name]
```

#### 依赖

编译过程需用到docker/chroot/createrepo/xmllint，请确保这几个工具已安装

