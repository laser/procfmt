# procfmt

> I'm getting totally sick of reformatting these Procfiles by hand
>
> -- me

## About

This project includes a Foreman Procfile formatter, written in Bash. It
does only a few things, but these are things that were very annoying to
do by hand, such as:

1. Left-align the commands
2. Alpha-sort the environment variables

## Demo

![procfmt](https://user-images.githubusercontent.com/884507/208982771-79110bac-0e5b-4764-980d-27310c4a48b9.gif)

## Requirements

This is a Bash script, and uses Bash arrays. Other than that, is has no
dependencies.

## Usage

```shell
$ cat Procfile | ./procfmt.sh --ignore feedbin_clock > ./Procfile.formatted
```
