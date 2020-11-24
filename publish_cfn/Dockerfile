FROM amazon/aws-cli

RUN curl -L -k -s https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 >/usr/bin/jq

COPY . /usr/bin

RUN chmod +x /usr/bin/*


ENTRYPOINT ["/usr/bin/entrypoint.sh"]

