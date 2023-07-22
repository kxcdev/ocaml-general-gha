FROM ghcr.io/kxcinc/ocaml-general:ubuntu.22.04-ocaml.${TAGA}-node.hydrogen-amd64
COPY main.sh /main.sh
ENTRYPOINT ["/main.sh"]
