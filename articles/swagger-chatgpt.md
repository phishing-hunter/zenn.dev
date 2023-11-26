---
title: "ChatGPTを使って通信ログからSwagger(OpenAPI)の仕様を生成する"
emoji: "😽"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["openai", "swagger", "api", "python"]
published: true
---

# 1. はじめに

この記事では、OpenAIのChatGPTを使って通信ログからSwagger(OpenAPI)の仕様を生成する方法について説明します。これにより、APIの仕様書作成の手間を大幅に削減することが可能となります。

# 2. Swagger(OpenAPI)とは

[Swagger](https://swagger.io/)(現在はOpenAPIとして知られています)は、RESTful APIの仕様を記述するためのフレームワークです。APIのエンドポイント、リクエスト、レスポンスの形式などを定義することができます。また、Swaggerを使ってテストやコード生成を行うツールも多数存在します。例えば、[Swagger Codegen](https://swagger.io/tools/swagger-codegen/)は、Swaggerの仕様からクライアントやサーバーのコードを自動生成することができます。また、[Swagger UI](https://swagger.io/tools/swagger-ui/)は、Swaggerの仕様から動的なAPIドキュメンテーションを生成し、APIのエンドポイントを直接ブラウザからテストすることができます。

## 3. 通信ログからSwagger仕様を生成する

以下に、通信ログからSwaggerの仕様を生成する手順を示します。

## 3.1 通信ログの収集
まず、通信ログを収集します。今回はmitmdumpを使ってリクエストとレスポンスの内容を記録します。
mitmdumpは、ネットワークトラフィックをキャプチャし、HTTPとHTTPSのリクエストとレスポンスを記録するためのツールです。

始めに以下のようなスクリプトを`mitmdump.py`という名前で準備します。

```python
from mitmproxy import ctx, http
import sys

api_host = sys.argv[3]
api_path = sys.argv[4] if len(sys.argv) > 4 else "/"
ctx.log.info(f"API : {api_host}{api_path}")
log_file = "mitmproxy.log"  # ログを保存するファイル名

def write_log(message: str):
    with open(log_file, "a") as file:
        file.write(message + "\n")

def format_headers(headers):
    masked_headers = {}
    for name, value in headers.items():
        if name.lower() in ['authorization', 'cookie']:
            masked_headers[name] = '*' * 8  # 8文字のアスタリスクでマスク
        else:
            masked_headers[name] = value
    return '\n'.join(f'{name}: {value}' for name, value in masked_headers.items())

def request(flow: http.HTTPFlow) -> None:
    if flow.request.host == api_host and flow.request.path.find(api_path) != -1:
        # リクエストメソッドとPathのログ
        log_msg = f"---\n{flow.request.method} {flow.request.path}"
        write_log(log_msg)

        # リクエストヘッダーのログ
        headers = format_headers(flow.request.headers)
        log_msg  = f"\nDomain: {flow.request.host}"
        log_msg += f"Request Headers:\n{headers}"
        write_log(log_msg)

        # リクエストのbodyを出力
        if flow.request.content:
            log_msg = "Request Body:\n" + flow.request.content.decode('utf-8', 'ignore')
            write_log(log_msg)

def response(flow: http.HTTPFlow) -> None:
    if flow.request.host == api_host and flow.request.path.find(api_path) != -1 and flow.response:
        # ステータスコード
        if flow.response.status_code:
            log_msg = f"\nStatus Code: {flow.response.status_code}"
            write_log(log_msg)
        # レスポンス
        log_msg = "Response:\n" + flow.response.text
        write_log(log_msg)
```

次にmitmdumpをインストールします。公式のインストールガイドは[こちら](https://docs.mitmproxy.org/stable/overview-installation/)です。

Macにインストールする場合は以下のように実行します：
```bash
brew install mitmproxy
```

Linuxにインストールする場合は以下のように実行します：
```bash
sudo apt-get install mitmproxy
```

インストールが完了したら記録を開始します。
試しにzenn.devのAPIを対象にします。

```bash
mitmdump -s mitmdump.py zenn.dev /api
```

ブラウザのプロキシ設定を`http://localhost:8080`に設定し、zenn.devを適当に閲覧します。
すると`mitmproxy.log`にアクセスログが溜まります。
```bash
cat mitmproxy.log
```


## 3.2. ChatGPTを使ったSwaggerの生成
以下のように`generate.py`という名前のスクリプトを用意します。
```python
import sys
import json
import yaml
from openai import OpenAI

def generate_swagger(prompt):
    client = OpenAI()

    response = client.chat.completions.create(
        model="gpt-4-1106-preview", 
        messages=[
            {"role": "system", "content": "あなたは入力されたログ内容から`OpenAPI 3.0.0`のJSONを生成するアシスタントです。"},
            {"role": "user", "content": prompt},
        ],
        response_format={ "type": "json_object" },
    )
    return response.choices[0].message.content
    
with open(sys.argv[1]) as f:
    prompt = f.read()
    swagger_json = generate_swagger(prompt)
    swagger_yaml = yaml.dump(json.loads(swagger_json))
    print(swagger_yaml)
```

ログが保存正しくされていることを確認したら以下のようにSwaggerドキュメントを生成します。
```bash
export OPENAI_API_KEY=<OPENAIのAPIキー>
python generate.py mitmproxy.log > openapi.yaml
```

## 3.3 生成した仕様書
最後に以下が生成したSwagger仕様書です。

```yaml
info:
  title: Zenn.dev API
  version: 1.0.0
openapi: 3.0.0
paths:
  /api/announcement/current:
    get:
      responses:
        '200':
          content:
            application/json:
              example:
                announcement: null
              schema:
                properties:
                  announcement:
                    nullable: true
                    type: object
                type: object
          description: Successful response with current announcement
      summary: Retrieve current announcement
  /api/app_billboards:
    get:
      responses:
        '200':
          content:
            application/json:
              example:
                app_billboards: []
              schema:
                properties:
                  app_billboards:
                    items: {}
                    type: array
                type: object
          description: Successful response with billboard data
      summary: Retrieve billboards for the application
  /api/me:
    get:
      responses:
        '200':
          content:
            application/json:
              example:
                current_user:
                  bio: "Phishing Hunter\u3092\u958B\u767A\u3057\u3066\u3044\u307E\u3059"
                  username: tatsui
              schema:
                properties:
                  current_user:
                    $ref: '#/components/schemas/User'
                type: object
          description: Successful response with user information
      summary: Retrieve current user data
  /api/me/github_deployments:
    get:
      parameters:
      - description: Number of deployments to retrieve
        in: query
        name: count
        required: false
        schema:
          type: integer
      responses:
        '200':
          content:
            application/json:
              example:
                github_deployments:
                - deploy_status: SUCCESS
                  event: PUSH
              schema:
                properties:
                  github_deployments:
                    items:
                      $ref: '#/components/schemas/GithubDeployment'
                    type: array
                type: object
          description: Successful response with github deployments
      summary: Retrieve GitHub deployments for current user
servers:
- url: https://zenn.dev

components:
  schemas:
    GithubDeployment:
      properties:
        event:
          type: string
        id:
          format: int64
          type: integer
      type: object
    User:
      properties:
        id:
          format: int64
          type: integer
        username:
          type: string
      type: object

```

上記のYamlを[Swagger Editor](https://editor.swagger.io/)に貼り付ける事でわかりやすく表示することができます。
![](/images/swagger-chatgpt/swagger_zenn.png)

## まとめ

この記事では、ChatGPTを使って通信ログからSwaggerの仕様を生成する方法について説明しました。
この方法を用いることで、APIの仕様書作成の手間を大幅に削減することが可能となります。
ただし、生成されたSwaggerの仕様はあくまで参考の一つであり、実際のAPIの挙動を正確に反映しているわけではないため、適宜手動での確認と修正が必要です。

本記事のサンプルコードはこちらに整理して置いてあります。
https://github.com/tatsu-i/swagger-gpt
