import React, { useEffect, useRef } from 'react';
import Hls from 'hls.js';

interface VideoMediaProps {
  src: string;
  className?: string;
  autoPlay?: boolean;
  loop?: boolean;
  muted?: boolean;
  playsInline?: boolean;
  controls?: boolean;
  poster?: string;
}

export function isVideoUrl(url?: string): boolean {
  if (!url) return false;
  const lower = url.toLowerCase();
  return (
    lower.includes('.mp4') ||
    lower.includes('.webm') ||
    lower.includes('.m3u8') ||
    lower.includes('.mov') ||
    lower.includes('.ogg') ||
    lower.includes('/hls/') ||
    lower.includes('m3u8')
  );
}

export const VideoMedia: React.FC<VideoMediaProps> = ({
  src,
  className = "w-full h-full object-cover",
  autoPlay = true,
  loop = true,
  muted = true,
  playsInline = true,
  controls = false,
  poster,
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video || !src) return;

    let hls: Hls | null = null;
    const lowerSrc = src.toLowerCase();
    const isM3u8 = lowerSrc.includes('m3u8');
    const isExternal = src.startsWith('http://') || src.startsWith('https://');

    // External m3u8 URLs often fail due to CORS (e.g. pinimg.com, external CDNs)
    // We automatically use our server proxy endpoint to bypass CORS and stream m3u8 manifests & ts chunks
    const initialSrc = (isM3u8 && isExternal) ? `/api/proxy-media?url=${encodeURIComponent(src)}` : src;

    const setupPlayer = (mediaSrc: string) => {
      if (hls) {
        hls.destroy();
        hls = null;
      }

      if (isM3u8) {
        if (Hls.isSupported()) {
          hls = new Hls({
            enableWorker: true,
            lowLatencyMode: true,
            fragLoadingTimeOut: 20000,
            manifestLoadingTimeOut: 20000,
          });
          hls.loadSource(mediaSrc);
          hls.attachMedia(video);
          hls.on(Hls.Events.MANIFEST_PARSED, () => {
            if (autoPlay) {
              video.play().catch(() => {});
            }
          });
          hls.on(Hls.Events.ERROR, (_event, data) => {
            if (data.fatal) {
              if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
                // Try fallback to proxy if direct failed
                if (mediaSrc === src && isExternal) {
                  setupPlayer(`/api/proxy-media?url=${encodeURIComponent(src)}`);
                } else {
                  hls?.startLoad();
                }
              } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
                hls?.recoverMediaError();
              } else {
                hls?.destroy();
              }
            }
          });
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = mediaSrc;
          if (autoPlay) {
            video.play().catch(() => {});
          }
        } else {
          video.src = mediaSrc;
        }
      } else {
        video.src = mediaSrc;
        if (autoPlay) {
          video.play().catch(() => {});
        }
      }
    };

    setupPlayer(initialSrc);

    return () => {
      if (hls) {
        hls.destroy();
      }
    };
  }, [src, autoPlay]);

  return (
    <video
      ref={videoRef}
      className={className}
      autoPlay={autoPlay}
      loop={loop}
      muted={muted}
      playsInline={playsInline}
      controls={controls}
      poster={poster}
    />
  );
};

export default VideoMedia;
