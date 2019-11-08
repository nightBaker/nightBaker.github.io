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
[go to solution](#printing-messages-solutions)

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

[go to solution](#printing-messages-solutions)

3. Print 

```powershell
 0
 00
 000
 0000
 00000
```

[go to solution](#printing-messages-solutions)

4. Print big `W`

```powershell
*       **       *
 *     *  *     *
  *   *    *   *
   * *      * *
    *        *
```
[go to solution](#printing-messages-solutions)


### Arithmetic exercies

Following line of code allows read line from **console** input stream
```csharp
var line = Console::ReadLine();
```

For example, program sums two numbers and output result

```csharp
class Program
{
    static void Main(string[] args)
    {
        string aInput = Console.ReadLine();
        string bInput = Console.ReadLine();

        int a = int.Parse(aInput);
        int b = int.Parse(bInput);

        int sum = a + b;

        Console.WriteLine(sum);
    }
}
```

**Note** 
`Console.ReadLine()` returns string. *String* is data type which represents text. However, we wait for number as input data. So we need to get number from input string. We can use method `int.Parse` of type *int*, which returns *Integer* (int) data type. *Integer* represents number. 

#### Why we need data types
Every time we want to create variable in our source code, firstly we must define data type of variable. One of the reason is that different types behave differently. For example,

```csharp

    int a = 5;
    int b = 10;
    int sum1 = a + b; // will be 15

    string x = "5";
    string y = "10"
    string sum2 = x + y; // will be "510"

```

1. Compute $$ (a + 4b)(a - 3b) + a^2 $$, where `a` and `b` should be entered by user. When `a = 10, b = 15`, result is `-2350`  
**Note.** Use [Math.Pow](https://docs.microsoft.com/en-us/dotnet/api/system.math.pow?view=netframework-4.8) method for getting a number raised to specified power  
[go to solution](#arithmetic-exercies-solutions)

2. <div > $$ |x| + x^7  $$ </div> where `x` is entered by user
[go to solution](#arithmetic-exercies-solutions)

3. <div> $$ \displaystyle\frac{|x-5|-\sin{x}}{3}+\sqrt{x^2+2014}\cos{2x-3} $$ </div>
[go to solution](#arithmetic-exercies-solutions)

4. <div> $$ e^{x-2}+|\sin(x)|-x^{4}\cdot\cos{\frac{1}{x}} $$ </div>

5. User enters 2 numbers, compute sum and production of these numbers

6. User enters 3 numbers. Double the first number, reduce second number by 3,
square the third number and then the sum of the new three numbers.

7. User enters 3 numbers. Find average if these numbers and the difference between the doubled sum of first and third numbers and the tripple second number.

8. User enters  side of square. Find perimeter and area of the square

9. User enters price of one kilo of candies and 1kg of cookies. Find price of 300 grams candies and 400 grams cookies. Find price of 2kg cookies and 1.8kg of candies.  


----

## Solutions

### Printing messages solutions

1. 

```csharp

static void Main(string[] args)
{
    Console.WriteLine("Hello world, my name is NightBaker");
}

```

2. 

```csharp
Console.WriteLine("   ######\n" +
                " ##       ##\n" +
                "#\n" +
                "#\n" +
                "#\n" +
                "#\n" +
                "#\n" +
                " ##      ##\n" +
                "   ######");
```

**NOTE** `\n` - means new line

3. 

```csharp
Console.WriteLine("0\n00\n000\n0000\n00000")
```

**NOTE** `\n` - means new line

4. 

```csharp
Console.WriteLine("*       **       *");
Console.WriteLine(" *     *  *     *");
Console.WriteLine("  *   *    *   *");
Console.WriteLine("   * *      * *");
Console.WriteLine("    *        * ");
```

---

### Arithmetic exercies solutions

1.

```csharp
Console.WriteLine("Write 1st number");
string aInput = Console.ReadLine();
Console.WriteLine("Write 2nd number");
string bInput = Console.ReadLine();


int a = int.Parse(aInput);
int b = int.Parse(bInput);

double result = (a + (4 * b)) * (a-(3 * b)) - Math.Pow(a,2) ;
Console.WriteLine("(a+4b)(a−3b)+a2 = "+ result);
```

2.

```csharp
Console.WriteLine("Write number");
string aInput = Console.ReadLine();



int a = int.Parse(aInput);

double result = Math.Abs(a) + Math.Pow(a, 7);
Console.WriteLine("|x|+x^7 = " + result);
```

3.

```csharp
Console.WriteLine("Write number");
string aInput = Console.ReadLine();



int a = int.Parse(aInput);

double result = (Math.Abs(a - 5) - Math.Sin(a))/3 + Math.Sqrt(Math.Pow(a, 2) + 2014) *  Math.Cos(2 * a) - 3; 
Console.WriteLine("Answer = " + result);
```

4.

```csharp
Console.WriteLine("Write number");
string aInput = Console.ReadLine();



int a = int.Parse(aInput);

double result = Math.Exp(a - 2) + Math.Abs(Math.Sin(a)) - Math.Pow(a, 4) * Math.Cos(1 / a);
Console.WriteLine("Answer = " + result);
```

5.

```csharp
Console.WriteLine("Write 1st number ");
string aInput = Console.ReadLine();
Console.WriteLine("Write 2nd number ");
string bInput = Console.ReadLine();

int a = int.Parse(aInput);
int b = int.Parse(bInput);


int sum = a + b;
int prod = a * b;
Console.WriteLine(a + " + "+ b + " = "+ sum);
Console.WriteLine(a + " * " + b + " = " + prod);
```