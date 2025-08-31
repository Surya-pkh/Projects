# Production stage with nginx - using pre-built React app
FROM nginx:alpine

# Copy the entire dist folder to nginx html directory
COPY dist/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 3000 (as requested)
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
