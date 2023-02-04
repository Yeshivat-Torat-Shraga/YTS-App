import { getDownloadURL, ref } from '@firebase/storage';
import { storage } from './Firebase/firebase';
import { Rabbi, RawRabbi } from './types/rabbi';
import { RawShiur, Shiur } from './types/shiur';

export async function processRawRebbeim(rawRebbeim: RawRabbi[]): Promise<Rabbi[]> {
	return Promise.all(
		rawRebbeim.map(async (rawRabbi) => {
			let rabbi: Rabbi = {
				...rawRabbi,
				profilePictureURL: await getDownloadURL(
					ref(storage, `profile-pictures/${rawRabbi.profile_picture_filename}`)
				),
			};
			return rabbi;
		})
	);
}

export function processRawShiurim(rawShiurim: RawShiur[], rabbis: Rabbi[]): Shiur[] {
	return rawShiurim.map((rawShiur) => {
		// let rabbi: Rabbi =
		let shiur: Shiur = {
			...rawShiur,
			author: rabbis.find((rabbi) => rabbi.id === rawShiur.attributionID),
			authorName: rawShiur.author,
		};
		return shiur;
	});
}
