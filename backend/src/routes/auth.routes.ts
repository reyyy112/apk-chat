import { Router } from 'express';
import { 
  loginOrRegister, 
  registerUser, 
  requestOtp, 
  verifyOtp,
  getMyProfile,
  updateUserProfile,
  getUserPhotos,
  addUserPhoto,
  deleteUserPhoto,
  uploadImageFile
} from '../controllers/auth.controller';

const router = Router();

router.post('/login', loginOrRegister);
router.post('/register', registerUser);
router.post('/request-otp', requestOtp);
router.post('/verify-otp', verifyOtp);

// User Profile & Photo Endpoints
router.get('/me', getMyProfile);
router.put('/profile', updateUserProfile);
router.get('/photos', getUserPhotos);
router.post('/photos', addUserPhoto);
router.delete('/photos/:photoId', deleteUserPhoto);
router.post('/upload', uploadImageFile);

export default router;

