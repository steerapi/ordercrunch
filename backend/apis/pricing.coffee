http = require("http")
require('date-utils')
Usergrid = require "../usergrid"
moment = require "moment"
format = require "./format"
formatTime = format.formatTime
  
formatDate = "MM/DD/YYYY"
formatDateTime = "MM/DD/YYYYhh:mm"
async = require "async"

# date = "11/26/2012"
# shift = "11:01 PM"
# interval = ["10:00 PM","11:00 PM"]
# day = moment date, formatDate
# st = moment "#{date}#{interval[0]}", formatDateTime
# et = moment "#{date}#{interval[1]}", formatDateTime
# time = moment "#{date}#{shift}", formatDateTime
# time.toDate().between st.toDate(), et.toDate()

# Given "HH:MMA" make interval
t2i = (time)->
  day = moment(time,formatTime)
  hr = day.hours()
  min = day.minutes()
  (hr*4)+(Math.floor min/15)

i2t = (interval)->
  a = moment().sod()
  a.add('minutes', interval*15)
  a.format(formatTime)

# moment = require "moment"
# day = moment("01/26/201210:12 PM",formatDateTime)
# console.log day.hours()
# console.log day.minutes()
# console.log day.date()
# console.log day.month()
# console.log day.year()

getPastOrders = (buuid, interval, scb,ecb)->
  d = new Date()
  d.add
    days: -30
  time = d.getTime()
  params = 
    ql: "select * where orderedAt > #{time} and to.uuid = '#{buuid}' and interval = #{interval}"
    limit: 1000
  query = new Usergrid.Query "GET", "orders", null, params, scb, ecb
  Usergrid.ApiClient.runAppQuery query

getPredictedAvgTime = (business, interval, cb)->
  console.log "getPredictedAvgTime", arguments
  prepBusiness business, (err,buuid,business)->
    #console.log "getPredictedAvgTime", arguments
    buuid = business._data.uuid
    (cb err;return) if err
    getPastOrders buuid, interval, (response)->
      console.log "getPredictedAvgTime", arguments
      orders = response.entities
      totaltime = 0
      totalOrders = orders.length
      for order in orders
        if order.orderedAt and order.completedAt
          tstart = moment.unix order.orderedAt
          tend = moment.unix order.completedAt
          totaltime += tend.diff tstart, 'minutes'
        else
          totalOrders--
      avgtime = totaltime/totalOrders
      suggest business
        avgtime: avgtime
      # if have enough data
      predicted = null
      if orders.length > 100
        predicted = avgtime
      else
        predicted = business._data.avgtime
      cb null,predicted
    ,->
      cb "error"

getPredictedOrders = (business, interval, cb)->
  console.log "getPredictedOrders", arguments
  prepBusiness business, (err,buuid,business)->
    (cb err;return) if err
    getPastOrders buuid, interval, (response)->
      orders = response.entities
      past = orders.length
      avgpast = past/30
      # Suggested new max orders
      ####################################
      months = []
      for order in orders
        day = moment.unix order.orderedAt
        months[day.date()]?=0
        months[day.date()]++
      newmax = Math.max months 
      suggest business,
        maxorders: newmax
      ####################################
      # if have enough data
      predicted = null
      if orders.length > 100
        predicted = avgpast
      else
        predicted = 0.5*business._data.maxorders
      cb null, predicted
    , ->
      cb "error"

getBusiness = (buuid, cb)->
  entity = new Usergrid.Entity "businesses", buuid
  entity.fetch ->
    cb null, entity, entity._data

isOpen = (business)->
  today = moment()
  dow = today.format "dddd"
  time = today.format formatTime
  open = false
  for odow,intervals in business._data.open_hours
    if odow==dow and intervals?.length == 2
      if checkBetween time, intervals
        open = true
        break
  return open
  
prepBusiness = (business, cb)->
  if not business
    cb "error"
  # console.log "prepBusiness", arguments
  buuid = null
  #check if it is valid for discount
  checkValid = (business)->
    d = business._data
    # return isOpen(business) and d.maxdiscount and d.maxorders and d.avgtime and d.maxemployee
    return d.maxdiscount and d.maxorders and d.avgtime and d.maxemployee
    # return true
  if business instanceof Usergrid.Entity
    (cb "error";return) if not checkValid(business)
    buuid = business.get "uuid"
    cb null, buuid, business
  else
    getBusiness business, (err, entity, data)->
      (cb err;return) if err and not checkValid(entity)
      business = entity
      buuid = data.uuid
      cb null, buuid, business

getAll = (collection, donecb)->
  console.log "getAll", arguments
  # collection = new Usergrid.Collection path
  alldata = []
  collection.fetch (response)->
    collection.resetEntityPointer()
    while collection.hasNextEntity()
      entity = collection.getNextEntity()
      alldata.push entity._data
    if collection.hasNextPage()
      collection.getNextPage()
    else
      donecb?(null, alldata)
  , ->
    donecb? "error"
  
getEmployees = (business,cb)->
  console.log "getEmployees", arguments
  prepBusiness business, (err, buuid, business)->
    collection = new Usergrid.Collection "businesses/#{buuid}/employees"
    getAll collection, (err, data)->
      cb(err, data)
    # params = 
    #   ql: "select * where orderedAt > #{time} and to.uuid = '#{buuid}' and interval = #{interval}"
    #   limit: 1000
    # scb = (response)->
    #   response.entities
    # ecb = ->
    #   cb "error"
    # query = new Usergrid.Query "GET", "businesses/#{buuid}/employees", null, params, scb, ecb
    # Usergrid.ApiClient.runAppQuery query
  
getInfraOrderCapacity = (business, interval, cb)->
  console.log "getInfraOrderCapacity", arguments
  prepBusiness business, (err,buuid,business)->
    (cb err;return) if err
    cb null, business._data.maxorders

getLaborCapacity = (business, interval, cb)->
  console.log "getLaborCapacity", arguments
  prepBusiness business, (err,buuid,business)->
    (cb err;return) if err
    maxemployee = business._data.maxemployee
    totaltime = 15 # in min
    avgtime = business._data.avgtime # in min
    console.log "maxemployee", maxemployee
    getCurrentEmployees business,interval,(err,currentemployee)->
      (cb err;return) if err
      if currentemployee > maxemployee
        suggest business,
          maxemployee: currentemployee
      avgtime = null
      getPredictedAvgTime business, interval, (err, pavgtime)->
        console.log "LABOR", arguments
        (cb err;return) if err
        avgtime = pavgtime

        console.log "currentemployee",currentemployee
        console.log "avgtime",avgtime
        console.log "totaltime",totaltime
        console.log "maxemployee",maxemployee
        
        cb null, totaltime/avgtime*currentemployee/maxemployee

checkBetween = (interval, intevals)->
  st = moment "#{intevals[0]}", formatTime
  et = moment "#{intevals[1]}", formatTime
  time = moment "#{interval}", formatTime
  return time.toDate().between st.toDate(), et.toDate()

# intervals = ["10:00 PM","11:00 PM"]
# console.log checkBetween "10:15 AM", intervals

getCurrentEmployees = (business, inte, cb)->
  console.log "getCurrentEmployees", arguments
  prepBusiness business, (err,buuid,business)->
    (cb err;return) if err
    today = moment()
    todayStr = today.format formatDate
    getEmployees business, (err,employees)->
      count = 0
      for employee in employees
        present = false
        for date,intervals in employee.specialHours
          if todayStr==date and intervals.length == 2
            if checkBetween i2t(inte), intervals
              present = true
              break
        for dow,intervals in employee.regularHours
          if intervals.length == 2
            if checkBetween i2t(inte), intervals
              present = true
              break
        if present
          count++
      if count==0
        count = business._data.maxemployee
      cb(null, count)

_ = require "underscore"
suggest = (business, data)->
  business._data.suggestions?={}
  _.extend business._data.suggestions, data
  business.save()

getOrderCapacity = (business, interval, cb)->
  console.log "getOrderCapacity", arguments
  getInfraOrderCapacity business, interval, (err, icap)->
    (cb err;return) if err
    console.log "icap", icap
    getLaborCapacity business, interval, (err, lcap)->
      (cb err;return) if err
      console.log "lcap", lcap
      if lcap < icap
        # Over estimate max # of order
        suggest business,
          hireMore:true
      else
        # Under estimate max # of order
        suggest business,
          openNew:true
      cb null, Math.min icap, lcap

getDiscount = (business, interval, cb)->
  console.log "getDiscount", arguments
  prepBusiness business, (err,buuid,business)->
    (cb err;return) if err
    getOrderCapacity business, interval, (err, capacity)->
      (cb err;return) if err
      getPredictedOrders business, interval, (err, predicted)->
        (cb err;return) if err
        console.log "cap",capacity
        console.log "pred",predicted
        u = predicted/capacity
        max = business._data.maxdiscount
        #linear discount function
        d = -max*u+max
        console.log "max:",max
        console.log "U:",u
        console.log "D:",d
        cb null, Math.min max,Math.max(d,0), business

# getDiscount "1a370b02-3983-11e2-87fc-02e81ac5a17b", 10, (err,discount)->
#   console.log "DISCOUNT", discount

exports.register = (app,requiresLogin)->
  app.get "/api/v1/discounts", (req,res)->
    name = req.query.name
    inte = req.query.interval
    params = 
      ql: "select * where businessName contains '#{name}*'"
    scb = (response)->
      console.log response
      discounts = []
      d = 0
      async.forEachSeries response.entities, (entity, cb)->
        prepBusiness entity.uuid, (err,buuid,business)->
          (cb err;return) if err
          getDiscount business, inte, (err, dval)->
            if err
              dval = 0
            discount =  
              discount: d+=10
            _.extend discount, business._data
            discounts.push discount
            cb()
      , (err)->
        discounts.sort (a,b)->
          return b.discount - a.discount
        res.send discounts
    ecb = ->
      res.send 404
    query = new Usergrid.Query "GET", "businesses", null, params, scb, ecb
    Usergrid.ApiClient.runAppQuery query
    # 
    # # console.log req._parsedUrl.search
    # req = http.request
    #   method: "GET"
    #   host: "api.locu.com"
    #   path: "http://api.locu.com/v1_0/venue/search/#{req._parsedUrl.search}&api_key=#{locuKey}"
    # , (httpres)->
    #   buffer = ""
    #   httpres.on "data", (chunk)->
    #     # console.log buffer
    #     buffer+=chunk
    #   httpres.on "end", (chunk)->
    #     # console.log buffer
    #     try
    #       obj = JSON.parse buffer
    #       # console.log obj
    #       # val = extract(obj, req.params[0])
    #       res.send obj
    #     catch err
    #       res.send 404
    # req.end()
