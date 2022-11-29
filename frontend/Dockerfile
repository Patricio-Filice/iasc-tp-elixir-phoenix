FROM node:16

COPY reactiasc .

RUN npm ci --legacy-peer-deps
RUN npm run build

EXPOSE 3000

RUN npm install -g serve

CMD ["serve", "-s", "build", "-l", "3000"]