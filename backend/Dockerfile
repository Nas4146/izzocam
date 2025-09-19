# Build and run the IzzoCam backend on Cloud Run
FROM node:20-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY . .

# Debug: Show what we copied
RUN ls -la

# Run build with verbose output
RUN npm run build 2>&1

# Check if dist folder was created and list contents recursively
RUN ls -la dist/ && find dist/ -name "*.js"

# Verify the index.js file exists and is executable
RUN test -f dist/index.js || (echo "dist/index.js not found! Contents:" && find dist/ -type f && exit 1)

ENV NODE_ENV=production
ENV PORT=8080

CMD ["node", "dist/index.js"]
