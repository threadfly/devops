#FROM f5b454ae5954
FROM c5b01a078265
MAINTAINER rick.wu@threadfly.cn

COPY templates/ /root/templates/
COPY run.sh /root/

RUN chmod 755 /root/run.sh
COPY bin/ /root/bin/
WORKDIR /root
