import { pgTable, uuid, varchar, text, timestamp, boolean, integer, pgEnum, serial, index, uniqueIndex, jsonb } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// ==========================================
// Custom pgEnum Definitions for Space Savings & Constraints
// ==========================================
export const genderEnum = pgEnum('gender_type', ['male', 'female', 'other']);

export const relationshipEnum = pgEnum('relationship_type', [
  'self', 'spouse', 'son', 'daughter', 'father', 'mother',
  'brother', 'sister', 'daughter_in_law', 'son_in_law',
  'grandson', 'granddaughter', 'other'
]);

export const maritalStatusEnum = pgEnum('marital_status', [
  'single', 'married', 'widowed', 'divorced'
]);

export const occupationEnum = pgEnum('occupation_type', [
  'business', 'salaried', 'professional', 'student', 'homemaker', 'retired', 'other'
]);

export const verificationStatusEnum = pgEnum('verification_status', [
  'pending', 'approved', 'rejected'
]);

// ==========================================
// Core User & Auth Tables (Original Structures Maintained)
// ==========================================

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: varchar('email', { length: 255 }).unique(),
  mobile: varchar('mobile', { length: 20 }).unique(),
  fullName: varchar('full_name', { length: 255 }).notNull(),
  avatarUrl: text('avatar_url'),
  googleId: varchar('google_id', { length: 255 }).unique(),
  passwordHash: text('password_hash'),
  role: varchar('role', { length: 50 }).default('member').notNull(), // 'admin', 'member', 'moderator'
  preferredLanguage: varchar('preferred_language', { length: 10 }).default('en').notNull(), // 'en', 'hi'
  status: varchar('status', { length: 50 }).default('active').notNull(), // 'active', 'inactive', 'suspended'
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export const devices = pgTable('devices', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .references(() => users.id, { onDelete: 'cascade' })
    .notNull(),
  fcmToken: text('fcm_token').notNull().unique(),
  deviceType: varchar('device_type', { length: 50 }).default('android').notNull(), // 'android', 'ios'
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('devices_user_id_idx').on(table.userId),
]);

// ==========================================
// Normalized Directory & Family Tree Module Tables
// ==========================================

/**
 * Regions Table: Administrative zones or districts for coordinator assignments (e.g. "Jaipur Zone")
 */
export const regions = pgTable('regions', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 100 }).notNull().unique(), // e.g. "Jaipur Zone"
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

/**
 * Villages Table: Specific native villages (e.g. "Bagru", "Dudu") belonging to a region
 */
export const villages = pgTable('villages', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 100 }).notNull(), // e.g. "Bagru"
  regionId: integer('region_id').references(() => regions.id, { onDelete: 'cascade' }).notNull(), // Linked to region
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('villages_region_id_idx').on(table.regionId),
  uniqueIndex('villages_name_region_id_unique_idx').on(table.name, table.regionId), // Prevent duplicate villages in same region
]);

/**
 * Families Table: Groups family units together
 */
export const families = pgTable('families', {
  id: serial('id').primaryKey(),
  familyHeadId: integer('family_head_id').references((): any => familyMembers.id, { onDelete: 'set null' }), // Set after head record creation (circular link allowed nullable)
  familyCode: varchar('family_code', { length: 50 }).notNull().unique(), // e.g. "ABRP-10001"
  address: text('address').notNull(),
  city: varchar('city', { length: 100 }),
  state: varchar('state', { length: 100 }),
  pincode: varchar('pincode', { length: 15 }),
  villageId: integer('village_id').references(() => villages.id, { onDelete: 'restrict' }).notNull(), // Linked to specific village
  importBatchId: uuid('import_batch_id'), // Used to rollback a bulk onboarding import batch if errors occur
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('families_village_id_idx').on(table.villageId),
  index('families_head_id_idx').on(table.familyHeadId),
]);

/**
 * Family Members Table: Individual persons in the family tree
 */
export const familyMembers = pgTable('family_members', {
  id: serial('id').primaryKey(),
  familyId: integer('family_id').references((): any => families.id, { onDelete: 'cascade' }).notNull(),

  // Optionally links to credentials if they register on the app
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }).unique(),

  // Basic Details
  fullName: varchar('full_name', { length: 255 }).notNull(),
  gender: genderEnum('gender').notNull(), // Enums save space & enforce type constraints
  relationshipToHead: relationshipEnum('relationship_to_head').default('other').notNull(),
  birthDate: timestamp('birth_date'),
  estimatedAgeOnCreation: integer('estimated_age_on_creation'),
  estimatedBirthYear: integer('estimated_birth_year'), // Calculated dynamically as: (creation_year - estimatedAgeOnCreation)

  // Vital Status
  isAlive: boolean('is_alive').default(true).notNull(),
  deceasedDate: timestamp('deceased_date'),

  // Marriage details
  maritalStatus: maritalStatusEnum('marital_status').default('single').notNull(),
  anniversaryDate: timestamp('anniversary_date'),

  // Contact Info
  mobile: varchar('mobile', { length: 20 }).unique(), // Unique for quick lookup, optional for dependents
  whatsappMobile: varchar('whatsapp_mobile', { length: 20 }),
  email: varchar('email', { length: 255 }),
  bloodGroup: varchar('blood_group', { length: 5 }), // E.g. 'A+', 'O-', 'AB+'
  gotra: varchar('gotra', { length: 100 }),

  // Overriding Address (if living separately from family head, e.g. children in other cities)
  currentAddress: text('current_address'),
  currentCity: varchar('current_city', { length: 100 }),
  currentState: varchar('current_state', { length: 100 }),
  currentPincode: varchar('current_pincode', { length: 15 }),

  // Professional & Education
  education: varchar('education', { length: 255 }),
  occupationType: occupationEnum('occupation_type').default('other').notNull(),
  occupationDetail: varchar('occupation_detail', { length: 255 }),
  yearlyIncome: integer('yearly_income'),
  specialRemarks: text('special_remarks'),
  avatarUrl: text('avatar_url'), // Profile photo for tree nodes (R2 URL)

  // Family Tree Node Connections (Self-referential integer relationships)
  fatherId: integer('father_id').references((): any => familyMembers.id, { onDelete: 'set null' }),
  motherId: integer('mother_id').references((): any => familyMembers.id, { onDelete: 'set null' }),
  spouseId: integer('spouse_id').references((): any => familyMembers.id, { onDelete: 'set null' }),

  // Validation Workflow
  status: verificationStatusEnum('status').default('pending').notNull(),
  validationFeedback: text('validation_feedback'),
  validatedBy: uuid('validated_by').references(() => users.id),
  validatedAt: timestamp('validated_at'),

  // Tracking
  createdBy: uuid('created_by').references(() => users.id).notNull(),
  importBatchId: uuid('import_batch_id'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('fm_family_id_idx').on(table.familyId),
  index('fm_user_id_idx').on(table.userId),
  index('fm_father_id_idx').on(table.fatherId),
  index('fm_mother_id_idx').on(table.motherId),
  index('fm_spouse_id_idx').on(table.spouseId),
  index('fm_status_idx').on(table.status),
  index('fm_full_name_idx').on(table.fullName),
]);

/**
 * Business Profiles Table: Stores details for community business cards
 */
export const businessProfiles = pgTable('business_profiles', {
  id: serial('id').primaryKey(),
  businessName: varchar('business_name', { length: 255 }).notNull(),
  logoUrl: text('logo_url'),
  industryCategory: varchar('industry_category', { length: 100 }).notNull(),
  contactMobile: varchar('contact_mobile', { length: 20 }).notNull(),
  whatsappMobile: varchar('whatsapp_mobile', { length: 20 }),
  email: varchar('email', { length: 255 }),
  websiteUrl: varchar('website_url', { length: 255 }),
  gstin: varchar('gstin', { length: 15 }),
  description: text('description'),
  tags: jsonb('tags'), // JSON array of string tags
  operatingHours: jsonb('operating_hours'), // JSON object for operational timings
  communityPerk: jsonb('community_perk'), // JSON object for Samaj offer details
  catalog: jsonb('catalog'), // JSON array of products: [{title, description, imageUrl}]
  isApproved: boolean('is_approved').default(false).notNull(),
  createdBy: uuid('created_by').references(() => users.id).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('bp_created_by_idx').on(table.createdBy),
]);

/**
 * Business Members Table: Maps family members to business profiles (supports partner/owner roles)
 */
export const businessMembers = pgTable('business_members', {
  id: serial('id').primaryKey(),
  businessId: integer('business_id').references(() => businessProfiles.id, { onDelete: 'cascade' }).notNull(),
  memberId: integer('member_id').references(() => familyMembers.id, { onDelete: 'cascade' }).notNull(),
  roleInBusiness: varchar('role_in_business', { length: 100 }).default('Owner').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => [
  index('bm_business_id_idx').on(table.businessId),
  index('bm_member_id_idx').on(table.memberId),
]);

/**
 * Business Locations Table: Showrooms / factories / branches
 */
export const businessLocations = pgTable('business_locations', {
  id: serial('id').primaryKey(),
  businessId: integer('business_id').references(() => businessProfiles.id, { onDelete: 'cascade' }).notNull(),
  branchName: varchar('branch_name', { length: 100 }).default('Main Branch').notNull(),
  address: text('address').notNull(),
  city: varchar('city', { length: 100 }).notNull(),
  state: varchar('state', { length: 100 }),
  pincode: varchar('pincode', { length: 15 }),
  contactMobile: varchar('contact_mobile', { length: 20 }),
  googleMapsLink: text('google_maps_link'),
  isPrimary: boolean('is_primary').default(true).notNull(), // Identifies Head Office / Main Branch
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('bl_business_id_idx').on(table.businessId),
  index('bl_business_id_is_primary_idx').on(table.businessId, table.isPrimary),
]);

/**
 * Coordinator Regions Table: Maps users (coordinators) to regions they moderate
 */
export const coordinatorRegions = pgTable('coordinator_regions', {
  id: serial('id').primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  regionId: integer('region_id').references(() => regions.id, { onDelete: 'cascade' }).notNull(), // Normalized link
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => [
  index('cr_user_id_idx').on(table.userId),
  index('cr_region_id_idx').on(table.regionId),
]);

/**
 * OTPs Table: Temporary codes generated for mobile authentication
 */
export const otps = pgTable('otps', {
  id: serial('id').primaryKey(),
  mobile: varchar('mobile', { length: 20 }).notNull(),
  code: varchar('code', { length: 6 }).notNull(),
  expiresAt: timestamp('expires_at').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => [
  index('otps_mobile_idx').on(table.mobile),
]);

// ==========================================
// Drizzle Relations Helpers (Purely schema-level, no migrations needed)
// ==========================================

export const regionsRelations = relations(regions, ({ many }) => ({
  villages: many(villages),
}));

export const villagesRelations = relations(villages, ({ one, many }) => ({
  region: one(regions, {
    fields: [villages.regionId],
    references: [regions.id],
  }),
  families: many(families),
}));

export const familiesRelations = relations(families, ({ one, many }) => ({
  village: one(villages, {
    fields: [families.villageId],
    references: [villages.id],
  }),
  members: many(familyMembers),
  head: one(familyMembers, {
    fields: [families.familyHeadId],
    references: [familyMembers.id],
  }),
}));

export const familyMembersRelations = relations(familyMembers, ({ one }) => ({
  family: one(families, {
    fields: [familyMembers.familyId],
    references: [families.id],
  }),
}));

export const businessProfilesRelations = relations(businessProfiles, ({ many }) => ({
  members: many(businessMembers),
  locations: many(businessLocations),
}));

export const businessMembersRelations = relations(businessMembers, ({ one }) => ({
  business: one(businessProfiles, {
    fields: [businessMembers.businessId],
    references: [businessProfiles.id],
  }),
  member: one(familyMembers, {
    fields: [businessMembers.memberId],
    references: [familyMembers.id],
  }),
}));

export const businessLocationsRelations = relations(businessLocations, ({ one }) => ({
  business: one(businessProfiles, {
    fields: [businessLocations.businessId],
    references: [businessProfiles.id],
  }),
}));

/**
 * Advertisements Table: Multi-placement community ads & promotional banners
 */
export const advertisements = pgTable('advertisements', {
  id: serial('id').primaryKey(),
  title: varchar('title', { length: 255 }).notNull(),
  tagline: text('tagline'),
  imageUrl: text('image_url'),
  category: varchar('category', { length: 100 }).notNull(),
  placements: jsonb('placements').notNull(), // JSON array of strings e.g. ["home_carousel", "directory_feed"]
  displayStyle: varchar('display_style', { length: 50 }).default('banner').notNull(),
  businessId: integer('business_id').references(() => businessProfiles.id, { onDelete: 'set null' }),
  targetUrl: text('target_url'),
  contactMobile: varchar('contact_mobile', { length: 20 }),
  whatsappMobile: varchar('whatsapp_mobile', { length: 20 }),
  location: varchar('location', { length: 150 }),
  isActive: boolean('is_active').default(true).notNull(),
  priority: integer('priority').default(0).notNull(),
  startDate: timestamp('start_date').defaultNow().notNull(),
  endDate: timestamp('end_date'),
  createdBy: uuid('created_by').references(() => users.id).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => [
  index('ads_is_active_priority_idx').on(table.isActive, table.priority),
]);

export const advertisementsRelations = relations(advertisements, ({ one }) => ({
  business: one(businessProfiles, {
    fields: [advertisements.businessId],
    references: [businessProfiles.id],
  }),
  creator: one(users, {
    fields: [advertisements.createdBy],
    references: [users.id],
  }),
}));




