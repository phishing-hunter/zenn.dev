FROM node:16

WORKDIR /app

COPY package*.json ./

RUN yarn

CMD ["npx", "zenn", "preview", "--host", "0.0.0.0"]
