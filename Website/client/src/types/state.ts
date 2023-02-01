import Shiur from './shiur';

export interface ShiurData {
	shiurim: Shiur[];
	setShiurim: (shiurim: Shiur[]) => void;
	updateShiur: (shiur: Shiur) => void;
	deleteShiur: (shiur: Shiur) => void;
	clearShiurim: () => void;
}
