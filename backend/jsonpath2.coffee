vm = require('vm')
_ = require('underscore')
class JSONPath
  constructor: ->
    @cache = {}
  eval:(obj, expr, arg, replace)->
    P =
      mod: (if (arg and arg.hasOwnProperty("mod")) then arg.mod else true)
      resultType: arg and arg.resultType or "VALUE"
      flatten: arg and arg.flatten or false
      wrap: (if (arg and arg.hasOwnProperty("wrap")) then arg.wrap else false)
      sandbox: (if (arg and arg.sandbox) then arg.sandbox else {})
      normalize: (expr) =>
        return @cache[expr]  if @cache[expr]
        subx = []
        ret = expr.replace(/[\['](\+?\(.*?\))[\]']/g, ($0, $1) ->
          "[#" + (subx.push($1) - 1) + "]"
        ).replace(/'?\.'?|\['?/g, ";").replace(/;;;|;;/g, ";..;").replace(/;$|'?\]|'$/g, "").replace(/#([0-9]+)/g, ($0, $1) ->
          subx[$1]
        )
        @cache[expr] = ret
        ret
  
      asPath: (path)  =>
        x = path.split(";")
        p = "$"
        i = 1
        n = x.length
  
        while i < n
          p += (if /^[0-9*]+$/.test(x[i]) then ("[" + x[i] + "]") else ("['" + x[i] + "']"))
          i++
        p
  
      store: (p, v, parent, idx) ->
        
        # console.log("store", v);
        # console.log(obj);
        
        # if(replace instanceof Array){
        #   console.log(replace);
        #   var x = replace.shift();
        #   console.log(x);
        #   parent[idx] = x;
        # }else{
        # console.log("replace");
        parent[idx] = replace  if replace
        
        # }
        if p
          if P.resultType is "PATH"
            P.result[P.result.length] = P.asPath(p)
          else
            if _.isArray(v) and P.flatten
              
              # console.log("out2");
              P.result = []  unless P.result
              P.result = [P.result]  unless _.isArray(P.result)
              P.result = P.result.concat(v)
            else
              
              # console.log("out3", P.result);
              if P.result
                P.result = [P.result]  unless _.isArray(P.result)
                if _.isArray(v) and P.flatten
                  P.result = P.result.concat(v)
                else
                  
                  # P.result[P.result.length] = v;
                  P.result = P.result.concat([v])
              else
                P.result = v
        
        # console.log(obj);
        !!p
  
      trace: (expr, val, path, parent, idx) ->
        
        #console.log("expr",expr,"mod",P.mod);
        if expr
          x = expr.split(";")
          loc = x.shift()
          next = x[0]
          x = x.join(";")
          
          # console.log("val", val, loc, val.hasOwnProperty(loc));
          if val and val.hasOwnProperty(loc)
            
            # console.log("hasOwn", val, loc);
            P.trace x, val[loc], path + ";" + loc, val, loc
          else if loc is "*"
            P.walk loc, x, val, path, (m, l, x, v, p) ->
              P.trace m + ";" + x, v, p, parent, idx
  
          else if loc is ".."
            P.trace x, val, path, parent, idx
            P.walk loc, x, val, path, (m, l, x, v, p) ->
              
              # console.log("recur",next, v,m);
              # if (replace) {
              #               if (next) {
              #                 if (/^\d+$/.test(next)) {
              #                   v[m] = [];
              #                 } else {
              #                   v[m] = {};
              #                 }
              #               }
              #             }
              typeof v[m] is "object" and P.trace("..;" + x, v[m], p + ";" + m, v, m)
  
          else if /,/.test(loc) # [name1,name2,...]
            s = loc.split(/'?,'?/)
            i = 0
            n = s.length
  
            while i < n
              P.trace s[i] + ";" + x, val, path, parent, idx
              i++
          else if /^\(.*?\)$/.test(loc) # [(expr)]
            P.trace P.eval(loc, val, path.substr(path.lastIndexOf(";") + 1)) + ";" + x, val, path, parent, idx
          else if /^\+\(.*?\)$/.test(loc) # [?(expr)]
            P.walk loc, x, val, path, (m, l, x, v, p) ->
              P.trace m + ";" + x, v, p, parent, idx  if P.eval(l.replace(/^\+\((.*?)\)$/, "$1"), v[m], m)
  
          else if /^(-?[0-9]*):(-?[0-9]*):?([0-9]*)$/.test(loc) # [start:end:step]  phyton slice syntax
            P.slice loc, x, val, path, parent, idx
          else if replace and P.mod
            
            # console.log("expr",expr);
            # console.log("replace", val, loc, arguments, x);
            # console.log("next",next);
            if next and not val[loc]
              if /^\d+$/.test(next)
                
                # console.log("array");
                val[loc] = []
              else
                
                # console.log("object");
                val[loc] = {}
            P.trace x, val[loc], path + ";" + loc, val, loc
        else
          P.store path, val, parent, idx
  
      walk: (loc, expr, val, path, f) ->
        if val instanceof Array
          i = 0
          n = val.length
  
          while i < n
            f i, loc, expr, val, path  if i of val
            i++
        else if typeof val is "object"
          for m of val
            f m, loc, expr, val, path  if val.hasOwnProperty(m)
  
      slice: (loc, expr, val, path, parent, idx) ->
        if val instanceof Array
          len = val.length
          start = 0
          end = len
          step = 1
          loc.replace /^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$/g, ($0, $1, $2, $3) ->
            start = parseInt($1 or start)
            end = parseInt($2 or end)
            step = parseInt($3 or step)
  
          start = (if (start < 0) then Math.max(0, start + len) else Math.min(len, start))
          end = (if (end < 0) then Math.max(0, end + len) else Math.min(len, end))
          i = start
  
          while i < end
            P.trace i + ";" + expr, val, path, parent, idx
            i += step
  
      eval: (x, _v, _vname) ->
        P.sandbox["_v"] = _v
        try
          return $ and _v and vm.runInNewContext(x.replace(/@/g, "_v"), P.sandbox)
        catch e
          console.log e
          throw new SyntaxError("jsonPath: " + e.message + ": " + x.replace(/@/g, "_v").replace(/\^/g, "_a"))
  
    P.result = (if P.wrap is true then [] else `undefined`)
    
    # console.log(P.wrap);
    $ = obj
    if expr and obj and (P.resultType is "VALUE" or P.resultType is "PATH")
      P.trace P.normalize(expr).replace(/^\$;/, ""), obj, "$"
      P.result = [P.result]  if not _.isArray(P.result) and P.wrap
      (if P.result then P.result else false)    

module.exports = JSONPath