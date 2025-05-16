FROM rocker/r-ver:4.3.0

# Install system dependencies and R packages as root
USER root
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libsodium-dev \
    zlib1g-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && R -e "install.packages(c('plumber','dotenv','logger','jsonlite'), repos='https://cloud.r-project.org')"

# Create non-root user with specific UID/GID
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/bash -m appuser

# Set working directory
WORKDIR /app

# Copy application files
COPY --chown=appuser:appgroup R/ /app/R/

# Set permissions
RUN chown -R appuser:appgroup /app && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Start the API with better error handling
CMD ["R", "-e", "tryCatch({ \
    library(plumber); \
    library(dotenv); \
    library(logger); \
    library(jsonlite); \
    logger::log_threshold(logger::INFO); \
    message('Starting plumber API...'); \
    pr <- plumb('/app/R/plumber.R'); \
    message('Plumber loaded successfully, starting server...'); \
    pr$run(host='0.0.0.0', port=8000) \
}, error = function(e) { \
    message(sprintf('Error starting server: %s', e$message)); \
    quit(status=1) \
})"] 