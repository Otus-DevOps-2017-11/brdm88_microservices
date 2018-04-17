# Post service Dockerfile

FROM python:3.6.0-alpine

# Set Workdir and copy the code
WORKDIR /app
COPY . /app

# Install dependencies
RUN pip install flask pymongo \
&& pip install -r /app/requirements.txt

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

CMD ["python3", "post_app.py"]
