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
  imageUrl?: string;
}

export interface SendWishNotificationRequest {
  title: string;
  body: string;
  imageUrl?: string;
  type?: 'festival' | 'birthday' | 'anniversary' | 'announcement' | 'general';
  targetType?: 'all' | 'family' | 'user';
  targetIds?: string[];
  metadata?: Record<string, any>;
}

export interface NotificationResponseItem {
  id: string;
  title: string;
  body: string;
  imageUrl: string | null;
  type: string;
  targetType: string;
  targetId: string | null;
  metadata: Record<string, any> | null;
  createdAt: string;
  isRead: boolean;
  isToday: boolean;
}

