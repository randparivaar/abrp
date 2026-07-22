export interface GoogleLoginRequest {
  idToken?: string;
  fcmToken?: string;
  deviceType?: 'android' | 'ios';
}

export interface RegisterRequest {
  email?: string;
  fullName?: string;
  password?: string;
  mobile?: string;
  fcmToken?: string;
  deviceType?: 'android' | 'ios';
}

export interface LoginRequest {
  email?: string;
  password?: string;
  fcmToken?: string;
  deviceType?: 'android' | 'ios';
}

export interface UserSessionPayload {
  id: string;
  email: string;
  role: 'admin' | 'member' | 'moderator';
}
