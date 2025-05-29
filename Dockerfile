FROM rocker/geospatial:4.5

# Instala paquetes necesarios adicionales
RUN install2.r --error \
    plumber \
    jsonlite \
    dotenv \
    logger \
    dplyr \
    xgboost \
    PCAmixdata

# Usa el usuario preexistente de la imagen
USER rstudio

# Directorio de trabajo
WORKDIR /app

# Copia los scripts y datos con permisos correctos
COPY --chown=rstudio:rstudio R/ /app/R/
# COPY --chown=rstudio:rstudio data/ /app/data/

# Copia el script de inicio (preparado localmente como archivo)
COPY --chown=rstudio:rstudio start.R /app/start.R

# Asegura permisos
RUN chmod +x /app/start.R && \
    chown -R rstudio:rstudio /app && \
    chmod -R 755 /app

# Puerto expuesto por la API
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# Ejecuta el script al iniciar el contenedor
CMD ["Rscript", "/app/start.R"]
