# plumber.R

#* @apiTitle R Plumber API
#* @apiDescription A simple API that sums two numbers

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

#* Sum two numbers
#* @post /modi
#* @serializer json
function(req, res) {
  tryCatch({
    # Parse request body
    body <- jsonlite::fromJSON(req$postBody)
    
    # Validate required fields
    if (!all(c("a", "b") %in% names(body))) {
      res$status <- 400
      return(list(error = "Request must include both 'a' and 'b' fields"))
    }
    
    # Convert to numeric
    a <- as.numeric(body$a)
    b <- as.numeric(body$b)
    
    # Validate numeric values
    if (is.na(a) || is.na(b)) {
      res$status <- 400
      return(list(error = "Both 'a' and 'b' must be valid numbers"))
    }
    
    # Compute result
    result <- a + b
    message(sprintf("Computed sum %s + %s = %s", a, b, result))
    
    # Return success
    list(result = result)
    
  }, error = function(e) {
    # Log the error
    message(sprintf("Error processing request: %s", e$message))
    
    # Return error response
    res$status <- 400
    list(error = "Invalid request body. Expected JSON with 'a' and 'b' numeric values.")
  })
} 