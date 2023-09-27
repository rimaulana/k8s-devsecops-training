FROM public.ecr.aws/docker/library/python:3.7-alpine

LABEL maintainer="Rio Maulana"
RUN adduser sasquatch -D

COPY requirements.txt start.sh app /app/

WORKDIR /app
RUN pip install -r requirements.txt

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 5000

USER sasquatch

CMD ./start.sh