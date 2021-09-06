FROM registry.redhat.io/ubi8/openjdk-11

USER 0

COPY . /tmp/src
RUN chown -R 1001:0 /tmp/src

USER 1001
RUN /usr/local/s2i/assemble
CMD /usr/local/s2i/run
