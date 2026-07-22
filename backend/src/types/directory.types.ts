export interface BusinessProfilePayload {
  businessName: string;
  industryCategory: string;
  contactMobile: string;
  whatsappMobile?: string;
  email?: string;
  websiteUrl?: string;
  gstin?: string;
  description?: string;
  tags?: string[];
  operatingHours?: {
    days?: string;
    open?: string;
    close?: string;
  };
  communityPerk?: {
    type?: string;
    value?: string;
    description?: string;
  };
  catalog?: {
    title: string;
    description: string;
    imageUrl?: string;
  }[];
  address: string;
  city: string;
  state?: string;
  pincode?: string;
  googleMapsLink?: string;
}

export interface OnboardFamilyRequest {
  family: {
    address: string;
    city?: string;
    state?: string;
    pincode?: string;
    villageId: number;
  };
  head: {
    fullName: string;
    gender: 'male' | 'female' | 'other';
    birthDate?: string; // ISO String
    estimatedAgeOnCreation?: number;
    mobile?: string;
    whatsappMobile?: string;
    gotra?: string;
    bloodGroup?: string;
    education?: string;
    occupationType?: 'business' | 'salaried' | 'professional' | 'student' | 'homemaker' | 'retired' | 'other';
    occupationDetail?: string;
    yearlyIncome?: number;
    businessProfile?: BusinessProfilePayload;
  };
}

export interface AddFamilyMemberRequest {
  familyId: number;
  fullName: string;
  gender: 'male' | 'female' | 'other';
  relationshipToHead: 'spouse' | 'son' | 'daughter' | 'father' | 'mother' | 'brother' | 'sister' | 'daughter_in_law' | 'son_in_law' | 'grandson' | 'granddaughter' | 'other';
  birthDate?: string; // ISO String
  estimatedAgeOnCreation?: number;
  mobile?: string;
  whatsappMobile?: string;
  email?: string;
  bloodGroup?: string;
  gotra?: string;
  maritalStatus?: 'single' | 'married' | 'widowed' | 'divorced';
  anniversaryDate?: string; // ISO String
  currentAddress?: string;
  currentCity?: string;
  currentState?: string;
  currentPincode?: string;
  education?: string;
  occupationType?: 'business' | 'salaried' | 'professional' | 'student' | 'homemaker' | 'retired' | 'other';
  occupationDetail?: string;
  yearlyIncome?: number;
  specialRemarks?: string;
  avatarUrl?: string;
  fatherId?: number;
  motherId?: number;
  spouseId?: number;
  businessProfile?: BusinessProfilePayload;
}
