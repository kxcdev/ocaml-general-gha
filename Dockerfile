FROM ghcr.io/kxcinc/ocaml-general:ubuntu.22.04-ocaml.5.0.0-node.hydrogen-amd64
RUN echo `date +%s`
COPY main.sh /main.sh
ENTRYPOINT ["/main.sh"]
