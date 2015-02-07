require("coffee-script/register");
var ssd = require("start-stop-daemon");
var http = require("http");
var argv = require("argv");
var jsonfile = require("jsonfile");
var express = require("express");
var minify = require("express-minify");
var compression = require("compression");
var bodyParser = require("body-parser");

var poemGen = require('./lib/poem');
var forceGC = require('./lib/forcegc');

ssd(function() {
  var app = express();
  var httpserv = http.Server(app);
  var config = {};
  var runIP;
  var runPort;
  var isLoaded = 0;
  var args = argv.option([
    {
      name: "port",
      short: "p",
      type: "int",
      description: "(Optional) which port will the server runs on."
    }, {
      name: "ip",
      short: "ip",
      type: "string",
      description: "(Optional) which ip will the server runs on."
    }
  ]).run();
  app.use(bodyParser.urlencoded({ extended: false }));
  app.use(compression());
  app.use(minify());
  app.post("/generate", function(req, res) {
    try {
      var poem = new poemGen();
      res.send(poem.generate(req.body.word, req.body.length, req.body.pos, req.body.vocab));
      delete poem;
      forceGC();
    } catch(err) {
      console.log(err.stack);
      res.status(500).send(err.toString());
    }
  });
  app.use(express.static(__dirname + "/static"));
  jsonfile.readFile("./data/word_dict.json", function(err, content) {
    if(err) console.log(err.stack);
    poemGen.loadDict(content);
    isLoaded++;
    startServerIfLoaded();
  });
  jsonfile.readFile("./data/gram1.json", function(err, content) {
    if(err) console.log(err.stack);
    poemGen.loadGram1(content);
    isLoaded++;
    startServerIfLoaded();
  });
  jsonfile.readFile("./data/gram2.json", function(err, content) {
    if(err) console.log(err.stack);
    poemGen.loadGram2(content);
    isLoaded++;
    startServerIfLoaded();
  });
  jsonfile.readFile("./config.json", function(err, cfg) {
    if(err) console.log(err.stack);
    if(cfg) config = cfg;
    runPort = args.options.port || config.port || process.env.PORT || 3838;
    runIP = args.options.ip || config.ip || process.env.IP || "0.0.0.0";
    isLoaded++;
    startServerIfLoaded();
  });
  function startServerIfLoaded() {
    if(isLoaded < 4) return;
    forceGC();
    httpserv.listen(runPort, runIP, function() {
      console.log("Server listening on " + runIP + ":" + runPort);
    });
  }
});
