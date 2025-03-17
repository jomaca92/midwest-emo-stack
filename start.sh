#!/bin/sh -ex

# Run database migrations before starting the server
# This ensures the database schema is up to date before the application starts

# Run Prisma migrations
npx prisma migrate deploy

# Start the application
npm run start
