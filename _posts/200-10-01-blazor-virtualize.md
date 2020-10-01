---
layout: post
title: Blazor virtualize component
date:       2020-10-01
summary:    Lazy loading of big lists. Rendering optimization.
categories: blazor virtualize
---

## New Virtualize component

At the time of writting, microsoft released new .NET 5 RC version which includes new Virtualize component. It optimizes rendering of big lists (hundreds of items) and allows to load (lazy loading) items only when it should be rendered.

## Prerequisites

- Install [.NET 5 SDK ](https://dotnet.microsoft.com/download/dotnet/5.0) (RC at the time of writting)

- Install Visual Studio (Preview at the time of writting)

- Create blazor webassembly project from template in visual studio or using CLI
  
![create blazor proj ](/images/blazor-virtualize-component/2020-09-23-16-13-33-image.png)

## Virtualize forecasts

In default blazor webassembly project we have `FetchData.razor` page and there we can use new `Virtualize` component

1. Change page to 
   
   ```csharp
   @page "/fetchdata"
   @inject HttpClient Http
   
   <h1>Weather forecast</h1>
   
   <p>This component demonstrates fetching data from the server.</p>
   
   @if (forecasts == null)
   {
       <p><em>Loading...</em></p>
   }
   else
   {
       <table class="table">
           <thead>
               <tr>
                   <th>Id</th>
                   <th>Date</th>
                   <th>Temp. (C)</th>
                   <th>Temp. (F)</th>
                   <th>Summary</th>
               </tr>
           </thead>
           <tbody>
               <Virtualize Items="forecasts" Context="forecast">
                   <tr>
                       <td>@forecast.Id</td>
                       <td>@forecast.Date.ToShortDateString()</td>
                       <td>@forecast.TemperatureC</td>
                       <td>@forecast.TemperatureF</td>
                       <td>@forecast.Summary</td>
                   </tr>
               </Virtualize>
           </tbody>
       </table>
   }
   
   @code {
       private WeatherForecast[] forecasts;
   
       protected override async Task OnInitializedAsync()
       {
           forecasts = await Http.GetFromJsonAsync<WeatherForecast[]>("sample-data/weather.json");
       }
   
       public class WeatherForecast
       {
           public int Id { get; set; }
   
           public DateTime Date { get; set; }
   
           public int TemperatureC { get; set; }
   
           public string Summary { get; set; }
   
           public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
       }
   }
   peratureF => 32 + (int)(TemperatureC / 0.5556);
       }
   }
   ```

2. Now we need more forecasts, so let's generate forecasts source file `wwwroot/sample-data/`. For example, I used [online generator](https://www.json-generator.com/).

3. Run application and check that in one moment on page exist just some number of forecasts but not all. In our example there are just 23 item on page. However, if you scroll page down you can see that new items are added and top items are removed from html source
   
   ![virtualize-component-test.png](https://raw.githubusercontent.com/nightBaker/nightBaker.github.io/master/2020/09/23-17-22-15-virtualize-component-test.png)

You can see one bug - scroll goes down while it gets to the end. The reason is blazor does not know height of our row, so it thinks that all items can be downloaded and be shown on the page. It easy to fix, just set ItemSize

```csharp
<Virtualize Items="forecasts" Context="forecast" ItemSize="49" >
    <p>
        <td>@forecast.Id</td>
        <td>@forecast.Date.ToShortDateString()</td>
        <td>@forecast.TemperatureC</td>
        <td>@forecast.TemperatureF</td>
        <td>@forecast.Summary</td>
    </p>
</Virtualize>
```

ItemSize - size of element in pixels.

## Lazy loading

Often you don't need to have all items in memory in one time, so you want to lazy load items when user need it. Blazor Virtualize component offer to specify `ItemsProvider` which respones for items loading. Lets change our code to

```csharp
@page "/fetchdata"
@inject HttpClient Http

<h1>Weather forecast</h1>

<p>This component demonstrates fetching data from the server.</p>


<Virtualize ItemsProvider="LoadForecasts" Context="forecast" ItemSize="10" >
    <p>
        <td>@forecast.Id</td>
        <td>@forecast.Date.ToShortDateString()</td>
        <td>@forecast.TemperatureC</td>
        <td>@forecast.TemperatureF</td>
        <td>@forecast.Summary</td>
    </p>
</Virtualize>


@code {

    protected async ValueTask<ItemsProviderResult<WeatherForecast>> LoadForecasts(ItemsProviderRequest request)
    {
        var forecasts = await Http.GetFromJsonAsync<WeatherForecast[]>("sample-data/weather.json");

        return new ItemsProviderResult<WeatherForecast>(forecasts.Skip(request.StartIndex).Take(request.Count), forecasts.Count());
    }

    public class WeatherForecast
    {
        public int Id { get; set; }

        public DateTime Date { get; set; }

        public int TemperatureC { get; set; }

        public string Summary { get; set; }

        public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    }
}
```

Now, we don't load any items on initilizing time, but virtualize component trigger `LoadForecasts` method when it need some items, passing parameter with `startIndex` and number of items to load (`count`) . So we can load only items which user see on the page on the time.

Now, we have white screen while items are loading. However, virtualize component allow us to have placeholder while we load items. Let's change our component 

```csharp
<Virtualize ItemsProvider="LoadForecasts" Context="forecast" ItemSize="10">   
    <ItemContent>
        <p>
            <td>@forecast.Id</td>
            <td>@forecast.Date.ToShortDateString()</td>
            <td>@forecast.TemperatureC</td>
            <td>@forecast.TemperatureF</td>
            <td>@forecast.Summary</td>
        </p>
    </ItemContent>
    <Placeholder>
        <p>
           Loading...
        </p>
    </Placeholder>
</Virtualize>
```

Now, we can `Loading...` message instead of white screen.

## Conclusion

 .NET 5 brings new feature which is not in a final state. However, we can see that it is big feature, which makes developers life easier. You can find source code of the post on [github](https://github.com/nightBaker/examples/tree/master/examples/BlazorVirtualizeComponent/BlazorVirtualizeComponentTester).
