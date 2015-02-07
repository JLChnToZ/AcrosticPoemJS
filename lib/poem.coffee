_ = require 'underscore'

randomItem = (arr, offset = 1) ->
  arr[Math.floor Math.random() * arr.length * offset]

compareProb = (a, b) ->
  b[1].prob - a[1].prob

toItems = (obj) ->
  arr = []
  arr.push [key, value] for key, value of obj
  arr

toDict = (arr, _default = {}) ->
  _.reduce arr, (o, v) ->
    o[v[0]] = v[1]
    o
  , _default

class PoemGen
  gram1 = []
  gram2 = {}
  dict = {}
  yun = {}
  pinjeShun =
    ' ': 0
    '\u02CA': 0
    '\u02C7': 1
    '\u02CB': 1
    '\u02D9': 1
  vwordCount = 200
  vocabTypeDict =
    simple: 10
    medium: 7
    hard: 4

  @loadDict = (dic) =>
    dict = dic
    for key, value of dic
      thisYun = value.yun + pinjeShun[value.shun]
      value.yun = thisYun
      yun[thisYun] = [] unless yun[thisYun]?
      yun[thisYun].push key
    return

  @loadGram1 = (content) ->
    gram1 = content
    return

  @loadGram2 = (content) ->
    gram2 = content
    return

  selectWords = (weight = 1) ->
    resultList = []
    for i in [0...vwordCount]
      resultList.push randomItem(gram1)[0]
    resultList

  viterbiSub2 = (preAry, thisAry, _default = 0.5, offset = 0.01, backward = false) ->
    for tw, twValue of thisAry
      maxProb = 0
      randPw = null
      allTempProb = []
      for pw, pwValue of preAry
        gramStr = if backward then "#{tw} #{pw}" else "#{pw} #{tw}"
        thisProb = gram2[gramStr] ? _default
        tempProbVal = thisProb * pwValue.prob
        tempProb = [pw, tempProbVal]
        if tempProbVal >= maxProb
          randPw = tempProb
          maxProb = tempProbVal
      randPw = tempProb unless randPw?
      twValue.prob = randPw[1]
      if backward
        twValue.word = [].concat [randPw[0]], preAry[randPw[0]].word
      else
        twValue.word = [].concat preAry[randPw[0]].word, [randPw[0]]
    return

  viterbiSub1 = (wordStart, interval, offset = 0.01, backward = false) ->
    preAry = {}
    preAry[wordStart[wordStart.length - 1]] =
      prob: 1
      word: wordStart[0...-1]
    for i in [0...interval]
      wordList = if i is interval - 1 and not backward then selectWords 10 else selectWords()
      ignoreThis = false
      thisAry = {}
      for word in wordList
        thisAry[word] =
          prob: 0
          word: []
      viterbiSub2 preAry, thisAry, null, null, backward
      preAry = thisAry
    preAry

  viterbi = (wordStartRaw, length, itvalBackward = 0, offset = 0.01) ->
    itvalAll = length - 1
    itvalForward = itvalAll - itvalBackward
    wordStart = [wordStartRaw]
    if itvalBackward >= 1
      preAryBackward = toItems viterbiSub1 wordStart, itvalBackward, null, true
      preAryBackward.sort compareProb
      randPw = randomItem preAryBackward, offset
      wordStart = [].concat [randPw[0]], randPw[1].word
    viterbiSub1 wordStart, itvalForward

  constructor: ->
    @reset()

  reset: ->
    @length = 0
    @vocabType = 10
    @itvalBackward = 0
    @itvalSlash = null
    return

  genPoemYun: (wordYun, itvalDict, offset = 0.01) ->
    yunAry = {}
    for y, yValue of yun
      yunAry[y] = []
      for i in [0...wordYun.length]
        yunAry[y].push
          prob: 0
          word: []
          lastWord: []
    for wStart, i in wordYun
      preAry = viterbi wStart, @length, itvalDict[i]
      for w of preAry
        yun = dict[w].yun
        lastWordAry = _.reduce (yunAry[yun][j].word[-1...] for j in [0..i]), ((x, y) -> x.concat y), []
        if preAry[w].prob > yunAry[yun][i].prob and lastWordAry.indexOf(w) < 0
          yunAry[yun][i].prob = preAry[w].prob
          yunAry[yun][i].word = preAry[w].word.concat [w]
    yunKeyAry = []
    for yun, yunValue of yunAry
      yunProbProduct = _.reduce _.map(yunAry[yun], (x) -> x.prob), ((x, y) -> x * y), 1
      yunProbNotEmpty = _.reduce _.map(yunAry[yun], (x) -> x.word.length isnt 0), (x, y) -> x and y
      yunKeyAry.push [yun, yunProbProduct] if yunProbNotEmpty
    yunKeyAry.sort (a, b) -> b[1] - a[1]
    resultYunKey = randomItem yunKeyAry, offset
    resultRaw = yunAry[resultYunKey[0]]
    resultAry = []
    resultAry.push [i, rsl.word] for rsl, i in resultRaw
    toDict resultAry, []

  genPoemNonYun: (wordNoYun, itvalDict, offset = 0.01) ->
    resultAry = []
    for wStart, i in wordNoYun
      preAry = toItems viterbi wStart, @length, itvalDict[i]
      preAry.sort compareProb
      randPw = randomItem preAry, offset
      resultAry.push [i, randPw[1].word.concat [randPw[0]]]

    toDict resultAry, []

  genPoem: (rawStr, slash = false) ->
    wordYun = []
    wordNoYun = []
    wordIdxList = []
    itvalDictYun = {}
    itvalDictNoYun = {}
    hasYun = false
    unless @itvalSlash
      itvalVal = (@itvalBackward for i in [0...rawStr.length])
    else
      lenId = @length
      if @itvalSlash is 'lr'
        itvalVal = (i % lenId for i in [0...rawStr.length])
      else if @itvalSlash is 'rl'
        itvalVal = (lenId - 1 - i % lenId for i in [0...rawStr.length])
    for word, i in rawStr
      if i % 2 isnt 0 and (@length - 1) isnt itvalVal[i]
        wordIdxList.push [wordYun.length, 'yun']
        itvalDictYun[wordYun.length] = itvalVal[i]
        wordYun.push word
        hasYun = true
      else
        wordIdxList.push [wordNoYun.length, 'nonyun']
        itvalDictNoYun[wordNoYun.length] = itvalVal[i]
        wordNoYun.push word
    resultYun = @genPoemYun wordYun, itvalDictYun if hasYun
    resultNoYun = @genPoemNonYun wordNoYun, itvalDictNoYun
    resultList = []
    for [idx, typ] in wordIdxList
      if typ is 'yun'
        resultList.push resultYun[idx]
      else if typ is 'nonyun'
        resultList.push resultNoYun[idx]
    resultList

  generate: (inputStr, length = 5, position = '1', vocab = 'simple') ->
    @length = length
    @vocabType = vocabTypeDict[vocab]
    if position of (x.toString() for x in [1..8])
      @itvalBackward = parseInt(position) - 1
      if @itvalBackward >= @length
        throw 'Position is too large.'
    else
      @itvalSlash = position
    result = @genPoem inputStr.split ''
    @reset()
    result2 = []
    for x in result
      result2.push x.join ''
    result2.join '\n'

module.exports = PoemGen
