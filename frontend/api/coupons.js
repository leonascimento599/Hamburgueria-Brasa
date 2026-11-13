import { menu, getOnly } from '../server/catalog.js';

export default { fetch: getOnly(() => Response.json({ coupons: menu.coupons })) };
