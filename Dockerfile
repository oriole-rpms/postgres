ARG IMAGE=ghcr.io/oriole-rpms/pgbuilder
ARG IMAGETAG
FROM ${IMAGE}:${IMAGETAG}

WORKDIR /

COPY oriolepg/rpms /rpms
RUN createrepo /rpms
COPY oriolepg/oriolepg-local.repo /etc/yum.repos.d
RUN dnf module disable -y postgresql ; \
    dnf install -y /rpms/postgresql*-server-*.rpm /rpms/postgresql*-devel-*.rpm


