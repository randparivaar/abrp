export interface UpdateUserProfileRequest {
  fullName?: string;
  preferredLanguage?: 'en' | 'hi';
}

export interface ChangeRoleRequest {
  userId?: string;
  newRole?: 'admin' | 'member' | 'moderator';
}
