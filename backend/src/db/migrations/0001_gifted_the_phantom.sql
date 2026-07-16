CREATE TABLE "otps" (
	"id" serial PRIMARY KEY NOT NULL,
	"mobile" varchar(20) NOT NULL,
	"code" varchar(6) NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "users" ALTER COLUMN "email" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "mobile" varchar(20);--> statement-breakpoint
CREATE INDEX "otps_mobile_idx" ON "otps" USING btree ("mobile");--> statement-breakpoint
ALTER TABLE "family_members" DROP COLUMN "full_name_hindi";--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_mobile_unique" UNIQUE("mobile");