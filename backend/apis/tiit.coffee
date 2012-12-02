moment = require "moment"
DateUtils = require('date-utils')
format = require "./format"
formatTime = format.formatTime  

exports.t2i = (time)->
  day = moment(time,formatTime)
  hr = day.hours()
  min = day.minutes()
  (hr*4)+(Math.floor min/15)

exports.i2t = (interval)->
  a = moment().sod()
  a.add('minutes', interval*15)
  a.format(formatTime)
