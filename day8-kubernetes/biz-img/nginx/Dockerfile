FROM harbor.k8s.com/pub-images/nginx-base:v1.18.0
ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD webapp.tar.gz /usr/local/nginx/html/webapp/
ADD index.html /usr/local/nginx/html/index.html

# 静态资源挂载路径 用于在K8S上创建pod时作为挂载点使用
RUN mkdir -p /usr/local/nginx/html/webapp/static /usr/local/nginx/html/webapp/images

EXPOSE 80 443

CMD ["nginx"]