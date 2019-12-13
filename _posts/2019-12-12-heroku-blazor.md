---
layout: post
title:  Free hosting for your blazor app
date:       2019-12-12
summary:  Don't pay for the cloud
categories: blazor heroku webassembly dotnet 
---

## Heroku

[Heroku](https://www.heroku.com/home) is a cloud platform with full CI/CD support. There you can easily create, deploy, monitor and scall your app. 
And the most excited thing that it has free option to host your app.

## Prerequisites

* Create blazor app hosted on asp.net core
* Create repo on github
* Push your project to github
* Register on heroku

## Creating app on heroku

* In first step, we have to create app in heroku
  
1. Go to your [heroku dashboard](https://dashboard.heroku.com/apps)
2. Click `New` -> `Create new app`
3. Name and click `Create`
4. Connect your app to github repo for enabling deploy
5. Also you can enable automatic deploy 

![](\images\heroku-blazor\create-app-1.gif | absolute_url)
![](\images\heroku-blazor\create-app-2.gif | absolute_url)

After these steps you have ability to deploy project manualy, however it will not work yet.

## Adding buildpack

Unfoturnately, heroku by default does not support .net apps. So we have to add third party buildpacks for enabling .net apps suport. 
Don't worry, it is pretty easy.

![](\images\heroku-blazor\add-buildpack.gif | absolute_url)

1. You can find Heroku .Net Core Buildpack [here](https://github.com/jincod/dotnetcore-buildpack)
2. Go to your app on heroku **setting** tab
3. In buildpacks section click `add buildpack`
4. Copy buildpack github url from github page
5. Enter coppied url to input and click `Save changes`
  
Now heroku knows how to build your app. However, we still are not ready to deploy our app.

## Project file

If we would try to deploy our app we got some errors while building. Because buildpack automatically detect project for publishing by looking first Startup.cs file in solution. If we created blazor app hosted on asp.net core , we will have 2 web projects in solution and we must specify `PROJECT_FILE` in environment variables.

![](\images\heroku-blazor\project-file.gif | absolute_url)

1. Go to `settings` page
2. In Config Vars section click `Reveal Config Vars`
3. Add Key `PROJECT_FILE` with value of relative path to your server `csproj` file. In my situation, it is `PerekupDetector/PerekupDetector.Web/Server/PerekupDetector.Web.Server.csproj`
4. Now you can manually deploy your project in **Deploy** tab


## Conclusion
Heroku gives ability to host your .net core app for free with limited resources. However, it is enough to start up.