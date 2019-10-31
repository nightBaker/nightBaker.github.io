---
layout: post
title: Learn to code
date:       2019-10-31
summary:    Learning how to code with C# in .net core
categories: net core console
---

## Code

Let's learn how to code from scratch.

### Prerequisites

* Visual studio community edition (2019 - recommended)


### Create first project

Let's create our first project - console application. You can name it as you wish. 

![creating console app]({{ "/images/learn-code/1/create-console-app.gif" | absolute_url }})

Your newly created project has following structure
![console app structure]({{ "/images/learn-code/1/structure.png" | absolute_url }})

Where `Programm.cs` is file with `Program` class and `static void Main(string[] args)` method, which is entry point of your program.

## Exercises

### Printing messages

1. Print following message: `Hello world, my name is <YourName>`

<details><summary><i>show solution</i></summary>
<p>

```csharp
static void Main(string[] args)
{
    Console.WriteLine("Hello world, my name is NightBaker");
}
```

</p>
</details>

2. Write a program to print a big 'C' using hash (`#`)

```powershell
    ######
  ##      ##
 #
 #
 #
 #
 #
  ##      ##
    ######
```

3. Print 

```powershell
 0
 00
 000
 0000
 00000
```
4. Print big `W`

```powershell
*       **       *
 *     *  *     *
  *   *    *   *
   * *      * *
    *        *
```