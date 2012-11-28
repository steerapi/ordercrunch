locuKey = "a231808077ef79fabb66e7f7fd315263278f8d99"
http = require("http")

exports.register = (app,requiresLogin)->
  # 3. Locu search by name
  app.get "/locu/api/v1/venue/search/", requiresLogin, (req,res)->
    # console.log req._parsedUrl.search
    req = http.request
      method: "GET"
      host: "api.locu.com"
      path: "http://api.locu.com/v1_0/venue/search/#{req._parsedUrl.search}&api_key=#{locuKey}"
    , (httpres)->
      buffer = ""
      httpres.on "data", (chunk)->
        # console.log buffer
        buffer+=chunk
      httpres.on "end", (chunk)->
        # console.log buffer
        try
          obj = JSON.parse buffer
          # console.log obj
          # val = extract(obj, req.params[0])
          res.send obj
        catch err
          res.send 404
    req.end()
