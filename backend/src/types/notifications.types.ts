export interface RegisterDeviceRequest {
  fcmToken?: string;
  deviceType?: 'android' | 'ios';
}

export interface UnregisterDeviceRequest {
  fcmToken?: string;
}

export interface SendTestNotificationRequest {
  targetUserId?: string;
  targetUserIds?: string[];
  title?: string;
  body?: string;
}
