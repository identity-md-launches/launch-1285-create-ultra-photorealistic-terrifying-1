#!/usr/bin/env bash
set -euo pipefail

# This build uses a local static encoder when the workspace does not provide ffmpeg.
FFMPEG_BIN="${FFMPEG_BIN:-/tmp/imd-ffmpeg/ffmpeg}"
mkdir -p artifacts

"$FFMPEG_BIN" -y \
  -f lavfi -t 2 -i "color=c=black:s=3840x2160:r=30" \
  -loop 1 -framerate 30 -t 0.55 -i assets/generated/red_moon_observer.png \
  -loop 1 -framerate 30 -t 0.75 -i assets/generated/bedroom_signal.png \
  -loop 1 -framerate 30 -t 0.55 -i assets/generated/red_moon_observer.png \
  -loop 1 -framerate 30 -t 0.75 -i assets/generated/bedroom_signal.png \
  -loop 1 -framerate 30 -t 0.40 -i assets/generated/red_moon_observer.png \
  -loop 1 -framerate 30 -t 3 -i assets/generated/ships_over_suburbia.png \
  -loop 1 -framerate 30 -t 1 -i assets/generated/alien_face.png \
  -loop 1 -framerate 30 -t 1 -i assets/generated/title_card.png \
  -i test/scratch/whisper1.wav \
  -i test/scratch/whisper2.wav \
  -f lavfi -t 10 -i "anoisesrc=color=pink:sample_rate=48000:amplitude=0.26" \
  -f lavfi -t 10 -i "sine=frequency=38:sample_rate=48000" \
  -f lavfi -t 10 -i "sine=frequency=116:sample_rate=48000" \
  -filter_complex "
    [0:v]format=yuv420p[v0];
    [1:v]scale=4450:2506,crop=3840:2160:x='(in_w-out_w)/2+45*sin(t*6)':y='(in_h-out_h)/2',eq=contrast=1.18:saturation=0.72,vignette=PI/5,format=yuv420p[v1];
    [2:v]scale=4350:2447,crop=3840:2160:x='(in_w-out_w)/2-30*sin(t*9)':y='(in_h-out_h)/2',eq=contrast=1.22:saturation=0.63:brightness='0.025*sin(t*35)',vignette=PI/5,format=yuv420p[v2];
    [3:v]scale=4560:2564,crop=3840:2160:x='(in_w-out_w)/2+60*sin(t*8)':y='(in_h-out_h)/2',eq=contrast=1.24:saturation=0.70,vignette=PI/5,format=yuv420p[v3];
    [4:v]scale=4480:2520,crop=3840:2160:x='(in_w-out_w)/2+50*sin(t*10)':y='(in_h-out_h)/2',eq=contrast=1.25:saturation=0.60:brightness='0.035*sin(t*42)',vignette=PI/5,format=yuv420p[v4];
    [5:v]scale=4700:2644,crop=3840:2160:x='(in_w-out_w)/2+110*sin(t*14)':y='(in_h-out_h)/2',eq=contrast=1.30:saturation=0.65,vignette=PI/5,format=yuv420p[v5];
    [6:v]scale=4250:2391,crop=3840:2160:x='(in_w-out_w)/2+90*sin(t*1.4)':y='(in_h-out_h)/2+20*sin(t*1.8)',eq=contrast=1.18:saturation=0.65,vignette=PI/5,format=yuv420p[v6];
    [7:v]scale=4420:2486,crop=3840:2160:x='(in_w-out_w)/2+160*sin(t*11)':y='(in_h-out_h)/2+50*sin(t*13)',eq=contrast=1.42:saturation=0.42:brightness='0.04*sin(t*33)',vignette=PI/4,format=yuv420p[v7];
    [8:v]format=yuv420p[v8];
    [v0][v1][v2][v3][v4][v5][v6][v7][v8]concat=n=9:v=1:a=0[video];
    [9:a]highpass=f=650,lowpass=f=3600,aecho=0.8:0.55:75:0.20,volume=0.9,adelay=360|360[s1];
    [10:a]highpass=f=500,lowpass=f=3200,aecho=0.8:0.6:90:0.22,volume=0.82,adelay=6800|6800[s2];
    [11:a]highpass=f=680,lowpass=f=7000,volume=0.12[static];
    [12:a]lowpass=f=120,volume=0.48[rumble];
    [13:a]volume='if(between(t,8,9),0.23,0.025)'[tone];
    [static][rumble][tone][s1][s2]amix=inputs=5:duration=longest:normalize=0,alimiter=limit=0.88[audio]" \
  -map "[video]" -map "[audio]" -t 10 \
  -c:v libx264 -preset fast -crf 24 -pix_fmt yuv420p -profile:v high -level 5.1 \
  -c:a aac -b:a 192k -ar 48000 -ac 2 -movflags +faststart \
  artifacts/video.mp4
