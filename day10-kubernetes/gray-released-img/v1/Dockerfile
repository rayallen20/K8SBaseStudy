FROM harbor.k8s.com/pub-images/nginx-base:v1.18.0
ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD gray-released-app.tar.gz /usr/local/nginx/html/
EXPOSE 80 443
CMD ["nginx"]