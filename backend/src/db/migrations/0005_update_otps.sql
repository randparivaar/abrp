ALTER TABLE "otps" ALTER COLUMN "mobile" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "otps" ADD COLUMN IF NOT EXISTS "email" varchar(255);--> statement-breakpoint
ALTER TABLE "otps" ADD COLUMN IF NOT EXISTS "attempts" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "otps_email_idx" ON "otps" USING btree ("email");
