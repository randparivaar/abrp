ALTER TABLE "business_profiles" ADD COLUMN "tags" jsonb;--> statement-breakpoint
ALTER TABLE "business_profiles" ADD COLUMN "operating_hours" jsonb;--> statement-breakpoint
ALTER TABLE "business_profiles" ADD COLUMN "community_perk" jsonb;--> statement-breakpoint
ALTER TABLE "business_profiles" ADD COLUMN "catalog" jsonb;--> statement-breakpoint
ALTER TABLE "family_members" DROP COLUMN "aadhaar_no";