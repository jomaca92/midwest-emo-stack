# base node image
FROM node:18-bullseye-slim AS base

# set for base and all layer that inherit from it
ENV NODE_ENV production

# Install openssl for Prisma
RUN apt-get update && apt-get install -y openssl sqlite3 curl  

# Install all node_modules, including dev dependencies
FROM base AS deps

WORKDIR /app

ADD package.json .npmrc ./
RUN npm install --include=dev

# Setup production node_modules
FROM base AS production-deps

WORKDIR /app

COPY --from=deps /app/node_modules /app/node_modules
ADD package.json .npmrc ./
RUN npm prune --omit=dev

# Build the app
FROM base AS build

WORKDIR /app

COPY --from=deps /app/node_modules /app/node_modules

ADD prisma .
RUN npx prisma generate

ADD . .
RUN npm run build

# Finally, build the production image with minimal footprint
FROM base

ENV DATABASE_URL=file:/data/sqlite.db
ENV PORT="3000"
ENV NODE_ENV="production"
ENV SESSION_SECRET="replace-this-with-a-real-secret-in-production"

# add shortcut for connecting to database CLI
RUN echo "#!/bin/sh\nset -x\nsqlite3 \$DATABASE_URL" > /usr/local/bin/database-cli && chmod +x /usr/local/bin/database-cli

WORKDIR /app

COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/node_modules/.prisma /app/node_modules/.prisma

COPY --from=build /app/build /app/build
COPY --from=build /app/public /app/public
COPY --from=build /app/package.json /app/package.json
COPY --from=build /app/start.sh /app/start.sh
COPY --from=build /app/prisma /app/prisma

# Create data directory for SQLite
RUN mkdir -p /data && chown -R node:node /data
VOLUME /data

# Use non-root user
USER node

# Add health check to verify the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD curl -f http://localhost:3000/ || exit 1

# Run migrations and start the application
CMD ["sh", "./start.sh"]

EXPOSE 3000
