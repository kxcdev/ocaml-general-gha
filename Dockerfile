ARG ARG
FROM:ghcr.io/kxcinc/ocaml-general:$IMAGE_TAG
COPY main.sh /main.sh
ENTRYPOINT ["/main.sh"]
