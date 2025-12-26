import { defineConfig } from 'drizzle-kit';
import { config } from 'dotenv';

config();

// Support both connection string and individual components
const getDbCredentials = () => {
  // If DATABASE_URL is provided, use it directly
  if (process.env.DATABASE_URL) {
    return {
      url: process.env.DATABASE_URL,
    };
  }

  // Otherwise, use individual components
  return {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'gravita',
    // Neon requires SSL, so default to require mode
    ssl: process.env.DB_SSL === 'false' 
      ? false 
      : { rejectUnauthorized: false }, // Neon uses valid certificates
  };
};

export default defineConfig({
  schema: './src/database/schema/index.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: getDbCredentials(),
  verbose: true,
  strict: true,
});

