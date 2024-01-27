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

function gitshallowclone() {
  LOCALCLONE=$1
  GITTAG=$2
  cd ${LOCALCLONE}
  git pull --depth=1 origin "${GITTAG}"
}

PGVERSION=${1:-16}

PGLOCALCLONE=${2:-~/rpmbuild/BUILD/postgresql-${PGVERSION}}
PGGITORIGIN=${3:-https://github.com/orioledb/postgres}
rm -rf "${PGLOCALCLONE}"
gitinit "${PGLOCALCLONE}" "${PGGITORIGIN}"
PGGITTAG=$(gettags "${PGLOCALCLONE}" | grep "patches${PGVERSION}" | awk '{print $2}' | sort | tail -n1)
gitshallowclone "${PGLOCALCLONE}" "${PGGITTAG}"
