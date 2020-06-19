---
layout: post
title:  Blazor grpc - comunication optimization
date:       2020-06-19
summary:  Smaller and faster requests to your backend from blazor wasm
categories: blazor webassembly dotnet grpc
---

## Prerequisites

Let's create blazor wasm aspnet hosted app and confirm everything works.

![2020-06-19-10-27-27-image.png](https://raw.githubusercontent.com/nightBaker/nightBaker.github.io/master/2020/06/19-10-27-46-2020-06-19-10-27-27-image.png)

We get following structured solution with Server and Client projects.

![2020-06-19-10-30-37-image.png](https://raw.githubusercontent.com/nightBaker/nightBaker.github.io/master/2020/06/19-10-30-52-2020-06-19-10-30-37-image.png)

## Protobuf vs json - the place of optimization

Our created project works with http client and sends requests using http protocol and json format of messages. It means every time when you send request it is serialized to json and deserelized on other side to message. We can't avoid serialization deserialization steps, however grpc can impove the speed. Grpc uses protobuf message format, which is more lightweight than json. Although, protobuf format is not human readable, we can install extension like [this one](https://chrome.google.com/webstore/detail/grpc-web-developer-tools/ddamlpimmiapbcopeoifjfmoabdbfbjj) for our browser, which translates  message from protobuf to json format.

## Adding Grpc to the server

1. Install packages

```powershell
dotnet add package Grpc.AspNetCore
dotnet add package Grpc.AspNetCore.Web
```

2. Change `Startup.cs`
   
   ```csharp
   public void ConfigureServices(IServiceCollection services)
   {
       services.AddGrpc();
   }
   ```

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    if (env.IsDevelopment())
    {
        app.UseDeveloperExceptionPage();
        app.UseWebAssemblyDebugging();
    }
    else
    {
        app.UseExceptionHandler("/Error");
        // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
        app.UseHsts();
    }

    app.UseHttpsRedirection();
    app.UseBlazorFrameworkFiles();
    app.UseStaticFiles();

    app.UseRouting();

    app.UseGrpcWeb(); // should be between routing and enpoints

    app.UseEndpoints(endpoints =>
    {
        endpoints.MapGrpcService<WeatherService>().EnableGrpcWeb();
        endpoints.MapFallbackToFile("index.html");
    });
}
```

3. Create `WeatherService .cs` under `Services folder` 

4. Now we need to create contract which is located in `*.proto` file. Let's add protos to `Shared` project and add to `Client` and `Server` projects this file as link in the following way
   
   ![2020-06-19-14-54-33-image.png](https://raw.githubusercontent.com/nightBaker/nightBaker.github.io/master/2020/06/19-17-39-13-2020-06-19-14-54-33-image.png)
   
   #### note
   
   proto files should have following  **build action** property
   
   ![2020-06-19-17-20-02-image.png](https://raw.githubusercontent.com/nightBaker/nightBaker.github.io/master/2020/06/19-17-38-57-2020-06-19-17-20-02-image.png)

   `weather.proto` contains 

```protobuf
   syntax = "proto3";

   import "google/protobuf/timestamp.proto";
   import "google/protobuf/empty.proto";

   package weather;

   service WeatherForecasts {
     rpc GetWeatherForecasts (google.protobuf.Empty) returns (GetWeatherForecastsResponse);
   }

   message GetWeatherForecastsResponse {
     repeated WeatherForecast forecasts = 1;
   }

   message WeatherForecast {
     google.protobuf.Timestamp date = 1;
     int32 temperatureC = 2;
     string summary = 3;
   }
```

5. Edit `WeatherServic.cs`
   
   ```csharp
   public class WeatherService : WeatherForecasts.WeatherForecastsBase
       {
           private static readonly string[] Summaries = new[]
           {
               "Freezing", "Bracing", "Chilly", "Cool", "ld", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
           };
   
           public override Task<GetWeatherForecastsResponse> GetWeatherForecasts(Empty request, ServerCallContext context)
           {
               var rng = new Random();
               var results = Enumerable.Range(1, 5).Select(index => new WeatherForecast
               {
                   Date = DateTime.UtcNow.AddDays(index).ToTimestamp(),
                   TemperatureC = rng.Next(-20, 55),
                   Summary = Summaries[rng.Next(Summaries.Length)]
               }).ToArray();
   
               var response = new GetWeatherForecastsResponse();
               response.Forecasts.AddRange(results);
   
               return Task.FromResult(response);
           }
       }
   ```

6. That's all for server side.

## Client side grpc client

1. Install packages
   
   ```powershell
   dotnet add package Google.Protobuf
   dotnet add package Grpc.Net.Client
   dotnet add package Grpc.Net.Client.Web
   dotnet add package Grpc.Tools
   ```

2. In the `FetchData.razor` page we have to inject `GrpcChannel` instead of `HttpClient` and send requests using generated grpc client.
   
   ```csharp
   @page "/fetchdata"
   @using Grpc.Net.Client
   @inject GrpcChannel Channel
   @using Weather
   @using Google.Protobuf.WellKnownTypes
   
   <h1>Weather forecast</h1>
   
   <p>This component demonstrates fetching data from the server.</p>
   
   @if (forecasts == null)
   {
   <p><em>Loading...</em></p> }
   else
   {
   <table class="table">
       <thead>
           <tr>
               <th>Date</th>
               <th>Temp. (C)</th>
               <th>Temp. (F)</th>
               <th>Summary</th>
           </tr>
       </thead>
       <tbody>
           @foreach (var forecast in forecasts)
           {
   <tr>
       <td>@forecast.Date.ToDateTime().ToShortDateString()</td>
       <td>@forecast.TemperatureC</td>
       <td>@( 32 + (int)(forecast.TemperatureC / 0.5556))</td>
       <td>@forecast.Summary</td>
   </tr>}
       </tbody>
   </table>}
   
   @code { private IList<WeatherForecast> forecasts;
   
       protected override async Task OnInitializedAsync()
       {
           var client = new WeatherForecasts.WeatherForecastsClient(Channel);
           forecasts = (await client.GetWeatherForecastsAsync(new Empty())).Forecasts;
       } 
   }
   ```

      ```

3. And last step, we should configure DI in `Program.cs` 
   
   ```csharp
   public static async Task Main(string[] args)
   {
       var builder = WebAssemblyHostBuilder.CreateDefault(args);
       builder.RootComponents.Add<App>("app");
   
       builder.Services.AddSingleton(services =>
       {
   
           var backendUrl = builder.HostEnvironment.BaseAddress; 
   
           var httpHandler = new GrpcWebHandler(GrpcWebMode.GrpcWeb, new HttpClientHandler());
   
           return GrpcChannel.ForAddress(backendUrl, new GrpcChannelOptions { HttpHandler = httpHandler });
       });            
   
       await builder.Build().RunAsync();
   }
   ```
   
Run application and press **F12** to check that we reduce requests size.
   
[Source code you can find on github](https://github.com/nightBaker/BlazorGrpc/tree/master/BlazorGrpc/Shared/protos) 
   
## Conclusion

When you need good performance or want to reduce requests/responses size, that impoves speed of communication, Grpc can be good choice. However, we should know that it is just one point of different pros of the protocol.
