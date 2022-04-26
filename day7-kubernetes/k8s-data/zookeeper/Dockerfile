FROM harbor.k8s.com/baseimages/slim_java:8
ENV ZK_VERSION 3.4.14
# 更换镜像仓库
ADD repositories /etc/apk/repositories

# 将zookeeper复制到镜像中
COPY zookeeper-3.4.14.tar.gz /tmp/zk.tgz
COPY zookeeper-3.4.14.tar.gz.asc /tmp/zk.tgz.asc
COPY KEYS /tmp/KEYS

# 安装依赖
RUN apk add --no-cache --virtual .build-deps \
      ca-certificates   \
      gnupg             \
      tar               \
      wget &&           \
    #
    # Install dependencies
    apk add --no-cache  \
      bash &&           \
    #
    #
    # 校验KEY
    export GNUPGHOME="$(mktemp -d)" && \
    gpg -q --batch --import /tmp/KEYS && \
    gpg -q --batch --no-auto-key-retrieve --verify /tmp/zk.tgz.asc /tmp/zk.tgz && \
    #
    # 创建zookeeper安装路径
    #
    mkdir -p /zookeeper/data /zookeeper/wal /zookeeper/log && \
    #
    # 安装zookeeper
    tar -x -C /zookeeper --strip-components=1 --no-same-owner -f /tmp/zk.tgz && \
    #
    # Slim down
    cd /zookeeper && \
    cp dist-maven/zookeeper-${ZK_VERSION}.jar . && \
    rm -rf \
      *.txt \
      *.xml \
      bin/README.txt \
      bin/*.cmd \
      conf/* \
      contrib \
      dist-maven \
      docs \
      lib/*.txt \
      lib/cobertura \
      lib/jdiff \
      recipes \
      src \
      zookeeper-*.asc \
      zookeeper-*.md5 \
      zookeeper-*.sha1 && \
    #
    # 清理安装包
    apk del .build-deps && \
    rm -rf /tmp/* "$GNUPGHOME"

COPY conf /zookeeper/conf/
COPY bin/zkReady.sh /zookeeper/bin/
COPY entrypoint.sh /

ENV PATH=/zookeeper/bin:${PATH} \
    ZOO_LOG_DIR=/zookeeper/log \
    ZOO_LOG4J_PROP="INFO, CONSOLE, ROLLINGFILE" \
    JMXPORT=9010

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "zkServer.sh", "start-foreground" ]


EXPOSE 2181 2888 3888 9010