# Судьбоносные печеньки

### Собираем

```
$ make
```

### Загружаем

```
# insmod fortunes
```

### Проверяем

```
$ dmesg | tail -1
[xxx.xxx] Fortune module loaded.
```

```
$ lsmod | grep fortune
fortune xxxx 0
```

### Посылаем сообщения в файл

```
$ echo "People are naturally attracted to you." > /proc/fortune
$ echo "You learn from your mistakes... You will learn a lot today." > /proc/fortune
$ echo "A dream you have will come true." > /proc/fortune
```

### Считываем сообщения

```
$ cat /proc/fortune
People are naturally attracted to you.
```
```
$ cat /proc/fortune
You learn from your mistakes... You will learn a lot today.
```
```
$ cat /proc/fortune
A dream you have will come true.
```

### Выгружаем

```
# rmmod fortune
```

### Проверяем

```
$ dmesg | tail -2
[xxx.xxx] Fortune module loaded.
[xxx.xxx] Fortune module unloaded.
```

```
$ lsmod | grep fortune
nothing
```

### Клиним

```
$ make clean
```

## FAQ

> Что делает ваша программа?

Отправляем сообщения фортунки в файл `fortune`, затем считываем их.

> Зачем нужны модули ядра?

Для того чтобы расширять функционал ядра. Тем самым отпадает необходимость перекомпилировать ядро.

> Что значит Used by 0? (lsmod)

Модуль используется ядром.

> Что делает fortune_init?

Функция fortune_init вызывается при загрузке модуля. Дальше по коду:
* выделяем блок памяти с помощью системного вызова `vmalloc`;
* с помощью `memset` заполняем блок нулями;
* создаём `proc_file` (`struct proc_dir_entry`) c именем `fortune` c операциями `fops` (`struct file_operations`);
* инициализируем переменные.

> Что делает fortune_exit?

Функция `fortune_exit` вызывается во время выгрузки модуля.

> Что делают макросы fortune_init и fortune_exit

С помощью этих макросов задаются функции вызываемые при загрузке/выгрузке модуля.

> Что значит 0644? (0666 и т. д.)

Права доступа:
* 4 - read;
* 2 - write;
* 1 - execute.

К примеру, если `0644` - для владельца файла _read & write_, для группы _read_ для остальных _read_.