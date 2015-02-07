(function(m) {
  var hasGC = global && global.gc && setImmediate;
  function forceGC() {
    global.gc();
  }
  m.exports = function() {
    if(hasGC)
      setImmediate(forceGC);
  };
})(module);
