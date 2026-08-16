FROM node:24-alpine

# Set CI environment variable to bypass interactive TTY prompts for pnpm
ENV CI=true
ENV confirmModulesPurge=false

# Install pnpm inside the container
RUN npm install -g pnpm


WORKDIR /app

# Copy package files first to leverage caching
COPY package.json pnpm-lock.yaml* ./

# Install dependencies (including devDependencies for tsx/typescript watch mode)
RUN pnpm install --no-frozen-lockfile --ignore-scripts

# Copy source code
COPY . .

# Expose the API port
EXPOSE 8005

# Start the Hono app in development watch mode
CMD ["pnpm", "run", "dev"]
