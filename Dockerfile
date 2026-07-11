# Builds the marketing site (site/) into a static nginx image for
# reversobar.zaakir.io, deployed by ArgoCD from ikarza-gitops-infra.
# node 24 = npm 11, matching the npm that wrote site/package-lock.json
# (npm 10 rejects the lock over platform-conditional optional deps).
FROM node:24-alpine AS build
WORKDIR /site
COPY site/package.json site/package-lock.json ./
RUN npm ci
COPY site/ ./
RUN npm run build

FROM nginx:1.27-alpine
COPY site/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /site/dist /srv/site
