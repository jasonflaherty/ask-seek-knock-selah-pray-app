FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY migrations ./migrations
COPY scripts ./scripts
COPY src ./src

ENV PORT=8080
EXPOSE 8080

CMD ["node", "src/index.js"]
