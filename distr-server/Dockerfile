
FROM python:3.9-slim

RUN pip install flask

COPY ./distr-server/server.py /app/server.py

WORKDIR /app

EXPOSE 5000

VOLUME /distr

CMD ["python", "server.py"]
