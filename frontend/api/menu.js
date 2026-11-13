import { menu, getOnly } from '../server/catalog.js';

const GET = () => Response.json(menu);
export default { fetch: getOnly(GET) };
