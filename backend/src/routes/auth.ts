import { Hono } from 'hono';
import { 
  handleGoogleLogin, 
  handleRegister, 
  handleLogin,
  handleForgotPassword,
  handleResetPassword,
  handleLinkMobile
} from '../controllers/auth.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const authRouter = new Hono();

authRouter.post('/google', handleGoogleLogin);
authRouter.post('/register', handleRegister);
authRouter.post('/login', handleLogin);
authRouter.post('/forgot-password', handleForgotPassword);
authRouter.post('/reset-password', handleResetPassword);
authRouter.post('/link-mobile', authMiddleware, handleLinkMobile);

export { authRouter };
