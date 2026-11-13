import { getOnly, loadCoupons } from '../server/catalog.js';

export default { fetch: getOnly(async () => ({ coupons: await loadCoupons() })) };
