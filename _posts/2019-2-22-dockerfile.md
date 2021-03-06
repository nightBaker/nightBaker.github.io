---
layout: post
title: Angular 7 + Asp.net Core Dockerfile that just works!
date:       2019-02-22
summary:    Dockerfile for building and running asp.net core 2.2 SPA with Angular 7
categories: Angular 7, asp.net core, docker
---

## Problem
We have Asp.net core 2.2 SPA with Angular 7 application. Below, dockerfile which builds docker image for our app.

## Solution

```dockerfile
FROM microsoft/dotnet:2.2-aspnetcore-runtime AS base

WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM microsoft/dotnet:2.2-sdk AS build

WORKDIR /src
COPY ["MyApp.csproj", "MyApp/"]
COPY ["MyApp.Domain/MyApp.Domain.csproj", "MyApp.Domain/"]
RUN dotnet restore "MyApp.csproj"
COPY . .
WORKDIR "/src/MyApp"
RUN dotnet build "MyApp.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "MyApp.csproj" -c Release -o /app



FROM node as nodebuilder
RUN mkdir /usr/src/app
WORKDIR /usr/src/app
ENV PATH /usr/src/app/node_modules/.bin:$PATH
COPY MyApp/ClientApp/package.json /usr/src/app/package.json
RUN npm install
COPY MyApp/ClientApp/. /usr/src/app
RUN npm run build

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
RUN mkdir -p /app/ClientApp/dist
COPY --from=nodebuilder /usr/src/app/dist/. /app/ClientApp/dist/
ENTRYPOINT ["dotnet", "MyApp.dll"]

```
