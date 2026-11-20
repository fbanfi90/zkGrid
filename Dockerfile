FROM node:26-alpine

WORKDIR /app
ENV NODE_ENV=production

# Install exact dependency versions from the lockfile
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Only what the server needs: the proof/ pipeline is a dev-time tool
COPY server.js ./
COPY public ./public

USER node
EXPOSE 9075
CMD ["node", "server.js"]
