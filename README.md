# Raspberry Pi Live Webcam

For this example, ffmpeg and the WebSocket relay run on the same system. This allows you to view the stream in your local network, but not on the public internet.

This example assumes that your webcam is compatible with Video4Linux2 and appears as `/dev/video0` in the filesystem. Most USB webcams support the UVC standard and should work just fine. The onboard Raspberry Camera can be made available as V4L2 device by loading a kernel module: `sudo modprobe bcm2835-v4l2`.


1) Install ffmpeg  
cd /usr/src  
git clone git://git.videolan.org/x264  
cd x264   
./configure --enable-shared --enable-static --enable-strip --disable-cli  

sudo make -j4  
sudo make install  
sudo make clean  
sudo make distclean 

cd /usr/src  
git clone https://github.com/FFmpeg/FFmpeg.git  
cd ffmpeg  
sudo ./configure --arch=armel --target-os=linux --enable-gpl --enable-libx264 --enable-nonfree --enable-shared  
sudo make -j4  
sudo make install  
sudo make distclean  

It may take more than half an hour  

add /usr/local/ffmpeg/lib into /etc/ld.so.conf  

add export PATH="/usr/local/ffmpeg/bin:$PATH" into /etc/profile  

ffmpeg -version
If you get some information of version, you install ffmpeg successfully 


2) Install Node.js and npm (See [Installing Node.js on Debian and Ubuntu based Linux distributions](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions) for newer versions). The Websocket relay is written in Node.js

3) Install http-server. We will use this to serve the static files (view-stream.html, jsmpeg.min.js), so that we can view the website with the video in our browser. Any other webserver would work as well (nginx, apache, etc.):
`sudo npm -g install http-server`

4) Install git and clone this repository (or just download it as ZIP and unpack)
```
sudo apt-get install git
git clone https://github.com/phoboslab/jsmpeg.git
```

5) Change into the jsmpeg/ directory
`cd jsmpeg/`

6) Install the Node.js Websocket Library:
`npm install ws`

7) Start the Websocket relay. Provide a password and a port for the incomming HTTP video stream and a Websocket port that we can connect to in the browser:
`node websocket-relay.js supersecret 8081 8082`

8) In a new terminal window (still in the `jsmpeg/` directory, start the `http-server` so we can serve the view-stream.html to the browser:
`http-server`

9) Open the streaming website in your browser. The `http-server` will tell you the ip (usually `192.168.[...]`) and port (usually `8080`) where it's running on:
`http://192.168.[...]:8080/view-stream.html`

10) In a third terminal window, start ffmpeg to capture the webcam video and send it to the Websocket relay. Provide the password and port (from step 7) in the destination URL:
```
ffmpeg \
	-f v4l2 \
		-framerate 25 -video_size 640x480 -i /dev/video0 \
	-f mpegts \
		-codec:v mpeg1video -s 640x480 -b:v 1000k -bf 0 \
	http://localhost:8081/supersecret
```

You should now see a live webcam image in your browser. 

If ffmpeg failed to open the input video, it's likely that your webcam does not support the given resolution, format or framerate. To get a list of compatible modes run:

`ffmpeg -f v4l2 -list_formats all -i /dev/video0`


To add the webcam audio, just call ffmpeg with two separate inputs.

```
ffmpeg \
	-f v4l2 \
		-framerate 25 -video_size 640x480 -i /dev/video0 \
	-f alsa \
		-ar 44100 -c 2 -i hw:0 \
	-f mpegts \
		-codec:v mpeg1video -s 640x480 -b:v 1000k -bf 0 \
		-codec:a mp2 -b:a 128k \
		-muxdelay 0.001 \
	http://localhost:8081/supersecret
```

Note the `muxdelay` argument. This should reduce lag, but doesn't always work when streaming video and audio - see remarks below.

## start rtmp server  
ffmpeg -f avfoundation -video_size 640x480 -framerate 30 -i "0:0" -vcodec libx264 -preset veryfast -f flv rtmp://localhost:1935/hls/movie


# JSMpeg – MPEG1 Video & MP2 Audio Decoder in JavaScript
 

### list device
ffmpeg -f avfoundation -list_devices true -i ""  
(This command is for Mac)

### take a video
ffmpeg -f avfoundation -video_size 640x480 -framerate 30 -i "0:0" out.avi  
(This command is for Mac)  

"0:0" : "your camera : you microphone"


JSMpeg is a Video Player written in JavaScript. It consists of an MPEG-TS demuxer, MPEG1 video & MP2 audio decoders, WebGL & Canvas2D renderers and WebAudio sound output. JSMpeg can load static videos via Ajax and allows low latency streaming (~50ms) via WebSockets.

JSMpeg can decode 720p Video at 30fps on an iPhone 5S, works in any modern browser (Chrome, Firefox, Safari, Edge) and comes in at just 20kb gzipped.

Using it can be as simple as this:
```html
<script src="jsmpeg.min.js"></script>
<div class="jsmpeg" data-url="video.ts"></div>
```

Some more info and demos: [jsmpeg.com](http://jsmpeg.com/)


## Usage

A JSMpeg video player can either be created in HTML using the CSS class `jsmpeg` for the container:

```html
<div class="jsmpeg" data-url="<url>"></div>
```

or by directly calling the `JSMpeg.Player()` constructor in JavaScript:

```javascript
var player = new JSMpeg.Player(url [, options]);
```

Note that using the HTML Element (internally `JSMpeg.VideoElement`) provides some features on top of `JSMpeg.Player`. Namely a SVG pause/play button and the ability to "unlock" audio on iOS devices.

The `url` argument accepts a URL to an MPEG .ts file or a WebSocket server (ws://...).

The `options` argument supports the following properties:

- `canvas` – the HTML Canvas elment to use for video rendering. If none is given, the renderer will create its own Canvas element.
- `loop` – whether to loop the video (static files only). Default `true`.
- `autoplay` - whether to start playing immediately (static files only). Default `false`.
- `audio` - whether to decode audio. Default `true`.
- `video` - whether to decode video. Default `true`.
- `poster` – URL to an image to use as the poster to show before the video plays.
- `pauseWhenHidden` – whether to pause playback when the tab is inactive. Default `true`. Note that browsers usually throttle JS in inactive tabs anyway.
- `disableGl` - whether to disable WebGL and always use the Canvas2D renderer. Default `false`.
- `preserveDrawingBuffer` – whether the WebGL context is created with `preserveDrawingBuffer` - necessary for "screenshots" via `canvas.toDataURL()`. Default `false`.
- `progressive` - whether to load data in chunks (static files only). When enabled, playback can begin before the whole source has been completely loaded. Default `true`.
- `throttled` - when using `progressive`, whether to defer loading chunks when they're not needed for playback yet. Default `true`.
- `chunkSize` - when using `progressive`, the chunk size in bytes to load at a time. Default `1024*1024` (1mb).
- `decodeFirstFrame` - whether to decode and display the first frame of the video. Useful to set up the Canvas size and use the frame as the "poster" image. This has no effect when using `autoplay` or streaming sources. Default `true`.
- `maxAudioLag` – when streaming, the maximum enqueued audio length in seconds.
- `videoBufferSize` – when streaming, size in bytes for the video decode buffer. Default 512*1024 (512kb). You may have to increase this for very high bitrates.
- `audioBufferSize` – when streaming, size in bytes for the audio decode buffer. Default 128*1024 (128kb). You may have to increase this for very high bitrates.

All options except from `canvas` can also be used with the HTML Element through `data-` attributes. E.g. to specify looping and autoplay in JavaScript:

```javascript
var player = new JSMpeg.Player('video.ts' {loop: true, autoplay: true});
```

or HTML
```html
<div class="jsmpeg" data-url="video.ts" 
	data-loop="true" data-autoplay="true"></div>
```

Note that `camelCased` options have to be hyphenated when used as data attributes. E.g. `decodeFirstFrame: true` becomes `data-decode-first-frame="true"` for the HTML element.


## JSMpeg.Player API

A `JSMpeg.Player` instance supports the following methods and properties:

- `.play()` – start playback
- `.pause()` – pause playback
- `.stop()` – stop playback and seek to the beginning
- `.destroy()` – stops playback, disconnects the source and cleans up WebGL and WebAudio state. The player can not be used afterwards.
- `.volume` – get or set the audio volume (0-1)
- `.currentTime` – get or set the current playback position in seconds


## Encoding Video/Audio for JSMpeg

JSMpeg only supports playback of MPEG-TS containers with the MPEG1 Video Codec and the MP2 Audio Codec. The Video Decoder does not handle B-Frames correctly (though no modern encoder seems to use these by default anyway) and the width of the video has to be a multiple of 2.

You can encode a suitable video using [ffmpeg](https://ffmpeg.org/) like this:

```sh
ffmpeg -i in.mp4 -f mpegts -codec:v mpeg1video -codec:a mp2 -b 0 out.ts
```

You can also control the video size (`-s`), framerate (`-r`), video bitrate (`-b:v`), audio bitrate (`-b:a`), number of audio channels (`-ac`), sampling rate (`-ar`) and much more. Please refer to the ffmpeg documentation for the details.

Comprehensive example:
```sh
ffmpeg -i in.mp4 -f mpegts \
	-codec:v mpeg1video -s 960x540 -b:v 1500k -r 30 -bf 0 \
	-codec:a mp2 -ar 44100 -ac 1 -b:a 128k \
	out.ts
```


## Performance Considerations

While JSMpeg can handle 720p video at 30fps even on an iPhone 5S, keep in mind that MPEG1 is not as efficient as modern codecs. MPEG1 needs quite a bit of bandwidth for HD video. 720p begins to look okay-ish at 2 Mbits/s (that's 250kb/s). Also, the higher the bitrate, the more work JavaScript has to do to decode it.

This should not be a problem for static files, or if you're only streaming within your local WiFi. If you don't need to support mobile devices, 1080p at 10mbit/s works just fine (if your encoder can keep up). For everything else I would advise you to use 540p (960x540) at 2Mbit/s max.


## Streaming via WebSockets

JSMpeg can connect to a WebSocket server that sends out binary MPEG-TS data. When streaming, JSMpeg tries to keep latency as low as possible - it immediately decodes everything it has, ignoring video and audio timestamps altogether. To keep everything in sync (and latency low), audio data should be interleaved between video frames very frequently (`-muxdelay` in ffmpeg).

A separate, buffered streaming mode, where JSMpeg pre-loads a few seconds of data and presents everything with exact timing and audio/video sync is conceivable, but currently not implemented.

The internal buffers for video and audio are fairly small (512kb and 128kb respectively) and JSMpeg will discard old (even unplayed) data to make room for newly arriving data without much fuzz. This could introduce decoding artifacts when there's a network congestion, but ensures that latency is kept at a minimum. If necessary You can increase the `videoBufferSize` and `audioBufferSize` through the options.

JSMpeg comes with a tiny WebSocket "relay", written in Node.js. This server accepts an MPEG-TS source over HTTP and serves it via WebSocket to all connecting Browsers. The incoming HTTP stream can be generated using [ffmpeg](https://ffmpeg.org/), [gstreamer](https://gstreamer.freedesktop.org/) or by other means.

The split between the source and the WebSocket relay is necessary, because ffmpeg doesn't speak the WebSocket protocol. However, this split also allows you to install the WebSocket relay on a public server and share your stream on the Internet (typically NAT in your router prevents the public Internet from connecting _into_ your local network).

In short, it works like this:

1. run the websocket-relay.js
2. run ffmpeg, send output to the relay's HTTP port
3. connect JSMpeg in the browser to the relay's Websocket port


