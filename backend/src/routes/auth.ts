import { Hono } from 'hono';
import { 
  handleGoogleLogin, 
  handleRegister, 
  handleLogin 
} from '@/controllers/auth.controller';

const authRouter = new Hono();

authRouter.post('/google', handleGoogleLogin);
authRouter.post('/register', handleRegister);
authRouter.post('/login', handleLogin);

export { authRouter };
