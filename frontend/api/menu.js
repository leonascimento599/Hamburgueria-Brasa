import { getOnly, loadMenu } from '../server/catalog.js';

export default { fetch: getOnly(loadMenu) };
