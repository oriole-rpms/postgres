#!/bin/bash
set -ex

function _exit() {
  echo "ERROR: $1"
  exit 1
}

function gitinit() {
  LOCALCLONE=$1
  GITORIGIN=$2

  mkdir -p ${LOCALCLONE}
  cd ${LOCALCLONE}
  git init 1>&2
  git remote add origin ${GITORIGIN} 1>&2
}

function gettags() {
  LOCALCLONE=$1

  cd ${LOCALCLONE}
  git ls-remote --tags 2>/dev/null
}

function getlatesttag() {
  LOCALCLONE=$1

  cd ${LOCALCLONE}
  git ls-remote --tags --sort=committerdate 2>/dev/null | tail -n1 | cut -f2
}

function gitshallowclone() {
  LOCALCLONE=$1
  GITTAG=$2
  cd ${LOCALCLONE}
  git pull --depth=1 origin "${GITTAG}"
}

function gitfullclone() {
  LOCALCLONE=$1
  GITORIGIN=$2
  BASE=$(dirname "${LOCALCLONE}")
  mkdir -p $BASE
  cd ${BASE}
  git clone "${GITORIGIN}"
}

function downloadsource() {
  URL=$1
  LOCALSOURCE=/root/rpmbuild/SOURCES/$(basename $URL)
  mkdir -p $(dirname ${LOCALSOURCE})
  curl -L "${URL}" -o "${LOCALSOURCE}"
}

function gen_rpm_macros() {
  PGLOCALCLONE=$1
  PGGITREPO=$2
  PGGITSOURCE=$3

  PGPACKAGEVERSION=$(sed -n "/PACKAGE_VERSION=/{s/.*=//;s/'//g;p}" ${PGLOCALCLONE}/configure)
  #PGPACKAGEVERSION=$(echo ${GITTAG} | grep -oE '[0-9]+_[0-9]+' | sed 's/_/./')
  PGMAJORVERSION=$(echo ${PGPACKAGEVERSION} | grep -oE '^[0-9]+')
  #PGMINORVERSION=$(echo ${GITTAG} | grep -oE '[0-9]+$')
  echo "%pgmajorversion ${PGMAJORVERSION}
  %packageversion ${PGMAJORVERSION}0
  %prevmajorversion $((PGMAJORVERSION-1))
  %url ${PGGITREPO}
  %source0 ${PGGITSOURCE}
  %pgversion ${PGPACKAGEVERSION}" > ~/.rpmmacros
}

grep -E '^(NAME|VERSION)=' /etc/os-release

cd $(dirname $0)
BASEDIR=$PWD

# Postgres
if [[ "${PGVERSION}" =~ ^[0-9+]$ ]]; then
  echo "PGVERSION already set"
else 
  PGVERSION=$(echo "${PGGITTAG}" | grep -o '[0-9]*' | head -n1)
  if [ "${PGGITTAG}" != "" ]; then
    echo "PGVERSION calculated from PGGITTAG"
  else
    echo "PGVERSION defaulted to 16"
    PGVERSION=${PGVERSION:-16}
  fi
fi
echo "PGVERSION: $PGVERSION"
  
PGLOCALCLONE=$(mktemp -d)/postgresql-${PGVERSION}
PGGITORIGIN=${PGGITORIGIN:-https://github.com/orioledb/postgres}
gitinit "${PGLOCALCLONE}" "${PGGITORIGIN}"
if [ "${PGGITTAG}" = "" ]; then 
  PGGITTAG=$(gettags "${PGLOCALCLONE}" | grep "patches${PGVERSION}" | awk '{print $2}' | sort | tail -n1)
fi
if [[ ! "${PGGITTAG}" =~ ^refs/tags/ ]]; then
  PGGITTAG="refs/tags/${PGGITTAG}"
fi

echo "Building RPMs for ${PGGITTAG} from ${PGGITORIGIN}"

gitshallowclone "${PGLOCALCLONE}" "${PGGITTAG}"
PGGITSOURCE=${PGGITORIGIN}/archive/${PGGITTAG}.tar.gz
gen_rpm_macros "${PGLOCALCLONE}" "${PGGITORIGIN}" "${PGGITSOURCE}"
downloadsource "${PGGITSOURCE}"
downloadsource "https://www.postgresql.org/files/documentation/pdf/${PGVERSION}/postgresql-${PGVERSION}-A4.pdf"
cp "${BASEDIR}/sources"/* /root/rpmbuild/SOURCES
