# procfmt

> I'm getting totally sick of reformatting these Procfiles by hand
>
> -- me

## Demo

![procfmt](https://user-images.githubusercontent.com/884507/208982771-79110bac-0e5b-4764-980d-27310c4a48b9.gif)

## Requirements

This is a Bash script, and uses Bash arrays. Other than that, is has no
dependencies.

## Usage

```shell
$ cat Procfile | ./procfmt.sh --ignore feedbin_clock > ./Procfile.formatted
```
