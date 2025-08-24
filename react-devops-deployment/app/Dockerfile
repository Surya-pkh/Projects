# Stage 1: Build React app
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --only=production --silent

# Copy all source and build
COPY . .
RUN npm run build

# Stage 2: Nginx for serving
FROM nginx:1.21-alpine

# Install curl for healthcheck
RUN apk --no-cache add curl

# Copy built React app
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom Nginx config (make sure it's a server block)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

