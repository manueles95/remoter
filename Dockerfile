FROM rocker/r-ver:4.3.0

# Create non-root user
RUN useradd --create-home appuser
WORKDIR /home/appuser

# Install system dependencies and R packages as root
USER root
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libsodium-dev \
    zlib1g-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && R -e "install.packages(c('plumber','dotenv','logger','jsonlite'), repos='https://cloud.r-project.org')"

# Switch to non-root user
USER appuser

# Copy only what's needed
COPY --chown=appuser:appuser R/ /home/appuser/R/

# Expose the port the app runs on
EXPOSE 8000

# Start the API
CMD ["R", "-e", "library(plumber); library(dotenv); library(logger); library(jsonlite); pr <- plumb('R/plumber.R'); pr$run(host='0.0.0.0', port=8000)"] 