---
layout: post
title: Blazor + FluentValidation - lovely awesome couple
date:       2019-11-12
summary:    Share validation between client and server
categories: blazor fluetValidator webassembly dotnet 
---

## Fluent Validation

[Fluent validation]([https://fluentvalidation.net/](https://fluentvalidation.net/) is a popular library for validation using strongly typed rules written in code. For example:

```csharp

```

## Prerequisites

* Create blazor webassembly app based on .net ![](\images\blazor-fluent-validator\2019-11-12-17-57-23-image.png)
  
  ![](\images\blazor-fluent-validator\2019-11-12-17-59-57-image.png)
  
  Your solution should look like following example
  
  
  
  ![](\images\blazor-fluent-validator\2019-11-13-08-56-29-image.png)
  
  
  
  

`FluentValidationExample.Shared` is library for sharing source code between frontend and backend. When before we used fluentvalidation we defined any validation rules in server side, because we could not reuse it in frontend. However, with advent of Blazor framework, it became easier to share code. So now we easily share not only models, but also information about validation.



## Form and validator

Let's create form model and validator in shared project. 

```csharp
namespace FluentValidationExample.Shared
{
    public class MyFormModel
    {
        public string FirstName { get; set; }
        
        public string LastName { get; set; }

        public string Email { get; set; }        

        public string Address { get; set; }

        public int Age { get; set; }
    }
}
```

To use fluent validation we need to intall package firstly.

```shell
dotnet add package FluentValidation
```

```csharp
namespace FluentValidationExample.Shared
{
    public class MyFormModelValidator : AbstractValidator<MyFormModel>
    {
        public MyFormModelValidator()
        {
            RuleFor(x => x.FirstName).NotEmpty().WithMessage("Please specify a first name");
            RuleFor(x => x.LastName).NotEmpty().WithMessage("Please specify a last name");
            RuleFor(x => x.Email).NotEmpty().EmailAddress().WithMessage("Please specify a valid email");
            RuleFor(x => x.Address).NotEmpty().Length(5,50).WithMessage("Please specify a valid address"); ;
            RuleFor(x => x.Age).NotEqual(0).WithMessage("Age should be more than zero");
        }
    }
}
```

Now we can use this validator in both server and client side. We will not cover server side configuration in this post and assume that we already have server side configuration.



## Client side configuration

Client side blazor app has default validation using data annotations. For example, our form could look like following example

```html
@using FluentValidationExample.Shared
@page "/myform"



    <EditForm Model="@FormModel" OnValidSubmit="@HandleValidSubmit">
        <DataAnnotationsValidator />
        <ValidationSummary />

        <InputText id="firstName" @bind-Value="FormModel.FirstName" />

        <InputText id="lastName" @bind-Value="FormModel.LastName" />

        <InputText id="email" @bind-Value="FormModel.Email" />

        <InputText id="address" @bind-Value="FormModel.Address" />

        <InputNumber id="age" @bind-Value="FormModel.Age" />

        <button type="submit">Submit</button>
    </EditForm>


@code {
    private MyFormModel FormModel { get; set; } = new MyFormModel();

    private void HandleValidSubmit()
    {
        Console.WriteLine("OnValidSubmit");
    }
}
```

It will not work, because we don't use default data anotations validation. So we have to replace default `<DataAnnotationsValidator />` with our fluent validation validator component.

Firstly we need install several packages to client project.

```powershell
dotnet add package FluentValidation
dotnet add package Accelist.FluentValidation.Blazor
dotnet add package FluentValidation.DependencyInjectionExtensions
```

`Accelist.FluentValidation.Blazor` brings blazor component for replacing `<DataAnnotationsValidator />` with `<FluentValidation.FluentValidator></FluentValidation.FluentValidator>`, so our razor view looks like

```csharp
@using FluentValidationExample.Shared
@page "/myform"



<EditForm Model="@FormModel" OnValidSubmit="@HandleValidSubmit">
    <FluentValidation.FluentValidator></FluentValidation.FluentValidator>

    <ValidationSummary />

    <div class="form-group">
        <InputText id="firstName" @bind-Value="FormModel.FirstName" />
        <ValidationMessage For="() => FormModel.FirstName"></ValidationMessage>
    </div>
    <div class="form-group">
        <InputText id="lastName" @bind-Value="FormModel.LastName" />
        <ValidationMessage For="() => FormModel.LastName"></ValidationMessage>
    </div>
    <div class="form-group">
        <InputText id="email" @bind-Value="FormModel.Email" />
        <ValidationMessage For="() => FormModel.Email"></ValidationMessage>
    </div>
    <div class="form-group">
        <InputText id="address" @bind-Value="FormModel.Address" />
        <ValidationMessage For="() => FormModel.Address"></ValidationMessage>
    </div>
    <div class="form-group">
        <InputNumber id="age" @bind-Value="FormModel.Age" />
        <ValidationMessage For="() => FormModel.Age"></ValidationMessage>
    </div>

    <button type="submit">Submit</button>
</EditForm>


@code {
    private MyFormModel FormModel { get; set; } = new MyFormModel();

    private void HandleValidSubmit()
    {
        Console.WriteLine("OnValidSubmit");
    }
}
```

Also we must add FluentValidation to dependency injection container in `Startup.cs` 

```csharp

namespace FluentValidationExample.Client
{
    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddValidatorsFromAssemblyContaining<MyFormModelValidator>();
        }

        public void Configure(IComponentsApplicationBuilder app)
        {
            app.AddComponent<App>("app");
        }
    }
}

```

Run app. Go to `/myform` in browser and you should get 

![](\images\blazor-fluent-validator\2019-11-13-10-13-03-image.png)

That's all you need for using FluentValidaiton in blazor app.

# Conclusion

Blazor has default data anotations validation. However, if you use FluentValidaiton library you still can reuse your validations rules in frontend. As we can see, it is pretty easy to implement.

[**Example source code**]([https://github.com/nightBaker/examples/tree/master/examples/FluentValidationExample](https://github.com/nightBaker/examples/tree/master/examples/FluentValidationExample)
