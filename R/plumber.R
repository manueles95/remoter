# plumber.R
library(plumber)
library(dotenv)
library(logger)

# Try to load .env if it exists, but continue silently if it doesn't
suppressWarnings({
  tryCatch({
    if (file.exists(".env")) {
      load_dot_env(file = ".env")
      message("Loaded .env file")
    } else {
      message("No .env file found, using environment variables")
    }
  }, error = function(e) {
    message("Could not load .env file, using environment variables")
  })
})

#* @apiTitle R Plumber API
#* @apiDescription A simple API that sums two numbers

#* @filter auth
function(req, res) {
  key_req <- req$HTTP_X_API_KEY
  key_env <- Sys.getenv('API_KEY', '')
  if (identical(key_req, '') || key_req != key_env) {
    res$status <- 401
    return(list(error = "Unauthorized: invalid API key."))
  }
  plumber::forward()
}

#* Health check endpoint
#* @get /health
#* @serializer json
function() {
  list(status = "healthy", timestamp = as.character(Sys.time()))
}

#* Sum two numbers
#* @post /modi
#* @serializer json
function(req, res) {
  tryCatch({
    body <- jsonlite::fromJSON(req$postBody)
    a <- as.numeric(body$a)
    b <- as.numeric(body$b)
    
    if (is.na(a) || is.na(b)) {
      res$status <- 400
      return(list(error = "Both 'a' and 'b' must be numbers."))
    }
    
    result <- a + b
    message(sprintf("Computed sum %s + %s = %s", a, b, result))
    list(result = result)
  }, error = function(e) {
    res$status <- 400
    list(error = "Invalid request body. Expected JSON with 'a' and 'b' numeric values.")
  })
}

# Create and configure the router
pr <- plumber::Plumber$new()
pr$handle("GET", "/", function() {
  list(status = "healthy", timestamp = as.character(Sys.time()))
})
pr$handle("POST", "/modi", function(req, res) {
  tryCatch({
    body <- jsonlite::fromJSON(req$postBody)
    a <- as.numeric(body$a)
    b <- as.numeric(body$b)
    
    if (is.na(a) || is.na(b)) {
      res$status <- 400
      return(list(error = "Both 'a' and 'b' must be numbers."))
    }
    
    result <- a + b
    message(sprintf("Computed sum %s + %s = %s", a, b, result))
    list(result = result)
  }, error = function(e) {
    res$status <- 400
    list(error = "Invalid request body. Expected JSON with 'a' and 'b' numeric values.")
  })
})

# Add authentication filter
pr$filter("auth", function(req, res) {
  key_req <- req$HTTP_X_API_KEY
  key_env <- Sys.getenv('API_KEY', '')
  if (identical(key_req, '') || key_req != key_env) {
    res$status <- 401
    return(list(error = "Unauthorized: invalid API key."))
  }
  plumber::forward()
})

# Start the server
host <- Sys.getenv("HOST", "0.0.0.0")
port <- as.integer(Sys.getenv("PORT", 8000))
pr$run(host = host, port = port) 