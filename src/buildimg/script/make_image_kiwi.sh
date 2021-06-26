#!/bin/sh

function kiwi_init()
{
    local repofile=${REPO_FILE}
    
    local kiwirpm="python3-kiwi skopeo umoci"
    which kiwi &> /dev/null || dnf install -y $kiwirpm -c "${repofile}" $(sed -n "s@name=@--repo @pg" $repofile)
    [[ "x$(umask)" != "x0022" ]] && umask 0022g

    return 0
}

function repofile2str()
{
    local tmprepo=$1

    local dnfstr=$(dnf config-manager --dump-variables | sed -n 's@ = @=@pg')
    for dnfvar in $dnfstr
    do
        local varname=${dnfvar%%=*}
        local varval=${dnfvar##*=}
        sed -i "s@\$${varname}@${varval}@g" $tmprepo
    done
    unset dnfvar

    urlarr=$(sed -n 's@baseurl=@@p' $tmprepo)
    priori=$(sed -n 's@priority=@@p' $tmprepo)
    local repostr=""
    for cnt in $(seq 1 $(cat $tmprepo | grep 'baseurl=' | wc -l))
    do
        local tmpurl=$(echo $urlarr | cut -d ' ' -f $cnt)
        local tmppri=$(echo $priori | cut -d ' ' -f $cnt)
        [[ -d $tmpurl ]] && local tmpurl="dir:$tmpurl"
        local repostr="$repostr --add-repo=$tmpurl --add-repopriority=$tmppri --add-repotype=rpm-md"
    done
    echo $repostr
}

function make_image_kiwi()
{
    local confpath=$KIWI_CONFIG
    local workdir=${WORK_DIR}
    local repofile=$REPO_FILE
    local proftype=$PROFILE_TYPE

    local imgdir=${workdir}/image
    local cfgdir=${workdir}/kiwiconfig
    [[ -d $imgdir ]] && rm -rf $imgdir
    mkdir -p $imgdir
    [[ -d $cfgdir ]] && rm -rf $cfgdir
    mkdir -p $cfgdir

    local passwdfile=$imgdir/password.txt
    local tmprepo=${workdir}/$(basename $repofile).bak

    kiwi_init

    cp $repofile $tmprepo
    cp "$confpath"/config.xml "${cfgdir}"/
    cp "$confpath"/images.sh "${cfgdir}"/

    passwdstr=$(openssl rand -base64 12)
    sed -i "s@password=\"\([^\"]\+\)\" @password=\"$passwdstr\" @g" "${cfgdir}"/config.xml
    echo $passwdstr > $passwdfile

    local repostr=$(repofile2str $tmprepo)
    rm -f $tmprepo
    kiwicompat --build "${cfgdir}" -d "${imgdir}" --add-profile $proftype $repostr
    if [ $? -ne 0 ]; then
        log_error "failed on kiwi build docker image" &> /dev/null
    fi
}

