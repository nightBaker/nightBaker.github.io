---
layout: post
title: Dotnet custom template 
date:       2019-08-08
summary:    Dotnet template from zero to nuget package
categories: Rancher Docker Kubernates
---

## Problem

Most of time, starting new project, which can be api, web, console app, microservice or monolithic, big or small,
 you need and use mostly the same dependicies such as logging libraries, auth configuration, ORM (for example, entity framework), good practice health checks, api must have swagger documentation and so on. Also you projects structure is not changed a lot.  
 So there is a good question - why we don't create template for our and our's teamates needs. Furthermore, if you don't need some of template's dependencies, it is always easy to remove them at start time of development.

## Solution

Fortunately, dotnet allows us create our custom template in few easy steps.

### Project

First of all, we have to create solution or just project for your template. In my case, I've created solution with structure based on DDD. So I have API - infrastrucure, Application layer and Domain layer. Also for all layers I created xUnit test projects.

![solution visual studio DDD]({{ "/images/dotnet-template/solution.png" | absolute_url }})

### Dependencies

Now, you can add necessary dependies to your project. Let's add basic firstly. 

#### Entity framework

```console
dotnet install Npgsql.EntityFrameworkCore.PostgreSQL
```

Our appsettings.json

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "System": "Warning",
      "Microsoft": "Warning"
    }
  },
  "ConnectionStrings": {
    "{{Database_Name}}": "User ID=postgres;Password=postgres;Host=localhost;Port=15432;Database={{Database_Name}};Pooling=true;",    
  },
  "AllowedHosts": "*"  
}
```

Note, we use name of connection string and database name as `{{Database_Name}}`. It allows template to use it like a variable for replacing it during generating.

Now we need to create DbContext
```csharp
namespace ProjectTemplate.Api.Data
{
    public class DatabaseContext : DbContext
    {
        public DatabaseContext(DbContextOptions<DatabaseContext> options)
            : base(options)
        { }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {

        }
    }
}
```
Startup.cs

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_2);
    
    services.AddDbContext<DatabaseContext>(options =>
        options.UseNpgsql(Configuration.GetConnectionString("{{Database_Name}}")));

    
}
```

Note, we again use string `{{Database_Name}}` which will be replace with our real database name

#### Nlog

Every project needs logging. I use nlog most of time.

```console
dotnet install Nlog
dotnet install NLog.Web.AspNetCore
```

Don't forget add nlog.config. And our `Program.cs` looks like

```csharp
public class Program
    {
        public static void Main(string[] args)
        {
            // NLog: setup the logger first to catch all errors
            var logger = NLog.Web.NLogBuilder.ConfigureNLog("nlog.config").GetCurrentClassLogger();
            try
            {
                logger.Debug("Starting program");
                CreateWebHostBuilder(args).Build().Run();
            }
            catch (Exception ex)
            {
                //NLog: catch setup errors
                logger.Error(ex, "Stopped program because of exception");
                throw;
            }
            finally
            {
                // Ensure to flush and stop internal timers/threads before application-exit (Avoid segmentation fault on Linux)
                NLog.LogManager.Shutdown();
            }
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseStartup<Startup>()
                .ConfigureLogging(logging =>
                {
                    logging.ClearProviders();
                    logging.SetMinimumLevel(Microsoft.Extensions.Logging.LogLevel.Debug);

                })
                .UseNLog();
    }
```

So now, we have 2 dependencies in our template. Of course, you can add any dependencies you want.
Let's now generate our first template.

### Template

Firstly, we have to create folder in the root of solution and name it `.template.config`. There will be one file with name `template.json` and content

```json
{
  "$schema": "http://json.schemastore.org/template", 
  "author": "Your name",
  "classifications": [ "Web/API/Nlog/Entity framework core" ], 
  "name": "Night backer template", 
  "identity": "nightApi", 
  "shortName": "nightApi", 
  "tags": {
    "language": "C#", 
    "type": "project"
  },
  "sourceName": "ProjectTemplate",  // every entry of this string in source code or in project names will be replace with given value 
  "preferNameDirectory": true, 
  "symbols": { // this section allows to replace our variables with given value during generating project from template
    "db": { 
      "type": "parameter",
	  "isRequired": "true",
      "datatype": "string",
      "replaces": "{{Database_Name}}",
      "defaultValue": "MyGameStartupDB",
      "description": "The database name attached to this project."
    }		
  }
}
```

Our template is ready. Run following command in console in root of solution to install this template to your environment

```console
dotnet new -i .
```

If there is no error, you should see a list of installed templates

You can generate new project from our template, for example :

```console
dotnet new nightApi –db <Database_name> -n <Project_name>.
```

Replace following values :  
`<Database_name>` is our variable for database name
`<Project_name>` is a project name

### Nuget package

Using whole solution for creation of template is not so convinient way, for example, if your teammate want's to use your prepared template.
 So you may want to share it easily like nuget package. Fortunately, it is as much simple as creating template.

1. Let's create folder and name it `ProjectTemplatePackage`.
2. Copy our project folder into just created folder. 
3. Create file `ProjectTemplates.csproj` with content :

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <PackageType>Template</PackageType>
    <PackageVersion>1.0</PackageVersion>
    <PackageId>NightBacker.Templates</PackageId>
    <Title>Templates for .net</Title>
    <Authors>Night backer</Authors>
    <Description>Templates to use when creating an application.</Description>
    <PackageTags>dotnet-new;api;nlog;ef core</PackageTags>
    <TargetFramework>netstandard2.0</TargetFramework>

    <IncludeContentInPack>true</IncludeContentInPack>
    <IncludeBuildOutput>false</IncludeBuildOutput>
    <ContentTargetFolders>content</ContentTargetFolders>
  </PropertyGroup>

  <ItemGroup>
    <Content Include="ProjectTemplate\**\*" Exclude="ProjectTemplate\**\bin\**;ProjectTemplate\**\obj\**" />
    <Compile Remove="**\*" />
  </ItemGroup>

</Project>
```

4. Run command

```console
dotnet pack
```

Now in `ProjectTemplatePackage\bin\Debug` you can see your created nuget package. 
If you want to install template from nuget package use following command

```console
dotnet new -i <PATH_TO_NUPKG_FILE>
```

