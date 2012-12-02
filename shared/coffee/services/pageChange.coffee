class PageChange
  constructor: (@rootScope)->
    $(document).bind "pagechange", (e, obj)=>
      if obj.options.fromPage
        from = obj.options.fromPage[0].id
        @rootScope.$broadcast "#{from}Exit"
      to = obj.toPage[0].id
      @rootScope.$broadcast "#{to}"
      @rootScope.$apply()
PageChange.$inject = ["$rootScope"]
app.service "PageChange", PageChange