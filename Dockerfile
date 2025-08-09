FROM public.ecr.aws/nginx/nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy your built files to nginx web root  
COPY ./Brain-Tasks-App/dist /usr/share/nginx/html

# Remove default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Create custom nginx configuration for port 3000
RUN echo 'server { listen 3000; server_name localhost; root /usr/share/nginx/html; index index.html index.htm; location / { try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
