---
title: "Java 面向对象上机练习"
date: 2026-06-25
authors:
  - "萌睡梦"
tags:
  - "Java"
  - "面向对象"
---

### 1. 图形面积批量计算

【问题描述】

定义抽象图形父类 Shape，包含抽象方法 getArea() 计算面积。定义圆形 Circle、矩形 Rectangle 子类继承抽象类并实现面积计算方法。创建抽象父类对象数组，存储2个圆形、2个矩形对象，多态批量计算并输出所有图形面积，保留两位小数。

【输入形式】

第一、二行输入圆形半径；第三、四行输入矩形长和宽

【输出形式】

逐行输出每个图形的类型及对应面积，保留两位小数

【样例输入】

```text
2
3
2  5
4  6
```

【样例输出】

```text
圆形面积：12.57
圆形面积：28.27
矩形面积：10.00
矩形面积：24.00
```

【样例说明】

利用抽象父类数组存储不同子类对象，通过多态机制批量调用子类重写的面积方法，实现统一批量处理不同子类对象的效果。

【评分标准】

1. 抽象类及抽象方法定义规范（20分）
2. 两个子类正确继承并实现抽象方法（25分）
3. 父类对象数组实现多态存储子类对象（25分）
4. 批量遍历计算，结果精准、格式统一（30分）

【参考代码】

```java
import java.util.Scanner;

abstract class Shape {
    public abstract double getArea();
}

class Circle extends Shape {
    private double radius;

    public Circle(double radius) {
        this.radius = radius;
    }

    @Override
    public double getArea() {
        return Math.PI * radius * radius;
    }
}

class Rectangle extends Shape {
    private double length;
    private double width;

    public Rectangle(double length, double width) {
        this.length = length;
        this.width = width;
    }

    @Override
    public double getArea() {
        return length * width;
    }
}

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        double r1 = sc.nextDouble();
        double r2 = sc.nextDouble();
        double l1 = sc.nextDouble();
        double w1 = sc.nextDouble();
        double l2 = sc.nextDouble();
        double w2 = sc.nextDouble();

        Shape[] shapes = new Shape[4];
        shapes[0] = new Circle(r1);
        shapes[1] = new Circle(r2);
        shapes[2] = new Rectangle(l1, w1);
        shapes[3] = new Rectangle(l2, w2);

        for (Shape s : shapes) {
            if (s instanceof Circle) {
                System.out.printf("圆形面积：%.2f\n", s.getArea());
            } else if (s instanceof Rectangle) {
                System.out.printf("矩形面积：%.2f\n", s.getArea());
            }
        }

        sc.close();
    }
}
```

---

## 实验六：内部类

### 局部内部类

【问题描述】

编写外部类 Calculate，在外部类的普通成员方法 compute() 中定义局部内部类 Sum，要求：

1.方法 compute 接收两个整型参数 a、b；

2.局部内部类中定义方法 getSum()，计算两个数的和并返回结果；

3.在局部内部类外部调用 getSum() 方法，最终输出计算结果；

4.局部内部类仅在 compute 方法内有效。

【输入形式】

控制台输入两个整数，中间用空格分隔。

【输出形式】

输出格式：两数之和：XX

【样例输入】

15 25

【样例输出】

两数之和：40

【样例说明】

输入 15 和 25，通过方法内的局部内部类完成求和运算并输出结果。

【评分标准】

1. 正确在方法内定义局部内部类（30 分）
2. 局部内部类访问方法局部参数（30 分）
3. 方法逻辑完整，实现求和功能（20 分）
4. 主方法调用流程正确，输出无误（20 分）

【参考代码】

```java
import java.util.Scanner;

public class Main {

    public void compute(int a, int b) {

        class Sum {
            public int getSum() {
                return a + b;
            }
        }

        Sum s = new Sum();
        System.out.println("两数之和：" + s.getSum());
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        int a = sc.nextInt();
        int b = sc.nextInt();

        Main m = new Main();
        m.compute(a, b);
    }
}

```

### 内部类

【问题描述】
定义外部类Person，包含私有成员属性name (姓名)、age (年龄)，以及成员内部类Info。

要求:

1. 外部类提供带参构造方法，为姓名、年龄赋值;
2. 成员内部类Info中定义方法showInfo()，访问外部类私有属性并输出人员完整信息;
3. 在主方法中创建外部类对象，再创建内部类对象，调用showlnfo()方法。

【输入形式】

控制台输入一行字符串(姓名)和一个整数(年龄)，中间用空格分隔。

【输出形式】

按照格式输出人员姓名与年龄，格式:姓名:XXX，年龄:XX

【样例输入】
张三 20

【样例输出】
姓名：张三，年龄：20

【样例说明】

输入姓名为张三、年龄为20，内部类访问外部类私有属性并完成信息打印。

【评分标准】

1. 正确定义外部类及私有成员属性(20分)
2. 正确定义成员内部类(20分)
3. 内部类方法成功访问外部类私有属性(30分)

【参考代码】

```java
import java.util.Scanner;

class Person {
    private String name;
    private int age;

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    class Info {
        public void showInfo() {
            System.out.println("姓名：" + name + "，年龄:" + age);
        }
    }
}

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        String name = sc.next();
        int age = sc.nextInt();

        Person p = new Person(name, age);

        Person.Info info = p.new Info();

        info.showInfo();

        sc.close();
    }
}
```

### 静态内部类

【问题描述】

定义外部类Car，包含私有静态属性brand(品牌)。定义静态内部类Engine，要求:

1. 外部类通过静态方法为静态属性brand赋值;
2. 静态内部类中定义方法printBrand()，访问外部类静态属性并输出;
3. 主方法中直接通过外部类。内部类的方式创建静态内部类对象，调用方法。

【输入形式】

控制台输入一行字符串，表示汽车品牌。

【输出形式】

输出格式:汽车品牌:xxx

【样例输入】

比亚迪

【样例输出】

汽车品牌:比亚迪

【样例说明】

输入品牌名称，外部类静态属性接收数据，静态内部类直接访问并打印。

【评分标准】

1. 正确定义外部类静态私有属性(20分)
2. 正确定义静态内部类(20分)
3. 静态内部类正常访问外部类静态成员(30分)

【参考代码】

```java
import java.util.Scanner;

class Car {

    private static String brand;

    public static void setBrand(String brand) {
        Car.brand = brand;
    }

    static class Engine {
        public void printBrand() {
            System.out.println("汽车品牌:" + brand);
        }
    }
}

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        String brand = sc.nextLine();

        Car.setBrand(brand);

        Car.Engine engine = new Car.Engine();

        engine.printBrand();

        sc.close();
    }
}
```

## 实验四：接口与实现

### **1.** 涉及教师类实现接口MoveAble

【问题描述】设计教师类实现接口MoveAble，显示教师移动方式

【输入形式】无

【输出形式】move with talk

【样例输入】

【样例输出】

【样例说明】

【评分标准】完全正确，满分

【参考代码】

```java
public interface MoveAble{
	public void move();
}

// 教师类实现 MoveAble 接口
class Teacher implements MoveAble {
    @Override
    public void move() {
        System.out.println("move with talk");
    }
}

// 主类（Test）
public class Test {
    public static void main(String[] args) {
        MoveAble t = new Teacher();
        t.move();
    }
}
```

### **2.** 计算圆形面积

【问题描述】实现接口CalculateAble，计算圆面积

【输入形式】圆半径

【输出形式】圆面积

【样例输入】10

【样例输出】Circle Area=314.0

【样例说明】

【评分标准】完全正确，满分

【参考代码】

```java
public interface CalculateAble{
	public double getArea();
}

import java.util.Scanner;

// 圆类实现 CalculateAble 接口
class Circle implements CalculateAble {
    private double radius;

    public Circle(double radius) {
        this.radius = radius;
    }

    @Override
    public double getArea() {
        return 3.14 * radius * radius;   // π取3.14
    }
}

public class Test {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        double r = sc.nextDouble();
        Circle c = new Circle(r);
        System.out.println("Circle Area=" + c.getArea());
        sc.close();
    }
}
```

### 3. 实现接口MoveAble显示手机移动信息

【问题描述】设计学生类Student，实现接口MoveAble中方法，显示学生移动信息

【输入形式】无

【输出形式】move with owner

【样例输入】

【样例输出】

【样例说明】

【参考代码】

```java
public interface MoveAble{
	public void move();
}

// 学生类实现 MoveAble 接口
class Student implements MoveAble {
    @Override
    public void move() {
        System.out.println("move with owner");
    }
}

public class Test {
    public static void main(String[] args) {
        MoveAble s = new Student();
        s.move();
    }
}
```

### **4.** 实现接口MoveAble显示学生移动信息

【问题描述】设计学生类Student，实现接口MoveAble中方法，显示学生移动信息

【输入形式】无

【输出形式】move every day

【样例输入】

【样例输出】

【样例说明】

【评分标准】

【参考代码】

```java
public interface MoveAble{
	public void move();
}

// 学生类实现 MoveAble 接口
class Student implements MoveAble {
    @Override
    public void move() {
        System.out.println("move every day");
    }
}

public class Test {
    public static void main(String[] args) {
        MoveAble s = new Student();
        s.move();
    }
}
```

### **5.** 【修改】计算手机话费

【问题描述】

定义一个接口PayAble，包含计算电话话费的方法pay()。定义电话类Phone，包括属性号码code。定义手机类MobilePhone继承Phone类，包含属性有通话时间time，话费单价price。手机类实现PayAble接口计算话费。话费计算方法：

手机类话费=通话时间*话费单价+上网费用+短信费用。要点提示：在手机类和固定电话类中实现接口PayAble。

【输入形式】输入通话时长，话费单价

【输出形式】话费

【样例输入】120 0.6

【样例输出】Fee=72.0

【样例说明】

【评分标准】完全正确，满分

【参考代码】

```java
public interface PayAble{
	public double pay();
}

import java.util.Scanner;


class Phone {
    protected String code;  // 号码

    public Phone(String code) {
        this.code = code;
    }
}


class MobilePhone extends Phone implements PayAble {
    private double time;   // 通话时间（分钟）
    private double price;  // 话费单价（元/分钟）

    public MobilePhone(String code, double time, double price) {
        super(code);
        this.time = time;
        this.price = price;
    }

    @Override
    public double pay() {
        return time * price;
    }
}

// 主类
public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        double time = sc.nextDouble();
        double price = sc.nextDouble();
        MobilePhone mp = new MobilePhone("123456", time, price);
        System.out.println("Fee=" + mp.pay());
        sc.close();
    }
}
```

## 实验三：继承与多态

### 1. 显示抽象类Person子类信息

【问题描述】请根据已知的程序代码，补全教师类Teacher，显示教师和工人的信息。

【输入形式】无

【输出形式】

My salary is 1886.0

My level is 2

【样例输入】

【样例输出】

【样例说明】

【评分标准】输出正确，满分

【参考代码】

```java
public class Test{
    public static void main(String [] args){
        Teacher t = new Teacher("zhang", 45, 1886);
        Worker w = new  Worker ("wang", 42, 1550,2);        
        t.display();    
        w.display();

    }
}

abstract class Person{
    private String name;
    private int age;
    
    public Person(String name, int age){
        this.name = name;
        this.age = age;
    }
    
    public abstract void display();
}

class Teacher extends Person{
    private double salary;
    
    public Teacher(String name, int age, double salary){
        super(name, age);
        this.salary = salary;
    }
    
    public void display(){
        
System.out.println("My salary is "+ salary);

    }
}

class Worker extends Person{
    
    private double salary;
    private int level;

    public Worker(String name,int age,double salary,int level){
        super(name,age);
        this.salary=salary;
        this.level=level;
    }

    public void display(){
        System.out.println("My level is " + level);
    }

}
```

### 2. 学生类继承抽象类Person显示信息

【问题描述】请根据已知的程序代码，补全学生类Student，显示学生信息。

【输入形式】无

【输出形式】

grade:86.0

【样例输入】

【样例输出】

【样例说明】

【评分标准】输出正确，满分

【参考代码】

```java
public class Test{
    public static void main(String [] args){
        Student s = new Student("zhangsan", 23, 86);
        s.display();
    }
}

abstract class Person{
    private String name;
    private int age;
    
    public Person(String name, int age){
        this.name = name;
        this.age = age;
    }
    
    public abstract void display();
}

class Student extends Person{
    private double grade;
    
    public Student(String name, int age, double grade){
        super(name, age);
        this.grade = grade;
    }
    
    @Override
    public void display()
    {
        System.out.println("grade:" + grade);
    }
}
```

### **3.** 【修改】继承抽象类Phone，显示手机信息

【问题描述】继承抽象类Phone，实现手机类，显示手机信息。

【输入形式】无

【输出形式】

Brand isHUAWEI

OwnerId is130111111111111111

【样例输入】

【样例输出】

【样例说明】

【评分标准】输出正确，满分

【参考代码】

```java
public abstract class Phone{
	private String code;
	
    public Phone(String code){
		this.code = code;
	}

	public abstract void display();

}

// 注意：不要定义 Phone 类，直接继承系统已有的 Phone
class MobilePhone extends Phone {
    public MobilePhone(String code) {
        super(code);   // 调用父类带一个参数的构造方法
    }

    @Override
    public void display() {
        System.out.println("Brand isHUAWEI");
        System.out.println("OwnerId is130111111111111111");
    }
}


public class Main {
    public static void main(String[] args) {
        Phone p = new MobilePhone("任意code");   // 多态
        p.display();
    }
}
```
