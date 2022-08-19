FROM node:lts-bullseye-slim AS build-planet
LABEL stage=tmp

RUN echo "download tools and code..." && \
    apt-get -qq update && \
    apt-get -qq -y install git python3 make curl wget g++ gnupg
RUN mkdir -p /usr/include/nlohmann/ && \
    cd /usr/include/nlohmann/ && \
    wget https://github.com/nlohmann/json/releases/download/v3.10.5/json.hpp
RUN cd /opt && \
    git clone -v https://github.com/zerotier/ZeroTierOne.git --depth 1

RUN echo "install zerotier..." && \
    curl -s https://install.zerotier.com | bash > /dev/null && \
    cd /var/lib/zerotier-one && zerotier-idtool initmoon identity.public >moon.json
ADD ./patch /app/patch
ARG planet
RUN cd /app/patch && \
    python3 patch.py  && \
    cd /var/lib/zerotier-one  && \
    zerotier-idtool genmoon moon.json  && \
    mkdir moons.d  && \
    cp ./*.moon ./moons.d
RUN echo "compile planet..." && \
    cd /opt/ZeroTierOne/attic/world/ && sh build.sh > /dev/null && \
    cd /opt/ZeroTierOne/attic/world/ && ./mkworld > /dev/null && \
    mkdir /app/bin -p && cp world.bin /app/bin/planet && \
    cp /app/bin/planet /var/lib/zerotier-one/planet

FROM node:lts-bullseye-slim
COPY --from=build-planet /var/lib/zerotier-one/ /var/lib/zerotier-one/
COPY --from=build-planet /usr/sbin/zero* /usr/bin/
COPY --from=build-planet /usr/lib/x86_64-linux-gnu/libssl*  /usr/lib/x86_64-linux-gnu/
COPY --from=build-planet /usr/lib/x86_64-linux-gnu/libcrypto*  /usr/lib/x86_64-linux-gnu/
RUN true
COPY --from=dec0dos/zero-ui:latest /app/ /app/
COPY init.sh /
RUN chmod +x /init.sh
EXPOSE 9993/udp
EXPOSE 4000/tcp
ENV NODE_ENV=production
ENV ZU_SERVE_FRONTEND=true
#VOLUME /var/lib/zerotier-one/controller.d /app/backend/data
ENTRYPOINT ["/init.sh"]