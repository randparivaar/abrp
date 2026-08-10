CREATE TABLE "advertisements" (
	"id" serial PRIMARY KEY NOT NULL,
	"title" varchar(255) NOT NULL,
	"tagline" text,
	"image_url" text,
	"category" varchar(100) NOT NULL,
	"placements" jsonb NOT NULL,
	"display_style" varchar(50) DEFAULT 'banner' NOT NULL,
	"business_id" integer,
	"target_url" text,
	"contact_mobile" varchar(20),
	"whatsapp_mobile" varchar(20),
	"location" varchar(150),
	"is_active" boolean DEFAULT true NOT NULL,
	"priority" integer DEFAULT 0 NOT NULL,
	"start_date" timestamp DEFAULT now() NOT NULL,
	"end_date" timestamp,
	"created_by" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "advertisements" ADD CONSTRAINT "advertisements_business_id_business_profiles_id_fk" FOREIGN KEY ("business_id") REFERENCES "public"."business_profiles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "advertisements" ADD CONSTRAINT "advertisements_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "ads_is_active_priority_idx" ON "advertisements" USING btree ("is_active","priority");