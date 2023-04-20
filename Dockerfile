FROM ubuntu:22.04

WORKDIR /root
# SSH - VIM - JAVA
RUN apt update && apt install -y ssh openssh-server openssh-client vim openjdk-8-jre-headless openjdk-8-jdk
RUN apt update && apt install -y scala git

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

# install hadoop 3.3.0 
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz && \
    mkdir /opt/hadoop && \
    tar -xvzf hadoop-3.3.0.tar.gz -C /opt/hadoop


# set environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
ENV HADOOP_HOME=/opt/hadoop/hadoop-3.3.0
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop


RUN mkdir -p $HADOOP_HOME/dfs/name && \ 
    mkdir -p $HADOOP_HOME/dfs/data && \
    mkdir -p $HADOOP_HOME/dfs/namesecondary && \
    mkdir $HADOOP_HOME/tmp

COPY config/* /tmp/

RUN mv /tmp/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    mv /tmp/yarn-env.sh $HADOOP_HOME/etc/hadoop/yarn-env.sh && \
    mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \ 
    mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    cp /tmp/workers $HADOOP_HOME/etc/hadoop/workers && \
    mv /tmp/start-dfs.sh $HADOOP_HOME/sbin/start-dfs.sh && \
    mv /tmp/start-yarn.sh $HADOOP_HOME/sbin/start-yarn.sh && \
    mv /tmp/stop-dfs.sh $HADOOP_HOME/sbin/stop-dfs.sh && \
    mv /tmp/stop-yarn.sh $HADOOP_HOME/sbin/stop-yarn.sh && \
    mv /tmp/run-wordcount.sh $HADOOP_HOME/sbin/run-wordcount.sh

# -----------------------------------------------------------------------------------------#
# HIVE
RUN wget https://downloads.apache.org/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz && \
    mkdir /opt/hive && \
    tar -xvzf apache-hive-3.1.2-bin.tar.gz -C /opt/hive --strip 1

# set environment variable
ENV HIVE_HOME=/opt/hive
ENV PATH=$SPARK_HOME/bin:$PATH

# Change guava version between Hive and Hadoop
RUN rm $HIVE_HOME/lib/guava-19.0.jar
RUN cp $HADOOP_HOME/share/hadoop/common/lib/guava-27.0-jre.jar $HIVE_HOME/lib/

# RUN echo "HADOOP_HOME=/opt/hadoop/hadoop-3.3.0" >> $HIVE_HOME/bin/hive-config.sh
# RUN cp $HIVE_HOME/lib/hive-common-2.3.9.jar $SQOOP_HOME/lib/
# ADD config/hive-site.xml $HIVE_HOME/conf/

# -----------------------------------------------------------------------------------------#
#SPARK
RUN wget https://archive.apache.org/dist/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz && \
    mkdir /opt/spark && \
    tar -xvzf spark-3.3.0-bin-hadoop3.tgz -C /opt/spark --strip 1

# set environment variable
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$PATH

RUN cp /tmp/workers $SPARK_HOME/conf/workers && \
    mv /tmp/spark-env.sh $SPARK_HOME/conf/spark-env.sh

# --------------------------
ARG FORMAT_NAMENODE_COMMAND
RUN $FORMAT_NAMENODE_COMMAND
RUN mkdir -p /run/sshd
RUN /usr/sbin/sshd
EXPOSE 22
CMD [ "sh", "-c", "service ssh start; bash"]