CREATE TYPE "public"."gender_type" AS ENUM('male', 'female', 'other');--> statement-breakpoint
CREATE TYPE "public"."marital_status" AS ENUM('single', 'married', 'widowed', 'divorced');--> statement-breakpoint
CREATE TYPE "public"."occupation_type" AS ENUM('business', 'salaried', 'professional', 'student', 'homemaker', 'retired', 'other');--> statement-breakpoint
CREATE TYPE "public"."relationship_type" AS ENUM('self', 'spouse', 'son', 'daughter', 'father', 'mother', 'brother', 'sister', 'daughter_in_law', 'son_in_law', 'grandson', 'granddaughter', 'other');--> statement-breakpoint
CREATE TYPE "public"."verification_status" AS ENUM('pending', 'approved', 'rejected');--> statement-breakpoint
CREATE TABLE "business_locations" (
	"id" serial PRIMARY KEY NOT NULL,
	"business_id" integer NOT NULL,
	"branch_name" varchar(100) DEFAULT 'Main Branch' NOT NULL,
	"address" text NOT NULL,
	"city" varchar(100) NOT NULL,
	"state" varchar(100),
	"pincode" varchar(15),
	"contact_mobile" varchar(20),
	"google_maps_link" text,
	"is_primary" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "business_members" (
	"id" serial PRIMARY KEY NOT NULL,
	"business_id" integer NOT NULL,
	"member_id" integer NOT NULL,
	"role_in_business" varchar(100) DEFAULT 'Owner' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "business_profiles" (
	"id" serial PRIMARY KEY NOT NULL,
	"business_name" varchar(255) NOT NULL,
	"logo_url" text,
	"industry_category" varchar(100) NOT NULL,
	"contact_mobile" varchar(20) NOT NULL,
	"whatsapp_mobile" varchar(20),
	"email" varchar(255),
	"website_url" varchar(255),
	"gstin" varchar(15),
	"description" text,
	"is_approved" boolean DEFAULT false NOT NULL,
	"created_by" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "coordinator_regions" (
	"id" serial PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"region_id" integer NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "devices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"fcm_token" text NOT NULL,
	"device_type" varchar(50) DEFAULT 'android' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "devices_fcm_token_unique" UNIQUE("fcm_token")
);
--> statement-breakpoint
CREATE TABLE "families" (
	"id" serial PRIMARY KEY NOT NULL,
	"family_head_id" integer,
	"family_code" varchar(50) NOT NULL,
	"address" text NOT NULL,
	"city" varchar(100),
	"state" varchar(100),
	"pincode" varchar(15),
	"village_id" integer NOT NULL,
	"import_batch_id" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "families_family_code_unique" UNIQUE("family_code")
);
--> statement-breakpoint
CREATE TABLE "family_members" (
	"id" serial PRIMARY KEY NOT NULL,
	"family_id" integer NOT NULL,
	"user_id" uuid,
	"full_name" varchar(255) NOT NULL,
	"full_name_hindi" varchar(255),
	"gender" "gender_type" NOT NULL,
	"relationship_to_head" "relationship_type" DEFAULT 'other' NOT NULL,
	"birth_date" timestamp,
	"estimated_age_on_creation" integer,
	"estimated_birth_year" integer,
	"is_alive" boolean DEFAULT true NOT NULL,
	"deceased_date" timestamp,
	"marital_status" "marital_status" DEFAULT 'single' NOT NULL,
	"anniversary_date" timestamp,
	"mobile" varchar(20),
	"whatsapp_mobile" varchar(20),
	"email" varchar(255),
	"blood_group" varchar(5),
	"gotra" varchar(100),
	"current_address" text,
	"current_city" varchar(100),
	"current_state" varchar(100),
	"current_pincode" varchar(15),
	"education" varchar(255),
	"occupation_type" "occupation_type" DEFAULT 'other' NOT NULL,
	"occupation_detail" varchar(255),
	"yearly_income" integer,
	"aadhaar_no" varchar(12),
	"special_remarks" text,
	"avatar_url" text,
	"father_id" integer,
	"mother_id" integer,
	"spouse_id" integer,
	"status" "verification_status" DEFAULT 'pending' NOT NULL,
	"validation_feedback" text,
	"validated_by" uuid,
	"validated_at" timestamp,
	"created_by" uuid NOT NULL,
	"import_batch_id" uuid,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "family_members_user_id_unique" UNIQUE("user_id"),
	CONSTRAINT "family_members_mobile_unique" UNIQUE("mobile")
);
--> statement-breakpoint
CREATE TABLE "regions" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "regions_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(255) NOT NULL,
	"full_name" varchar(255) NOT NULL,
	"avatar_url" text,
	"google_id" varchar(255),
	"password_hash" text,
	"role" varchar(50) DEFAULT 'member' NOT NULL,
	"preferred_language" varchar(10) DEFAULT 'en' NOT NULL,
	"status" varchar(50) DEFAULT 'active' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email"),
	CONSTRAINT "users_google_id_unique" UNIQUE("google_id")
);
--> statement-breakpoint
CREATE TABLE "villages" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"region_id" integer NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "business_locations" ADD CONSTRAINT "business_locations_business_id_business_profiles_id_fk" FOREIGN KEY ("business_id") REFERENCES "public"."business_profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "business_members" ADD CONSTRAINT "business_members_business_id_business_profiles_id_fk" FOREIGN KEY ("business_id") REFERENCES "public"."business_profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "business_members" ADD CONSTRAINT "business_members_member_id_family_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."family_members"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "business_profiles" ADD CONSTRAINT "business_profiles_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coordinator_regions" ADD CONSTRAINT "coordinator_regions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coordinator_regions" ADD CONSTRAINT "coordinator_regions_region_id_regions_id_fk" FOREIGN KEY ("region_id") REFERENCES "public"."regions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "devices" ADD CONSTRAINT "devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "families" ADD CONSTRAINT "families_family_head_id_family_members_id_fk" FOREIGN KEY ("family_head_id") REFERENCES "public"."family_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "families" ADD CONSTRAINT "families_village_id_villages_id_fk" FOREIGN KEY ("village_id") REFERENCES "public"."villages"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_family_id_families_id_fk" FOREIGN KEY ("family_id") REFERENCES "public"."families"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_father_id_family_members_id_fk" FOREIGN KEY ("father_id") REFERENCES "public"."family_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_mother_id_family_members_id_fk" FOREIGN KEY ("mother_id") REFERENCES "public"."family_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_spouse_id_family_members_id_fk" FOREIGN KEY ("spouse_id") REFERENCES "public"."family_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_validated_by_users_id_fk" FOREIGN KEY ("validated_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "villages" ADD CONSTRAINT "villages_region_id_regions_id_fk" FOREIGN KEY ("region_id") REFERENCES "public"."regions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "bl_business_id_idx" ON "business_locations" USING btree ("business_id");--> statement-breakpoint
CREATE INDEX "bl_business_id_is_primary_idx" ON "business_locations" USING btree ("business_id","is_primary");--> statement-breakpoint
CREATE INDEX "bm_business_id_idx" ON "business_members" USING btree ("business_id");--> statement-breakpoint
CREATE INDEX "bm_member_id_idx" ON "business_members" USING btree ("member_id");--> statement-breakpoint
CREATE INDEX "bp_created_by_idx" ON "business_profiles" USING btree ("created_by");--> statement-breakpoint
CREATE INDEX "cr_user_id_idx" ON "coordinator_regions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "cr_region_id_idx" ON "coordinator_regions" USING btree ("region_id");--> statement-breakpoint
CREATE INDEX "devices_user_id_idx" ON "devices" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "families_village_id_idx" ON "families" USING btree ("village_id");--> statement-breakpoint
CREATE INDEX "families_head_id_idx" ON "families" USING btree ("family_head_id");--> statement-breakpoint
CREATE INDEX "fm_family_id_idx" ON "family_members" USING btree ("family_id");--> statement-breakpoint
CREATE INDEX "fm_user_id_idx" ON "family_members" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "fm_father_id_idx" ON "family_members" USING btree ("father_id");--> statement-breakpoint
CREATE INDEX "fm_mother_id_idx" ON "family_members" USING btree ("mother_id");--> statement-breakpoint
CREATE INDEX "fm_spouse_id_idx" ON "family_members" USING btree ("spouse_id");--> statement-breakpoint
CREATE INDEX "fm_status_idx" ON "family_members" USING btree ("status");--> statement-breakpoint
CREATE INDEX "fm_full_name_idx" ON "family_members" USING btree ("full_name");--> statement-breakpoint
CREATE INDEX "villages_region_id_idx" ON "villages" USING btree ("region_id");--> statement-breakpoint
CREATE UNIQUE INDEX "villages_name_region_id_unique_idx" ON "villages" USING btree ("name","region_id");