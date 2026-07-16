export interface UpdateUserProfileRequest {
  fullName?: string;
  preferredLanguage?: 'en' | 'hi';
  avatarUrl?: string;
}

export interface ChangeRoleRequest {
  userId?: string;
  newRole?: 'admin' | 'member' | 'moderator';
}
