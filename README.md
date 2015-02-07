# AcrosticPoemJS
這是一個使用 CoffeeScript 和 JavaScript 寫成，可運行在 Node.JS 上面的重製版本藏頭詩產生器。
原版在此： https://github.com/ckmarkoh/AcrosticPoem

本程式可以自動產生藏頭詩。

本程式以Ngram為語言模型，先從兩萬首全唐詩中算出Ngram的統計數值，再用Viterbi演算法拼湊出藏頭詩中的每個字，
得出的藏頭詩，看起來很像詩詞但語意未必通順。

# 安裝
此程式需要 Node.JS 運行。

下載後首次運行，請在終端機輸入

```
> npm install
```

待完成下載和安裝所需程式庫後即可運行

```
node index
```

程式預設的接口是在 3838，因此程式啟動後再在瀏覽器輸入 http://localhost:3838 應該可以看到網頁版。

如需修改接聽接口和 IP，請參考和修改 config.json。
