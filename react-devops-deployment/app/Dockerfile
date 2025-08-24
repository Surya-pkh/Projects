# Stage 1: Build React app
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production --silent

COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:1.21-alpine

RUN apk --no-cache add curl

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
