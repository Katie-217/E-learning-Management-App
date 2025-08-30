export interface EnvConfig {
  PORT: number;
  DATABASE_URL: string;
  JWT_SECRET: string;
}

export const env: EnvConfig = {
  PORT: parseInt(process.env.PORT || '4000', 10),
  DATABASE_URL: process.env.DATABASE_URL || 'postgres://user:pass@localhost:5432/elearning',
  JWT_SECRET: process.env.JWT_SECRET || 'change_me',
};












