import { db } from './index.js';
import { regions, villages, users, coordinatorRegions } from './schema.js';
import { eq } from 'drizzle-orm';
import { hashPassword } from '../utils/crypto.js';

// ── Village Seed Data ──────────────────────────────────────────────────────

const villageData = [
  {
    region: 'Nagaur Zone',
    villages: [
      'Makrana', 'Borawar', 'Bidiyad', 'Gachhipura', 'Kuchaman City',
      'Parbatsar', 'Didwana', 'Ladnun', 'Merta City', 'Gwan',
      'Kuchera', 'Degana', 'Jayal', 'Sanju', 'Rian Badi',
    ],
  },
  {
    region: 'Ajmer & Kishangarh Zone',
    villages: [
      'Kishangarh', 'Ajmer', 'Beawar', 'Pushkar', 'Roopangarh',
      'Madanganj', 'Kekri', 'Nasirabad', 'Sarwar', 'Arai',
    ],
  },
  {
    region: 'Sikar Zone (Shekhawati)',
    villages: [
      'Sikar', 'Laxmangarh', 'Fatehpur Shekhawati', 'Ramgarh Shekhawati',
      'Srimadhopur', 'Khandela', 'Neem Ka Thana', 'Reengus',
      'Dantaramgarh', 'Losal', 'Pipprali',
    ],
  },
  {
    region: 'Churu Zone (Shekhawati)',
    villages: [
      'Churu', 'Sujangarh', 'Ratangarh', 'Sardarshahar', 'Rajgarh',
      'Bidasar', 'Taranagar', 'Salasar', 'Sandwa',
    ],
  },
  {
    region: 'Jhunjhunu Zone (Shekhawati)',
    villages: [
      'Jhunjhunu', 'Nawalgarh', 'Chirawa', 'Mandawa', 'Udaipurwati',
      'Pilani', 'Surajgarh', 'Khetri', 'Mukundgarh', 'Bagar',
    ],
  },
  {
    region: 'Jodhpur Zone',
    villages: ['Jodhpur', 'Phalodi', 'Bilara', 'Pipar City', 'Shergarh', 'Luni', 'Osian', 'Boranada'],
  },
  {
    region: 'Jaipur Zone',
    villages: [
      'Jaipur City', 'Bagru', 'Dudu', 'Chomu', 'Sanganer',
      'Phulera', 'Sambhar Lake', 'Kotputli', 'Shahpura (Jaipur)', 'Achrol', 'Jobner',
    ],
  },
  {
    region: 'Bikaner Zone',
    villages: ['Bikaner', 'Nokha', 'Sri Dungargarh', 'Lunasar', 'Kolayat', 'Deshnoke'],
  },
  {
    region: 'Bhilwara Zone',
    villages: ['Bhilwara', 'Shahpura (Bhilwara)', 'Mandalgarh', 'Gangapur', 'Asind', 'Gulabpura', 'Bijolia'],
  },
  {
    region: 'Pali & Western Zone',
    villages: ['Pali', 'Falna', 'Sojat', 'Sumerpur', 'Jaitaran', 'Bali', 'Barmer', 'Balotra', 'Jalore', 'Jaisalmer'],
  },
  {
    region: 'Udaipur & Southern Zone',
    villages: ['Udaipur', 'Nathdwara', 'Rajsamand', 'Chittorgarh', 'Kankroli', 'Bhinder', 'Salumber', 'Dungarpur', 'Banswara'],
  },
  {
    region: 'Gujarat - Surat/Rander Zone',
    villages: ['Rander', 'Surat City', 'Adajan', 'Jahangirpura', 'Olpad', 'Bardoli', 'Vyara', 'Navsari', 'Valsad', 'Vapi'],
  },
  {
    region: 'Gujarat - Ahmedabad Zone',
    villages: ['Ahmedabad', 'Gandhinagar', 'Nadiad', 'Anand', 'Mehsana', 'Rajkot', 'Vadodara', 'Bhavnagar', 'Jamnagar', 'Bhuj', 'Morbi'],
  },
  {
    region: 'Maharashtra Zone',
    villages: ['Mumbai', 'Thane', 'Navi Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Kolhapur', 'Solapur', 'Aurangabad', 'Amravati', 'Akola', 'Jalgaon'],
  },
  {
    region: 'South India Zone',
    villages: ['Hyderabad', 'Secunderabad', 'Bangalore', 'Chennai', 'Coimbatore', 'Madurai', 'Vijayawada', 'Guntur', 'Visakhapatnam', 'Mysore', 'Kochi'],
  },
  {
    region: 'Central & North India Zone',
    villages: ['Delhi / NCR', 'Noida', 'Gurgaon', 'Faridabad', 'Ghaziabad', 'Kolkata', 'Indore', 'Raipur', 'Bhopal', 'Jabalpur', 'Gwalior', 'Kanpur', 'Lucknow', 'Varanasi', 'Patna'],
  },
  {
    region: 'International / NRI Zone',
    villages: ['United States', 'United Kingdom', 'United Arab Emirates', 'Canada', 'Australia', 'Singapore', 'Saudi Arabia', 'Oman', 'Kuwait', 'Qatar', 'Kenya', 'Other Country'],
  },
];

// ── User Seed Data ─────────────────────────────────────────────────────────

const userSeedData = [
  {
    email: 'admin@abrp.in',
    fullName: 'ABRP Super Admin',
    password: 'Admin@1234',
    role: 'admin' as const,
    label: 'Super Admin',
  },
  {
    email: 'moderator@abrp.in',
    fullName: 'Rander Samaj Moderator',
    password: 'Mod@1234',
    role: 'moderator' as const,
    label: 'Moderator (Gujarat - Surat/Rander Zone)',
    assignedRegion: 'Gujarat - Surat/Rander Zone',
  },
];

// ── Seed Functions ─────────────────────────────────────────────────────────

async function seedVillages() {
  console.log('\n📍 Seeding regions & villages...');

  let totalVillages = 0;
  for (const item of villageData) {
    // Upsert region
    const [insertedRegion] = await db
      .insert(regions)
      .values({ name: item.region })
      .onConflictDoUpdate({ target: regions.name, set: { updatedAt: new Date() } })
      .returning();

    const regionId = insertedRegion.id;

    // Insert villages (skip duplicates)
    const villageValues = item.villages.map((name) => ({ name, regionId }));
    await db.insert(villages).values(villageValues).onConflictDoNothing();
    totalVillages += item.villages.length;

    console.log(`  ✅ ${item.region} (${item.villages.length} villages)`);
  }

  console.log(`\n  Total: ${villageData.length} regions, ${totalVillages} villages seeded.`);
}

async function seedUsers() {
  console.log('\n👤 Seeding admin & moderator users...');

  for (const userData of userSeedData) {
    // Check if user already exists
    const existing = await db.query.users.findFirst({
      where: eq(users.email, userData.email),
    });

    if (existing) {
      console.log(`  ⏭️  ${userData.label} already exists (${userData.email}) — skipping`);
      continue;
    }

    // Insert user
    const [newUser] = await db
      .insert(users)
      .values({
        email: userData.email,
        fullName: userData.fullName,
        passwordHash: await hashPassword(userData.password),
        role: userData.role,
        status: 'active',
      })
      .returning();

    console.log(`  ✅ Created ${userData.label}: ${userData.email} / ${userData.password}`);

    // If moderator, assign to region
    if (userData.role === 'moderator' && 'assignedRegion' in userData && userData.assignedRegion) {
      const region = await db.query.regions.findFirst({
        where: eq(regions.name, userData.assignedRegion),
      });

      if (region) {
        await db.insert(coordinatorRegions).values({
          userId: newUser.id,
          regionId: region.id,
        }).onConflictDoNothing();
        console.log(`     📌 Assigned to region: ${userData.assignedRegion}`);
      } else {
        console.log(`     ⚠️  Region "${userData.assignedRegion}" not found — run village seed first!`);
      }
    }
  }
}

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 ABRP Database Seeder');
  console.log('========================');

  try {
    await seedVillages();
    await seedUsers();

    console.log('\n✅ All seeding completed successfully!\n');
    console.log('📋 Login credentials:');
    for (const u of userSeedData) {
      console.log(`   ${u.role.toUpperCase().padEnd(10)} → ${u.email.padEnd(30)} / ${u.password}`);
    }
  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();
