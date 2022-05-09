# elgato.sh

Script to control my Elgato Key Light (https://www.elgato.com/en/key-light)

## Usage

```bash
$ ./elgato.sh help
usage: ./elgato.sh <on|off|brightness number|temperature number>
```

## Examples

### Turn on / off the Key Light

Example output is shown here, it is omitted in the rest for brevity.

```bash
$ ./elgato.sh on
My Key Light (my-key-light.local.:9123)
=======================================
brightness:   50
on:           1
temperature:  250
```

```bash
$ ./elgato.sh off
```

Will swap the current state (`on` to `off` or vice versa):

```bash
$ ./elgato.sh toggle
```

### Set brightness / temperature

```bash
$ ./elgato.sh brightness 10
```

```bash
$ ./elgato.sh temperature 25
```

### Increment brightness / temperature

```bash
$ ./elgato.sh brightness +10
```

```bash
$ ./elgato.sh temperature -15
```

### Do multiple changes at once

```bash
$ ./elgato.sh brightness +10 temperature 200 on
```

### Last one wins

Expect the light to be `on` and have `brightness` `15` (`20 - 5`), leaving
`temperature` constant:

```bash
$ ./elgato.sh off toggle toggle on brightness +5 brightness 20 brightness -5
```

