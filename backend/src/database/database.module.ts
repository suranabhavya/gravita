import { Module, Global } from '@nestjs/common';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';
import { databaseConfig, getDatabaseUrl } from '../config/database.config';

const connectionString = getDatabaseUrl();

// Create the postgres connection
// Neon requires SSL, so we ensure it's enabled unless explicitly disabled
const queryClient = postgres(connectionString, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
  ssl: process.env.DB_SSL === 'false' ? false : 'require', // Neon requires SSL
});

// Create the drizzle instance
export const db = drizzle(queryClient, { schema });

export const DATABASE_CONNECTION = 'DATABASE_CONNECTION';

@Global()
@Module({
  providers: [
    {
      provide: DATABASE_CONNECTION,
      useValue: db,
    },
  ],
  exports: [DATABASE_CONNECTION],
})
export class DatabaseModule {}

