# alpine-mp4box

This image provides statically linked `mp4box` and `mp4decrypt` binaries for
`linux/amd64` and `linux/arm64`. The default entrypoint remains `mp4box`.

Copy `mp4decrypt` and its bundled license and source files into a consuming image:

```dockerfile
COPY --from=ghcr.io/arabcoders/alpine-mp4box /usr/bin/mp4decrypt /usr/bin/mp4decrypt
COPY --from=ghcr.io/arabcoders/alpine-mp4box /usr/share/doc/bento4/ /usr/share/doc/bento4/
```

To process a file with your content key, replace `KID:KEY` with its hexadecimal key ID and key:

```sh
docker run --rm --entrypoint mp4decrypt -v "$PWD:/work" ghcr.io/arabcoders/alpine-mp4box \
  --key KID:KEY /work/input.mp4 /work/output.mp4
```
