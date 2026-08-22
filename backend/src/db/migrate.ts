import { migrate } from 'drizzle-orm/neon-http/migrator';
import { db } from './index.js';

async function runMigrate() {
  console.log('⏳ Running database migrations via Neon HTTP driver...');
  try {
    await migrate(db, { migrationsFolder: './src/db/migrations' });
    console.log('✅ All migrations completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed with error:');
    console.error(error);
    process.exit(1);
  }
}

runMigrate();
