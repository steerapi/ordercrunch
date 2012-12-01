# $ ->
#   $("<div/>").attr("id","placeholder").width("100%").height("300px").appendTo "body"
#   
#   exports.plotDiscounts "#placeholder", [
#     discount: 10
#     businessName: "Pizza Hut"
#     street_address: "35 Oak st"
#     distance: "10 km"
#   ,
#     discount: 10
#     businessName: "Pizza Hut"
#     street_address: "35 Oak st"
#     distance: "10 km"
#   ,
#     discount: 0
#     businessName: "Pizza Hut"
#     street_address: "35 Oak st"
#     distance: "10 km"
#   ,
#     discount: 10
#     businessName: "Pizza Hut"
#     street_address: "35 Oak st"
#     distance: "10 km"
#   ]

exports.plotDiscounts = (id, businesses)->
  console.log businesses
  total = businesses.length-1
  last = 1+total*2
  data = []
  idx = 0
  labels = []
  for i in [last..1] by -2
    business = businesses[idx++]
    data.push [business.discount,i]
    labels.push
      offset: 
        x: 0
        y: i
      text1: business.businessName
      text2: business.street_address
      text3: business.distance
  plot id, data, labels, (event,pos,item)->
    if item
      console.log item

plot = (id, data, labels, listener)->
  # console.log data
  # console.log [-1..data[0][0]].map (v)-> ""+v
  options =
    yaxis:
      min: 0
      position: "left"
      ticks: []
      # transform: (v)->
        # -v
      autoscaleMargin: 0
    xaxis:
      # ticks: ["-1","-2"]
      # font:
      #   size: 11,
      #   style: "italic",
      #   weight: "bold",
      #   family: "sans-serif",
      #   variant: "small-caps"
      axisLabel: "Discount %"
      # autoscaleMargin: 0.01
      min: -1
      position: "top"
    series:
      bars:
        show: true
        barWidth: 2
        fill: true
        fillOpacity: 1.0
        horizontal: true
        align:"center"
    grid:
      show: true
      clickable: true

  series = [
    color: "#283E70"
    data: data
    xaxis: 2
    yaxis: 1
  ]
  
  placeholder = $(id)
  plot = $.plot placeholder, series, options
  placeholder.bind "plotclick", listener
  
  for label in  labels
    o = plot.pointOffset(label.offset)
    elms = '<div class=".ui-body" style="position:absolute;left:'+(o.left+15)+'px;top:'+(o.top-15)+'px;">'
    elms += "<h1>#{label.text1}</h1>"
    elms += "<p>#{label.text2} (#{label.text3})</p>"
    elms += "</div>"
    placeholder.append elms
