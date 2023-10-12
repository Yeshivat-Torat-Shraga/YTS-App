import { useEffect, useRef, useState } from 'react';
import Hls, { LevelLoadedData } from 'hls.js';

interface Props {
	hlsSource: string;
}

/**
 * Source: https://github.com/777777miSSU7777777/hls-audio-player/blob/master/src/components/hls-audio-player/hls-audio-player.tsx
 */
const HLSAudioPlayer = (props: Props) => {
	const { hlsSource } = props;
	const audioRef = useRef<HTMLMediaElement | null>(null);
	const hlsRef = useRef<Hls | null>(null);
	// const [duration, setDuration] = useState(0);
	// const [currentTime, setCurrentTime] = useState(0);
	// const [isPlaying, setIsPlaying] = useState<boolean>(false);
	// const [volume, setVolume] = useState<number>(1);
	// const [isMuted, setIsMuted] = useState<boolean>(false);

	useEffect(() => {
		if (hlsRef.current) {
			hlsRef.current.destroy();
		}

		if (audioRef.current) {
			hlsRef.current = new Hls();
			hlsRef.current.attachMedia(audioRef.current);
			hlsRef.current.on(Hls.Events.MEDIA_ATTACHED, () => {
				hlsRef.current?.loadSource(hlsSource);

				hlsRef.current?.on(Hls.Events.MANIFEST_PARSED, () => {
					hlsRef.current?.on(
						Hls.Events.LEVEL_LOADED,
						(_: string, data: LevelLoadedData) => {
							// const duration: number = data.details.totalduration;
							// setDuration(duration);
							// setCurrentTime(0);
							// audioRef.current?.play();
						}
					);
				});
			});
		}
	}, [hlsSource]);

	return <audio ref={audioRef} controls />;
};

export default HLSAudioPlayer;
