#!/bin/sh
################################################################################
#                                                                              #
# sploitctl.sh - fetch, install and search exploit archives from exploit sites #
#                                                                              #
# FILE                                                                         #
# sploitctl.sh                                                                 #
#                                                                              #
# DATE                                                                         #
# 2013-12-04                                                                   #
#                                                                              #
# DESCRIPTION                                                                  #
# Script to fetch, install, update and search exploit archives from well-known #
# sites like packetstormsecurity.org and exploit-db.com.                       #
#                                                                              #
# AUTHORS                                                                      #
# noptrix@nullsecurity.net                                                     #
# teitelmanevan@gmail.com                                                      #
# nrz@nullsecurity.net                                                         #
#                                                                              #
################################################################################


# sploitctl.sh version
VERSION="sploitctl.sh v1.2"

# true / false
FALSE=0
TRUE=1

# return codes
SUCCESS=1337
FAILURE=31337

# verbose mode - default: quiet
VERBOSE="/dev/null"

# debug mode - default: off
DEBUG="/dev/null"

# exploit base directory
EXPLOIT_DIR="/usr/share/exploits"

# link to exploit-db's exploit archive
XPLOITDB_URL="http://www.exploit-db.com/archive.tar.bz2"

# base url for packetstorm
PSTORM_URL="http://dl.packetstormsecurity.com/"

# link to m00 exploits archive
M00_URL="https://github.com/BlackArch/m00-exploits/raw/master/m00-exploits.tar.gz"

# link to lsd-pl exploits archive
LSDPL_URL="https://github.com/BlackArch/lsd-pl-exploits/archive/master.zip"

# clean up, delete downloaded archive files (default: on)
CLEAN=1

# user agent string for curl
USERAGENT="blackarch/${VERSION}"

# browser open url in web search option
BROWSER="firefox"

# default url list for web option
URL_FILE="/usr/share/sploitctl/web/url.lst"


# print error and exit
err()
{
    echo "[-] ERROR: ${@}"
    exit $FAILURE

    return $SUCCESS
}


# print warning
warn()
{
    echo "[!] WARNING: ${@}"

    return $SUCCESS
}


# print verbose message
vmsg()
{
    echo "    -> ${@}"

    return $SUCCESS
}


# print message
msg()
{
    echo "[*] ${@}"

    return $SUCCESS
}


# delete downloaded archive files
clean()
{
    if [ ${CLEAN} -eq 1 ]
    then
        msg "deleting archive files"
        rm -rf ${EXPLOIT_DIR}/{*.tar,*.tgz,*.tar.gz,*.tar.bz2,*zip} \
            > ${DEBUG} 2>&1
    fi

    return $SUCCESS
}


# search exploit(s) for given search pattern in web sites
search_web()
{
    name="${srch_str}"

    msg "searching '${name}'"

    while read -r;
    do
        open_browser "${REPLY}" "${name}"
    done < "${URL_FILE}"

    return "$SUCCESS"
}


# search exploit(s) using given string pattern
search_archive()
{
    local tmpfile="`mktemp`"

    msg "searching exploit for '${srch_str}'"

    if [ -d "${EXPLOIT_DIR}" ]
    then
        for i in `grep -ri --exclude={'*htm*','files.csv'} "${srch_str}" \
            ${EXPLOIT_DIR} | cut -d ':' -f 1 | sort -u`
        do
            printf "%-80s |   " ${i} ; grep -m 1 -i "${srch_str}" ${i}
        done | sort -u
    else
        err "no exploits directory found"
    fi

    return $SUCCESS
}


# open browser for the search
open_browser()
{
    url="${1}"
    name="${2}"

    domain=`printf "%s" "${url}" | sed 's|\(http://[^/]*/\).*|\1|g'`

    vmsg "opening '${domain}' in ${BROWSER}" > ${VERBOSE} 2>&1
    "${BROWSER}" "${url}${name}"

    return $SUCCESS
}


# extract lsd-pl-exploits archives and do changes if necessary
extract_lsdpl()
{
    unzip master.zip > ${DEBUG} 2>&1 ||
      warn "failed to extract lsd-pl-exploits ${f}"

    rm -rf lsd-pl-exploits > ${DEBUG} 2>&1
    mv lsd-pl-exploits-master lsd-pl-exploits > ${DEBUG} 2>&1

    cd lsd-pl-exploits > ${DEBUG} 2>&1
    for zip in *.zip
    do
        unzip ${zip} > ${DEBUG} 2>&1
        rm -rf ${zip} > ${DEBUG} 2>&1
    done

    return $SUCCESS
}


# extract m00-exploits archives and do changes if necessary
extract_m00()
{
    tar xfvz m00-exploits.tar.gz > ${DEBUG} 2>&1 ||
      warn "failed to extract m00-exploits ${f}"

    return $SUCCESS
}


# extract packetstorm archives and do changes if necessary
extract_pstorm()
{
    for f in *.tgz
    do
        vmsg "extracting ${f}" > ${VERBOSE} 2>&1
        tar xfvz ${f} -C "${pstorm_dir}/" > ${DEBUG} 2>&1 ||
            warn "failed to extract packetstorm ${f}"
    done

    return $SUCCESS
}


# extract exploit-db archive and do changes if necessary
extract_xploitdb()
{
    return $SUCCESS
}


# extract exploit archives
extract()
{
    msg "extracting exploit archives"

    case $site in
        0)
            extract_xploitdb
            extract_pstorm
            extract_m00
            extract_lsdpl
            ;;
        1)
            vmsg "extracting exploit-db archives" > ${VERBOSE} 2>&1
            extract_xploitdb
            ;;
        2)
            vmsg "extracting packetstorm archives" > ${VERBOSE} 2>&1
            extract_pstorm
            ;;
        3)
            vmsg "extracting m00-exploits archives" > ${VERBOSE} 2>&1
            extract_m00
            ;;
        4)
            vmsg "extracting lsd-pl-exploits archives" > ${VERBOSE} 2>&1
            extract_lsdpl
            ;;

    esac

    return $SUCCESS
}


# fix file permissions
fix_perms()
{
    msg "fixing permissions"

    find ${EXPLOIT_DIR} -type d -exec chmod 755 {} \; > ${DEBUG} 2>&1
    find ${EXPLOIT_DIR} -type f -exec chmod 644 {} \; > ${DEBUG} 2>&1

    return $SUCCESS
}


# download lsd-pl exploit archives from our github repository
fetch_lsdpl()
{
    vmsg "downloading lsd-pl-exploits" > ${VERBOSE} 2>&1

    curl -# -A "${USERAGENT}" -L -O ${LSDPL_URL} > ${DEBUG} 2>&1 ||
        err "failed to download lsd-pl-exploits"

    return $SUCCESS
}


# download m00 exploit archives from our github repository. some greets here to
# crash-x darkeagle and my old homies :(
fetch_m00()
{
    vmsg "downloading m00-exploits" > ${VERBOSE} 2>&1

    curl -# -A "${USERAGENT}" -L -O ${M00_URL} > ${DEBUG} 2>&1 ||
        err "failed to download m00-exploits"

    return $SUCCESS
}


# download exploit archives from packetstorm
# TODO: dirty hack here. make it better
fetch_pstorm()
{
    # enough for the next 90 years ;)
    cur_year=`date +%Y | sed 's/.*20//'`
    y=0

    vmsg "downloading archives from packetstorm" > ${VERBOSE} 2>&1

    while [ $y -le $cur_year ]
    do
        for m in {1..12}
        do
            if [ $y -lt 10 ]
            then
                year="0$y"
            else
                year="$y"
            fi
            if [ $m -lt 10 ]
            then
                month="0$m"
            else
                month="$m"
            fi
            vmsg "downloading $year$month-exploits.tgz" > ${VERBOSE} 2>&1
            curl -# -A "${USERAGENT}" -O \
                "${PSTORM_URL}/${year}${month}-exploits/${year}${month}-exploits.tgz" \
                > ${DEBUG} 2>&1 || err "failed to download packetstorm"
        done
        y=`expr $y + 1`
    done

    return $SUCCESS
}


# download exploit archives from exploit-db
fetch_xploitdb()
{
    vmsg "downloading archive from exploit-db" > ${VERBOSE} 2>&1

    if [ ! -f "${xploitdb_dir}/files.csv" ]
    then
        git clone https://github.com/offensive-security/exploit-database.git \
            exploit-db > ${DEBUG} 2>&1
    else
        cd ${xploitdb_dir}
        git pull > ${DEBUG} 2>&1
        cd ..
    fi

    return $SUCCESS
}


# download exploit archives from chosen sites
fetch()
{
    msg "downloading exploit archives"

    if [ $site -eq 0 -o $site -eq 1 ]
    then
        fetch_xploitdb
    fi
    if [ $site -eq 0 -o $site -eq 2 ]
    then
        fetch_pstorm
    fi
    if [ $site -eq 0 -o $site -eq 3 ]
    then
        fetch_m00
    fi
    if [ $site -eq 0 -o $site -eq 4 ]
    then
        fetch_lsdpl
    fi

    return $SUCCESS
}


# define and create exploit dirs for each site
make_exploit_dirs()
{
    xploitdb_dir="${EXPLOIT_DIR}/exploit-db"
    pstorm_dir="${EXPLOIT_DIR}/packetstorm"
    m00_dir="${EXPLOIT_DIR}/m00-exploits"
    lsdpl_dir="${EXPLOIT_DIR}/lsd-pl-exploits"

    if [ ! -d ${EXPLOIT_DIR} ]
    then
        if ! mkdir ${EXPLOIT_DIR} > ${DEBUG} 2>&1
        then
            err "failed to create ${EXPLOIT_DIR}"
        fi
    fi
    if [ ! -d ${xploitdb_dir} ]
    then
         mkdir ${xploitdb_dir} > ${DEBUG} 2>&1 ||
            err "failed to create ${xploitdb_dir}"
    fi
    if [ ! -d ${pstorm_dir} ]
    then
         mkdir ${pstorm_dir} > ${DEBUG} 2>&1 ||
            err "failed to create ${pstorm_dir}"
    fi
    if [ ! -d ${m00_dir} ]
    then
         mkdir ${m00_dir} > ${DEBUG} 2>&1 ||
            err "failed to create ${m00_dir}"
    fi
    if [ ! -d ${lsdpl_dir} ]
    then
         mkdir ${lsdpl_dir} > ${DEBUG} 2>&1 ||
            err "failed to create ${lsdpl_dir}"
    fi

    cd "${EXPLOIT_DIR}"

    return $SUCCESS
}


# checks for old exploit dir: /var/exploits
check_old_expl_dir()
{
    if [ -d "/var/exploits" ]
    then
        warn "old directory \"/var/exploits\" exists!"
        printf "    -> delete old directory? [y/N]: "
        read answer
        if [ "${answer}" = "y" ]
        then
            vmsg "deleting \"/var/exploits\" ..." > ${VERBOSE} 2>&1
            rm -rf "/var/exploits"
        else
            return $SUCCESS
        fi
    fi

    return $SUCCESS
}


# usage and help
usage()
{
    echo "usage:"
    echo ""
    echo "  sploitctl.sh -f <arg> | -s <arg> [options] | <misc>"
    echo ""
    echo "options:"
    echo ""
    echo "  -f <num>    - download and extract exploit archives from chosen"
    echo "                websites (default: all) - ? to list sites"
    echo "  -s <str>    - exploit to search using <str> in ${EXPLOIT_DIR}"
    echo "  -w <str>    - exploit to search in web exploit site"
    echo "  -e <dir>    - exploits base directory (default: /usr/share/exploits)"
    echo "  -b <url>    - give a new base url for packetstorm"
    echo "                (default: http://dl.packetstormsecurity.com/)"
    echo "  -l <file>   - give a new base path/file for website list option"
    echo "                (default: /usr/share/sploitctl/web/url.lst)"
    echo "  -c          - do not delete downloaded archive files"
    echo "  -v          - verbose mode (default: off)"
    echo "  -d          - debug mode (default: off)"
    echo ""
    echo "misc:"
    echo ""
    echo "  -V      - print version of packetstorm and exit"
    echo "  -H      - print this help and exit"

    exit $SUCCESS

    return $SUCCESS
}


# leet banner, very important
banner()
{
    echo "--==[ sploitctl.sh by blackarch.org ]==--"
    echo

    return $SUCCESS
}


# check chosen website
check_site()
{
    if [ "${site}" = "?" ]
    then
        msg "available exploit sites"
        vmsg "0 - all exploit sites (default)"
        vmsg "1 - exploit-db.com"
        vmsg "2 - packetstormsecurity.org"
        vmsg "3 - m00-exploits"
        vmsg "4 - lsd-pl-exploits"
        exit $SUCCESS
    elif [ $site -lt 0 -o $site -gt 4 ]
    then
        err "unknown exploit site"
    fi

    return $SUCCESS
}


# check argument count
check_argc()
{
    if [ ${#} -lt 1 ]
    then
        err "-H for help and usage"
    fi

    return $SUCCESS
}


# check if requimsg arguments were selected
check_args()
{
    msg "checking arguments"

    if [ -z "${job}" ]
    then
        err "choose -f, -u or -s"
    fi

    if [ "${job}" = "search_web" ] && [ ! -f "${URL_FILE}" ]
    then
        err "failed to get url file for web searching - try -l <file>"
    fi

    return $SUCCESS
}


# parse command line options
get_opts()
{
    while getopts f:s:w:e:b:l:cvdVH flags
    do
        case ${flags} in
            f)
                site=${OPTARG}
                job="fetch"
                check_site
                ;;
            s)
                srch_str="${OPTARG}"
                job="search_archive"
                ;;
            w)
                srch_str="${OPTARG}"
                job="search_web"
                ;;
            e)
                EXPLOIT_DIR="${OPTARG}"
                ;;
            b)
                PSTORM_URL="${OPTARG}"
                ;;
            l)
                URL_FILE="${OPTARG}"
                ;;
            c)
                CLEAN=0
                ;;
            v)
                VERBOSE="/dev/stdout"
                ;;
            d)
                DEBUG="/dev/stdout"
                ;;
            V)
                echo "${VERSION}"
                exit $SUCCESS
                ;;
            H)
                usage
                ;;
            *)
                err "WTF?! mount /dev/brain"
                ;;
        esac
    done

    return $SUCCESS
}


# controller and program flow
main()
{
    banner
    check_argc "${@}"
    get_opts "${@}"
    check_args "${@}"

    if [ "${job}" = "fetch" ]
    then
        check_old_expl_dir
        make_exploit_dirs
        fetch
        extract
        fix_perms
        clean
    elif [ "${job}" = "search_archive" ]
    then
        search_archive
    elif [ "${job}" = "search_web" ]
    then
        search_web
    else
        err "WTF?! mount /dev/brain"
    fi

    msg "game over"

    return $SUCCESS
}


# program start
main "${@}"


# EOF
