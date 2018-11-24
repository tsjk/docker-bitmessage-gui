Bitmessage GUI inside Docker

```bash
mkdir $HOME/bitmessage-data
docker run -it -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/bitmessage-data:/data -e DISPLAY=unix$DISPLAY jakobvarmose/bitmessage-gui:0.6.3.2
```
