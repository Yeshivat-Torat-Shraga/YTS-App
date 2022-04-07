# Set the base image to Python 3.10
FROM python:3.10

# Set the PRODUCTION environment variable
ENV PRODUCTION true

# Expose port 80
EXPOSE 80/tcp

# Set the working directory in the container
WORKDIR /app

# Copy the dependencies file to the working directory
COPY requirements.txt .

# Install the dependencies
RUN pip install -r requirements.txt

# Install ffmpeg
RUN apt install -y ffmpeg
# Copy the contents of the local src directory to the working directory
COPY . /app

# Start main.py
CMD ["python", "main.py"]
