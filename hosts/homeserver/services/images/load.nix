# ExecStartPre helper: make an image from ./ available to podman.
#
# Not oci-containers' `imageStream`/`imageFile`, whose preStart pipes the whole
# image into `podman load` on every single start — 44s for qbittorrent, whose
# closure is ~1GB, even with every layer already in storage. The tag is the
# image's content hash, so its presence means it's current.
#
# The second half drops the tags a rebuild superseded, which would otherwise
# pile up at ~1GB each. It removes by `repository:tag` rather than by image ID:
# an ID may carry several tags, and `podman rmi -f` on one would take the others
# with it. Note `podman images --filter reference=` is no help here — it matches
# far more than the name given.
{ pkgs }:
image:
let
  ref = "${image.imageName}:${image.imageTag}";
in
pkgs.writeShellScript "load-${image.imageName}" ''
  export PATH=${
    pkgs.lib.makeBinPath [
      pkgs.findutils
      pkgs.gawk
      pkgs.podman
    ]
  }
  podman image exists ${ref} || ${image} | podman load

  podman images --format '{{.Repository}}:{{.Tag}} {{.Repository}} {{.Tag}}' |
      awk -v n=${image.imageName} -v t=${image.imageTag} \
          '($2 == n || $2 == "localhost/" n) && $3 != t {print $1}' |
      xargs -r -n1 podman rmi || true
''
