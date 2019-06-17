# CsvToEs

This is a POC to parse a CSV in a streaming fashion and store a JSON-object
derived from a CSV-line in Elasticsearch, using the Bulk-API of Elasticsearch.

## Build

```shell
mix escript.build
```

## Load a CSV

```shell
./csv_to_es <FILENAME>
```

## Limitations

* Currently only a `;`-separated file is supported which must have a header-line
for naming the ES-doc-fields. This project has only been tested with a
bagadres-full.csv file downloaded from NLExtract.nl
[download](https://data.nlextract.nl/bag/csv/bag-adressen-full-laatst.csv.zip)
* Elasticsearch is expected to run at [localhost](http://localhost:9200)
* As we don't create an `_id` field explicitly, multiple runs of the tool will
create duplicates
* The batch-size is fixed at 1_000 this figure has been made up with no test
or knowledge whatsoever
* The time-out of 60s has been chose as "large enough" to avoid timeouts
* No error-handling is implemented
* The target index is hardcoded to `elixir-csv`

## Tip

Before running this tool you'd best set the `number_of_replicas` to `0` and the
`refresh_interval` to `-1` for the target-elasticsearch-index `elixir-csv`

## Can I use this in Production

Probably not as is
