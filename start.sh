#!/bin/sh -ex

# Fix permissions on the data directory if needed
# This handles cases where the volume is mounted with incorrect permissions
mkdir -p /data
chown -R node:node /data

# Run database migrations before starting the server
# This ensures the database schema is up to date before the application starts

# Run Prisma migrations
npx prisma migrate deploy

# Start the application
npm run start
