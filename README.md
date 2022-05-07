# elgato.sh

Script to control my Elgato Key Light (https://www.elgato.com/en/key-light)

## Usage

```bash
$ ./elgato.sh help
usage: ./elgato.sh <on|off|brightness number|temperature number>
```

## Examples

### Turn on / off the Key Light

```bash
$ ./elgato.sh on
```

```bash
$ ./elgato.sh off
```

### Set brightness / temperature

```bash
$ ./elgato.sh brightness 10
```

```bash
$ ./elgato.sh brightness 25 temperature 300
```

### Increment brightness / temperature

```bash
$ ./elgato.sh brightness +10
```

```bash
$ ./elgato.sh temperature -15
```
