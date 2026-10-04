import { Router } from 'express';
import { getCallHistory, recordCall, getIceServers } from '../controllers/call.controller';

const router = Router();

router.get('/', getCallHistory);
router.post('/', recordCall);
router.get('/ice-servers', getIceServers);

export default router;
