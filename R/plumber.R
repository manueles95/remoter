# plumber.R

#* @apiTitle R Plumber API
#* @apiDescription An api that estimates probability of land use for any parcel in Mexico City

#* @filter auth
function(req, res) {
  # Get API key from request header
  key_req <- req$HTTP_X_API_KEY
  if (is.null(key_req)) key_req <- ""
  
  # Get API key from environment
  key_env <- Sys.getenv('API_KEY', '')
  
  # Check if API key is configured
  if (identical(key_env, '')) {
    res$status <- 500
    return(list(error = "Server configuration error: API_KEY not set"))
  }
  
  # Check if request has valid API key
  if (identical(key_req, '') || key_req != key_env) {
    res$status <- 401
    return(list(error = "Unauthorized: invalid API key"))
  }
  
  plumber::forward()
}

#* Health check endpoint
#* @get /
#* @serializer json
function() {
  list(
    status = "healthy",
    timestamp = as.character(Sys.time()),
    version = "1.0.0"
  )
}

# CARGA DE LIBRERÍAS
message("Cargando librerías...")
library(dplyr)
library(plumber)
library(sf)
library(xgboost)
library(PCAmixdata)

# Path a insumos dentro del Docker para el modelo (bases de datos y objetos .rds)
message("Verificando existencia de archivos...")
if (!file.exists("/app/volumes/cdmx_predios.shp")) stop("Falta el archivo cdmx_predios.shp")
if (!file.exists("/app/volumes/pcamix6.rds")) stop("Falta el archivo pcamix6.rds")
if (!file.exists("/app/volumes/best_model_xgboost6.rds")) stop("Falta el archivo best_model_xgboost6.rds")
if (!file.exists("/app/volumes/model_metadata6.rds")) stop("Falta el archivo model_metadata6.rds")
if (!file.exists("/app/volumes/pipeline_predict_uso_sue6.rds")) stop("Falta el archivo pipeline_predict_uso_sue6.rds")

message("Leyendo archivos...")
tryCatch({
  message("Leyendo predios ")
  gdf_predios      <- st_read("/app/volumes/cdmx_predios.shp", quiet = TRUE)
  message("Leyendo PCAobjects...")
  pcamix_object    <- readRDS("/app/volumes/pcamix6.rds")
  message("Leyendo xgbmodel...")
  xgb_model        <- readRDS("/app/volumes/best_model_xgboost6.rds")
  message("Leyendo modelmetadata...")
  model_metadata   <- readRDS("/app/volumes/model_metadata6.rds")
  message("Leyendo pipeline predict...")
  pipeline_predict <- readRDS("/app/volumes/pipeline_predict_uso_sue_docker.rds")
  message("¡Todo cargado exitosamente!")
}, error = function(e) {
  message("⚠️ Error al cargar los archivos: ", e$message)
  quit(status = 1)
})




# ENDPOINT
#* @post /modi
#* @param lat:double
#* @param lon:double
function(req, res, lat, lon) {
  tryCatch({
    lat <- as.numeric(lat)
    lon <- as.numeric(lon)

    X_num_model <- c(
      'superficie','area_libre',
      
      'metrobus_e','metrobus_1','metrobus_2','stc_metro_','stc_metr_1','stc_metr_2',
      'ste_troleb','ste_trol_1','ste_trol_2','ste_cableb','ste_cabl_1','ste_cabl_2',
      'ste_trenli','ste_tren_1','ste_tren_2',
      
      'min_met',   'ag_gas_cse','construc',  'inst_hs_g', 'el_p_alim', 'com_beb',   'com_moda',  'fab_meq_ot','fa_co_hog', 'impresion', 'r_m_meq',  
      'com_indust','electr',    'com_med',   'joyas',     'com_depo',  'otros',     'com_beb_m', 'papelerias','com_libros','com_meq_m', 'telecom',  
      'com_auto',  'com_tec',   'org',       'transp',    's_prof',    'pub_med',   'bodega',    'dis_edic',  'museos_bib','alq_bien',  'alq_meq_ot',
      'laboratori','ed_bms_pr', 'ed_bms_pu', 'ed_eyo',    'ed_s_pr',   'ed_s_pu',   'educ_extra','educ_esp',  'hosp_c_pyp','serv_ass',  'guard_pyp',
      'com_recr',  'hoteles',   'r_auto',    'cerrajeria','sanit',     'estac_san', 'entr_jug',  'banca',     'residuos',  
      
      'homicidio', 'les_armas',
      'robo_casa', 'robo_neg',  'robo_tran', 'robo_veh',  'robo_mbus', 'robo_metro','violacion', 'robo_rep',  'robo_ctah', 'robo_taxi', 'robo_trans',
      'secuestro', 'bajo_imp', 
      
      'dist_centr','dist_prima','dist_secon','dist_terti','dist_Metro','dist_STC_M','lat_centro','lon_centro','longitud_x','latitud_x',
      
      'POBTOT',    'POBFEM',    'POBMAS', 'POB0_14','P15A29A',   'P30A59A',   'P_60YMAS', 'PRES2015',     'VIVTOT', 
      'POCUPADA',    'PDER_SS','GRAPROES', 'VPH_DREN' #'VPH_BICI','VPH_MOTO','PROM_HNV', 'PRESOE15','VPH_AUTOM'
    )
    
    
    X_cat <- c(
      'RECUCALL_D','RAMPAS_D',  'BANQUETA_D','GUARNICI_D','ALUMPUB_D',  'LETRERO_D',
      'TELPUB_D',  'ARBOLES_D', 'DRENAJEP_D','TRANSCOL_D','ACESOPER_D', 'ACESOAUT_D',
      'PUESSEMI_D','PUESAMBU_D','CICLOVIA_C',
      'NOM_MUN','uso_sue'
    )
    
    # Eliminamos 'uso_sue' de X_cat, porque será la variable objetivo
    X_cat_no_uso <- setdiff(X_cat, "uso_sue")
    
    # Otras listas auxiliares (por ejemplo, las socioeconómicas)
    socioeconomicas_predios <- c('P30A59A','P_60YMA','POCUPAD','GRAPROES_')
    
    resultado <- pipeline_predict(
      lat            = lat,
      lon            = lon,
      gdf            = gdf_predios,
      pcamix_object  = pcamix_object,
      xgb_model      = xgb_model,
      model_metadata = model_metadata,
      k              = 5
    )
    
    list(prediccion_actual = resultado$actual)
  }, error = function(e) {
    res$status <- 500
    list(error = paste("Error interno:", e$message))
  })
}


    