import { config } from 'dotenv';

config();

// Parse connection string if provided, otherwise use individual components
const parseConnectionString = () => {
  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '5432', 10);
  const user = process.env.DB_USER || 'postgres';
  const password = process.env.DB_PASSWORD || '';
  const database = process.env.DB_NAME || 'gravita';
  const sslMode = process.env.DB_SSL_MODE || 'require';

  // Build connection string with SSL parameters for Neon
  const sslParams = sslMode === 'require' ? '?sslmode=require' : '';
  return `postgresql://${user}:${password}@${host}:${port}/${database}${sslParams}`;
};

export const databaseConfig = {
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

export const getDatabaseUrl = (): string => {
  return parseConnectionString();
};

