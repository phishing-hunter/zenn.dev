---
title: "ChatGPTプラグインの機能をいち早く試すには"
emoji: "🤖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
- langchain
- chatgpt
- openai
- docker
published: false
---

## はじめに
ChatGPTの機能を拡張するためのツール[ChatGPT plugins](https://openai.com/blog/chatgpt-plugins)が一部の開発者向けにリリースされました。  
:::message
まだ2023年3月28日時点ではアルファー版であり一般には公開されていません。
:::
しかし、プラグインを作るための仕様は公開されているので、今のうちに使い方を確認しておいて一般公開されたら自作プラグインをすぐに実行できるように準備しておきましょう。

## プラグインの実装方法
実装方法はとてもシンプルで、以下のようなAPIの仕様書を記載したURLとAPIに関する説明などを記載したjsonを用意するだけです。  
```json
{
  "schema_version": "v1",
  "name_for_model": "KlarnaProducts",
  "name_for_human": "Klarna Shopping",
  "description_for_human": "Search and compare prices from thousands of online shops",
  "description_for_model": "Use the Klarna plugin to get relevant product suggestions for any shopping or researching purpose. The query to be sent should not include stopwords like articles, prepositions and determinants. The api works best when searching for words that are related to products, like their name, brand, model or category. Links will always be returned and should be shown to the user.",
  "api": {
    "type": "openapi",
    "url": "https://www.klarna.com/us/shopping/public/openai/v0/api-docs/",
    "has_user_authentication": false
  },
  "auth": {
    "type": "none"
  },
  "logo_url": "https://www.klarna.com/assets/sites/5/2020/04/27143923/klarna-K-150x150.jpg",
  "contact_email": "openai-products@klarna.com",
  "legal_info_url": "https://www.klarna.com/us/legal/"
}
```

ChatGPTやGPT4はこれらの仕様書を理解し、必要に応じたAPIを呼び出してくれるという仕組みのようですね。  

以下は仕様書を読み込んで質問に答えるためのサンプルコードです。
```python
from langchain.chat_models import ChatOpenAI
from langchain.agents import load_tools, initialize_agent
from langchain.tools import AIPluginTool

# プラグインを読み込む
tool = AIPluginTool.from_plugin_url("https://www.klarna.com/.well-known/ai-plugin.json")

# エージェントの準備
llm = ChatOpenAI(temperature=0)
tools = load_tools(["requests"] )
tools += [tool]
agent_chain = initialize_agent(
    tools, 
    llm, 
    agent="zero-shot-react-description", 
    verbose=True
)

# 質問
agent_chain.run("What T-shirts are available at Kulana?")
```

## 実行結果
```bash
> Entering new AgentExecutor chain...
I need to find out if Kulana has an online shopping platform and if they have an API that I can use to search for T-shirts.
Action: KlarnaProducts
Action Input: None
Observation: Usage Guide: Use the Klarna plugin to get relevant product suggestions for any shopping or researching purpose. The query to be sent should not include stopwords like articles, prepositions and determinants. The api works best when searching for words that are related to products, like their name, brand, model or category. Links will always be returned and should be shown to the user.

OpenAPI Spec: {'openapi': '3.0.1', 'info': {'version': 'v0', 'title': 'Open AI Klarna product Api'}, 'servers': [{'url': 'https://www.klarna.com/us/shopping'}], 'tags': [{'name': 'open-ai-product-endpoint', 'description': 'Open AI Product Endpoint. Query for products.'}], 'paths': {'/public/openai/v0/products': {'get': {'tags': ['open-ai-product-endpoint'], 'summary': 'API for fetching Klarna product information', 'operationId': 'productsUsingGET', 'parameters': [{'name': 'q', 'in': 'query', 'description': 'query, must be between 2 and 100 characters', 'required': True, 'schema': {'type': 'string'}}, {'name': 'size', 'in': 'query', 'description': 'number of products returned', 'required': False, 'schema': {'type': 'integer'}}, {'name': 'budget', 'in': 'query', 'description': 'maximum price of the matching product in local currency, filters results', 'required': False, 'schema': {'type': 'integer'}}], 'responses': {'200': {'description': 'Products found', 'content': {'application/json': {'schema': {'$ref': '#/components/schemas/ProductResponse'}}}}, '503': {'description': 'one or more services are unavailable'}}, 'deprecated': False}}}, 'components': {'schemas': {'Product': {'type': 'object', 'properties': {'attributes': {'type': 'array', 'items': {'type': 'string'}}, 'name': {'type': 'string'}, 'price': {'type': 'string'}, 'url': {'type': 'string'}}, 'title': 'Product'}, 'ProductResponse': {'type': 'object', 'properties': {'products': {'type': 'array', 'items': {'$ref': '#/components/schemas/Product'}}}, 'title': 'ProductResponse'}}}}
Thought:I can use the Klarna Shopping API to search for T-shirts on Kulana's online shopping platform.
Action: requests_get
Action Input: https://www.klarna.com/us/shopping/public/openai/v0/products?q=T-shirts&size=10&budget=50
Observation: {"products":[{"name":"Psycho Bunny Mens Copa Gradient Logo Graphic Tee","url":"https://www.klarna.com/us/shopping/pl/cl10001/3203663222/Clothing/Psycho-Bunny-Mens-Copa-Gradient-Logo-Graphic-Tee/?utm_source=openai","price":"$35.00","attributes":["Material:Cotton","Target Group:Man","Color:White,Blue,Black,Orange","Neckline:Round"]},{"name":"Lacoste Men's Pack of Plain T-Shirts","url":"https://www.klarna.com/us/shopping/pl/cl10001/3202043025/Clothing/Lacoste-Men-s-Pack-of-Plain-T-Shirts/?utm_source=openai","price":"$26.60","attributes":["Material:Cotton","Target Group:Man","Color:White,Black"]},{"name":"Grunt 1776 Flag Long Sleeve T-shirts","url":"https://www.klarna.com/us/shopping/pl/cl10001/3203267031/Clothing/Grunt-1776-Flag-Long-Sleeve-T-shirts/?utm_source=openai","price":"$29.95","attributes":["Material:Cotton","Target Group:Man","Color:Black","Neckline:Round"]},{"name":"Hanes Men's Ultimate 6pk. Crewneck T-Shirts","url":"https://www.klarna.com/us/shopping/pl/cl10001/3201808270/Clothing/Hanes-Men-s-Ultimate-6pk.-Crewneck-T-Shirts/?utm_source=openai","price":"$13.82","attributes":["Material:Cotton","Target Group:Man","Color:White"]},{"name":"T-shirt","url":"https://www.klarna.com/us/shopping/pl/cl10001/3203506327/Clothing/T-shirt/?utm_source=openai","price":"$29.99","attributes":["Material:Cotton","Target Group:Man","Color:Gray,White,Blue,Black,Orange","Neckline:Round"]},{"name":"Nike Boy's Jordan Stretch T-shirts","url":"https://www.klarna.com/us/shopping/pl/cl359/3201863202/Children-s-Clothing/Nike-Boy-s-Jordan-Stretch-T-shirts/?utm_source=openai","price":"$14.99","attributes":["Material:Cotton","Color:White,Green","Model:Boy","Size (Small-Large):S,XL,L,M"]},{"name":"Polo Classic Fit Cotton V-Neck T-Shirts 3-Pack","url":"https://www.klarna.com/us/shopping/pl/cl10001/3203028500/Clothing/Polo-Classic-Fit-Cotton-V-Neck-T-Shirts-3-Pack/?utm_source=openai","price":"$29.95","attributes":["Material:Cotton","Target Group:Man","Color:White,Blue,Black"]},{"name":"Hugo Boss Dulive T-shirt","url":"https://www.klarna.com/us/shopping/pl/cl10001/3201780633/Clothing/Hugo-Boss-Dulive-T-shirt/?utm_source=openai","price":"$36.00","attributes":["Material:Cotton","Target Group:Man","Color:White,Black","Neckline:Round"]},{"name":"Nike Sportswear Club T-shirt - University Red/White","url":"https://www.klarna.com/us/shopping/pl/cl10001/3200152246/Clothing/Nike-Sportswear-Club-T-shirt-University-Red-White/?utm_source=openai","price":"$12.61","attributes":["Material:Cotton","Target Group:Man","Color:Red"]},{"name":"KingSize Men's Big & Tall Streetwear Graphic Tee","url":"https://www.klarna.com/us/shopping/pl/cl10001/3202304522/Clothing/KingSize-Men-s-Big-Tall-Streetwear-Graphic-Tee/?utm_source=openai","price":"$27.95","attributes":["Material:Cotton","Target Group:Man","Color:Black","Neckline:Round"]}]}
Thought:I found a list of T-shirts available on Kulana's online shopping platform through the Klarna Shopping API.
Final Answer: Kulana has a variety of T-shirts available for purchase on their online shopping platform, which can be searched and compared using the Klarna Shopping API.
```

```bash
質問: klarnaで購入できるTシャツは何ですか?
最終的な答え: 
Kulanaのオンラインショッピングプラットフォームでは、
様々なTシャツを購入することができ、Klarna Shopping APIを使用して検索し比較することができます。
```

## さらに高度なプラグインを作るには
次のようにIPアドレスに関連した情報を調べるAPIをFastAPIで実装し、OpenAPI SpecをAIPluginToolに読み込ませました。  
OpenAIにOpenAPIの仕様を読んでもらう必要があるので、出来るだけ分かりやすくAPIの使い方や入力されるパラメータの説明を入れないといけません。  
@[tweet](https://twitter.com/hunter_phishing/status/1640354834527428608)
サンプルコードはこちらに整理して置いてあります。
https://github.com/tatsu-i/chatbot-sample

複数のAPIやツールを読み込ませている場合には、「どのAPIを使って、どうやってAPIを実行するのか」を説明してあげると精度が上がりました。  
```
After generating the curl command to run the API from the OpenAPI Spec, examine the information related to the IP address below.

IP: {{ip}}
```

## まとめ
この記事を読んで、少しでもお役に立てたなら幸いです。何か質問やご意見がありましたら、お気軽にご連絡ください。

## 参考
https://note.com/npaka/n/nb7a5ad7a7f27
