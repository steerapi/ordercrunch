/* jsonpath-rep 0.0.1 - XPath for JSON with replacement
 * Surat Teerapittayanon
 * Modified from JSONPath 0.9.0 by
 * Copyright (c) 2007 Stefan Goessner (goessner.net)
 * Licensed under the MIT (MIT-LICENSE.txt) licence.
 */

var vm = require('vm'),
    _ = require('underscore');

exports.eval = jsonPath;
var cache = {};

function jsonPath(obj, expr, arg, replace) {
  var P = {
    mod: (arg && arg.hasOwnProperty('mod')) ? arg.mod : true,
    resultType: arg && arg.resultType || "VALUE",
    flatten: arg && arg.flatten || false,
    wrap: (arg && arg.hasOwnProperty('wrap')) ? arg.wrap : false,
    sandbox: (arg && arg.sandbox) ? arg.sandbox : {},
    normalize: function(expr) {
      if (cache[expr]) {
        return cache[expr];
      }
      var subx = [];
      ret = expr.replace(/[\['](\+?\(.*?\))[\]']/g, function($0, $1) {
        return "[#" + (subx.push($1) - 1) + "]";
      }).replace(/'?\.'?|\['?/g, ";").replace(/;;;|;;/g, ";..;").replace(/;$|'?\]|'$/g, "").replace(/#([0-9]+)/g, function($0, $1) {
        return subx[$1];
      });
      cache[expr] = ret;
      return ret;
    },
    asPath: function(path) {
      var x = path.split(";"),
          p = "$";
      for (var i = 1, n = x.length; i < n; i++)
      p += /^[0-9*]+$/.test(x[i]) ? ("[" + x[i] + "]") : ("['" + x[i] + "']");
      return p;
    },
    store: function(p, v, parent, idx) {
      // console.log("store", v);
      // console.log(obj);
      if (replace) {
        // if(replace instanceof Array){
        //   console.log(replace);
        //   var x = replace.shift();
        //   console.log(x);
        //   parent[idx] = x;
        // }else{
        // console.log("replace");
        parent[idx] = replace;
        // }
      }
      if (p) {
        if (P.resultType == "PATH") {
          P.result[P.result.length] = P.asPath(p);
        } else {
          if (_.isArray(v) && P.flatten) {
            // console.log("out2");
            if (!P.result) P.result = [];
            if (!_.isArray(P.result)) P.result = [P.result];
            P.result = P.result.concat(v);
          } else {
            // console.log("out3", P.result);
            if (P.result) {
              if (!_.isArray(P.result)) P.result = [P.result];
              if (_.isArray(v) && P.flatten) {
                P.result = P.result.concat(v);
              } else {
                // P.result[P.result.length] = v;
                P.result = P.result.concat([v]);
              }
            } else {
              P.result = v;
            }
          }
        }
      }
      // console.log(obj);
      return !!p;
    },
    trace: function(expr, val, path, parent, idx) {
      //console.log("expr",expr,"mod",P.mod);
      if (expr) {
        var x = expr.split(";"),
            loc = x.shift(),
            next = x[0];
        x = x.join(";");
        // console.log("val", val, loc, val.hasOwnProperty(loc));
        if (val && val.hasOwnProperty(loc)) {
          // console.log("hasOwn", val, loc);
          P.trace(x, val[loc], path + ";" + loc, val, loc);
        } else if (loc === "*") {
          P.walk(loc, x, val, path, function(m, l, x, v, p) {
            P.trace(m + ";" + x, v, p, parent, idx);
          });
        } else if (loc === "..") {
          P.trace(x, val, path, parent, idx);
          P.walk(loc, x, val, path, function(m, l, x, v, p) {
            // console.log("recur",next, v,m);
            // if (replace) {
            //               if (next) {
            //                 if (/^\d+$/.test(next)) {
            //                   v[m] = [];
            //                 } else {
            //                   v[m] = {};
            //                 }
            //               }
            //             }
            typeof v[m] === "object" && P.trace("..;" + x, v[m], p + ";" + m, v, m);
          });
        } else if (/,/.test(loc)) { // [name1,name2,...]
          for (var s = loc.split(/'?,'?/), i = 0, n = s.length; i < n; i++)
          P.trace(s[i] + ";" + x, val, path, parent, idx);
        } else if (/^\(.*?\)$/.test(loc)) { // [(expr)]
          P.trace(P.eval(loc, val, path.substr(path.lastIndexOf(";") + 1)) + ";" + x, val, path, parent, idx);
        } else if (/^\+\(.*?\)$/.test(loc)) { // [?(expr)]
          P.walk(loc, x, val, path, function(m, l, x, v, p) {
            if (P.eval(l.replace(/^\+\((.*?)\)$/, "$1"), v[m], m)) P.trace(m + ";" + x, v, p, parent, idx);
          });
        } else if (/^(-?[0-9]*):(-?[0-9]*):?([0-9]*)$/.test(loc)) { // [start:end:step]  phyton slice syntax
          P.slice(loc, x, val, path, parent, idx);
        } else if (replace && P.mod) {
          // console.log("expr",expr);
          // console.log("replace", val, loc, arguments, x);
          // console.log("next",next);
          if (next && !val[loc]) {
            if (/^\d+$/.test(next)) {
              // console.log("array");
              val[loc] = [];
            } else {
              // console.log("object");
              val[loc] = {};
            }
          }
          P.trace(x, val[loc], path + ";" + loc, val, loc);
        }
      } else {
        P.store(path, val, parent, idx);
      }
    },
    walk: function(loc, expr, val, path, f) {
      if (val instanceof Array) {
        for (var i = 0, n = val.length; i < n; i++)
        if (i in val) f(i, loc, expr, val, path);
      } else if (typeof val === "object") {
        for (var m in val)
        if (val.hasOwnProperty(m)) f(m, loc, expr, val, path);
      }
    },
    slice: function(loc, expr, val, path, parent, idx) {
      if (val instanceof Array) {
        var len = val.length,
            start = 0,
            end = len,
            step = 1;
        loc.replace(/^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$/g, function($0, $1, $2, $3) {
          start = parseInt($1 || start);
          end = parseInt($2 || end);
          step = parseInt($3 || step);
        });
        start = (start < 0) ? Math.max(0, start + len) : Math.min(len, start);
        end = (end < 0) ? Math.max(0, end + len) : Math.min(len, end);
        for (var i = start; i < end; i += step)
        P.trace(i + ";" + expr, val, path, parent, idx);
      }
    },
    eval: function(x, _v, _vname) {
      P.sandbox["_v"] = _v;
      try {
        return $ && _v && vm.runInNewContext(x.replace(/@/g, "_v"), P.sandbox);
      } catch (e) {
        console.log(e);
        throw new SyntaxError("jsonPath: " + e.message + ": " + x.replace(/@/g, "_v").replace(/\^/g, "_a"));
      }
    }
  };
  P.result = P.wrap === true ? [] : undefined;
  // console.log(P.wrap);
  var $ = obj;
  if (expr && obj && (P.resultType == "VALUE" || P.resultType == "PATH")) {
    P.trace(P.normalize(expr).replace(/^\$;/, ""), obj, "$");
    if (!_.isArray(P.result) && P.wrap) P.result = [P.result];
    return P.result ? P.result : false;
  }
}
