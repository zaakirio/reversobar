# Builds the marketing site (site/) into a static nginx image for
# reversobar.zaakir.io, deployed by ArgoCD from ikarza-gitops-infra.
FROM node:22-alpine AS build
WORKDIR /site
COPY site/package.json site/package-lock.json ./
RUN npm ci
COPY site/ ./
RUN npm run build

FROM nginx:1.27-alpine
COPY site/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /site/dist /srv/site
