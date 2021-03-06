#!/bin/bash
#
# -- Build Apache Spark Standalone Cluster Docker Images

# ----------------------------------------------------------------------------------------------------------------------
# -- Variables ---------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

BUILD_DATE="$(date -u +'%Y-%m-%d')"

SHOULD_BUILD_BASE="$(grep -m 1 build_base build.yml | grep -o -P '(?<=").*(?=")')"
SHOULD_BUILD_SPARK="$(grep -m 1 build_spark build.yml | grep -o -P '(?<=").*(?=")')"
SHOULD_BUILD_JUPYTERLAB="$(grep -m 1 build_jupyter build.yml | grep -o -P '(?<=").*(?=")')"

SCALA_VERSION="$(grep -m 1 scala build.yml | grep -o -P '(?<=").*(?=")')"
SPARK_VERSION="$(grep -m 1 spark build.yml | grep -o -P '(?<=").*(?=")')"
HADOOP_VERSION="$(grep -m 1 hadoop build.yml | grep -o -P '(?<=").*(?=")')"
GRAPHFRAMES_VERSION="$(grep -m 1 graphframes build.yml | grep -o -P '(?<=").*(?=")')"
JUPYTERLAB_VERSION="$(grep -m 1 jupyterlab build.yml | grep -o -P '(?<=").*(?=")')"

# ----------------------------------------------------------------------------------------------------------------------
# -- Functions----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

function cleanContainers() {

    if [[ "${SHOULD_BUILD_JUPYTERLAB}" == "true" ]]
    then
      container="$(docker ps -a | grep 'jupyterlab' | awk '{print $1}')"
      docker stop "${container}"
      docker rm "${container}"
    fi

    if [[ "${SHOULD_BUILD_SPARK}" == "true" ]]
    then

      container="$(docker ps -a | grep 'spark-worker' -m 1 | awk '{print $1}')"
      while [ -n "${container}" ];
      do
        docker stop "${container}"
        docker rm "${container}"
        container="$(docker ps -a | grep 'spark-worker' -m 1 | awk '{print $1}')"
      done

      container="$(docker ps -a | grep 'spark-master' | awk '{print $1}')"
      docker stop "${container}"
      docker rm "${container}"

      container="$(docker ps -a | grep 'spark-base' | awk '{print $1}')"
      docker stop "${container}"
      docker rm "${container}"

    fi

    if [[ "${SHOULD_BUILD_BASE}" == "true" ]]
    then
      container="$(docker ps -a | grep 'base' | awk '{print $1}')"
      docker stop "${container}"
      docker rm "${container}"
    fi

}

function cleanImages() {

    if [[ "${SHOULD_BUILD_JUPYTERLAB}" == "true" ]]
    then
      docker rmi -f "$(docker images | grep -m 1 'jupyterlab' | awk '{print $3}')"
    fi

    if [[ "${SHOULD_BUILD_SPARK}" == "true" ]]
    then
      docker rmi -f "$(docker images | grep -m 1 'spark-worker' | awk '{print $3}')"
      docker rmi -f "$(docker images | grep -m 1 'spark-master' | awk '{print $3}')"
      docker rmi -f "$(docker images | grep -m 1 'spark-base' | awk '{print $3}')"
    fi

    if [[ "${SHOULD_BUILD_BASE}" == "true" ]]
    then
      docker rmi -f "$(docker images | grep -m 1 'base' | awk '{print $3}')"
    fi

}

function cleanVolume() {
  docker volume rm "hadoop-distributed-file-system"
}

function buildImages() {

  if [[ "${SHOULD_BUILD_BASE}" == "true" ]]
  then
    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg scala_version="${SCALA_VERSION}" \
      --build-arg graphframes_version="${GRAPHFRAMES_VERSION}"\
      -f docker/base/Dockerfile \
      -t base:latest .
  fi

  if [[ "${SHOULD_BUILD_SPARK}" == "true" ]]
  then

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg hadoop_version="${HADOOP_VERSION}" \
      --build-arg graphframes_version="${GRAPHFRAMES_VERSION}"\
      -f docker/spark-base/Dockerfile \
      -t spark-base:${SPARK_VERSION}-hadoop-${HADOOP_VERSION} .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg hadoop_version="${HADOOP_VERSION}" \
      --build-arg graphframes_version="${GRAPHFRAMES_VERSION}"\
      -f docker/spark-master/Dockerfile \
      -t spark-master:${SPARK_VERSION}-hadoop-${HADOOP_VERSION} .

    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg hadoop_version="${HADOOP_VERSION}" \
      --build-arg graphframes_version="${GRAPHFRAMES_VERSION}"\
      -f docker/spark-worker/Dockerfile \
      -t spark-worker:${SPARK_VERSION}-hadoop-${HADOOP_VERSION} .

  fi

  if [[ "${SHOULD_BUILD_JUPYTERLAB}" == "true" ]]
  then
    docker build \
      --build-arg build_date="${BUILD_DATE}" \
      --build-arg scala_version="${SCALA_VERSION}" \
      --build-arg spark_version="${SPARK_VERSION}" \
      --build-arg jupyterlab_version="${JUPYTERLAB_VERSION}" \
      -f docker/jupyterlab/Dockerfile \
      -t jupyterlab:${JUPYTERLAB_VERSION}-spark-${SPARK_VERSION} .
  fi

}

# ----------------------------------------------------------------------------------------------------------------------
# -- Main --------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------

cleanContainers;
cleanImages;
cleanVolume;
buildImages;
