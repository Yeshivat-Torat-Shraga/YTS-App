import { create } from 'zustand';
import Shiur from './types/shiur';
import { ShiurData } from './types/state';

export const useShiurimStore = create<ShiurData>()((set) => ({
	shiurim: [],
	setShiurim: (shiurim: Shiur[]) => set({ shiurim }),
	updateShiur: (shiur: Shiur) =>
		set((state) => ({
			shiurim: state.shiurim.map((s) => (s.id === shiur.id ? shiur : s)),
		})),
	deleteShiur: (shiur: Shiur) =>
		set((state) => ({
			shiurim: state.shiurim.filter((s) => s.id !== shiur.id),
		})),
	clearShiurim: () => set({ shiurim: [] }),
}));
