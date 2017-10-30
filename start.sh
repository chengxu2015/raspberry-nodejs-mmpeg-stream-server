node websocket-relay.js supersecret 8081 8082 \
& http-server \
& ffmpeg -f avfoundation -video_size 1280x720 -framerate 30 -i "0:0" \
-f mpegts -codec:v mpeg1video -s 1280x720 -b:v 1000k -bf 0 \
http://localhost:8081/supersecret