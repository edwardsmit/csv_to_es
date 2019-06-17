defmodule CsvToEs.Loader do
  alias CsvToEs.Parsers.SemicolonCsv, as: Csv

  def start_load(filename) do
    partition_opts = [
      window: Flow.Window.global() |> Flow.Window.trigger_every(1000),
      stages: 1
    ]

    Mojito.put("http://localhost:9200/elixir-csv")

    Mojito.put(
      "http://localhost:9200/elixir-csv/_settings",
      [{"Content-Type", "application/json"}],
      Jason.encode!(%{"index" => %{"number_of_replicas" => 0, "refresh_interval" => -1}})
    )

    filename
    |> File.stream!(read_ahead: 100_000)
    |> Csv.parse_stream(skip_headers: false)
    |> convert_csv_lines_to_map()
    |> Flow.from_enumerable()
    |> Flow.partition(partition_opts)
    |> Flow.map(&Jason.encode!(&1))
    |> Flow.reduce(&init_batch/0, &create_batch(&1, &2))
    |> Flow.on_trigger(&ship_batch(&1))
    |> Flow.run()

    Mojito.put(
      "http://localhost:9200/elixir-csv/_settings",
      [{"Content-Type", "application/json"}],
      Jason.encode!(%{"index" => %{"number_of_replicas" => 1, "refresh_interval" => "30s"}})
    )
  end

  defp ship_batch(batch_of_json_lines) do
    {:ok, _response} =
      Mojito.post(
        "http://localhost:9200/_bulk",
        [{"Content-Type", "application/x-ndjson"}],
        Enum.join(batch_of_json_lines, ""),
        timeout: 60_000
      )

    {[], []}
  end

  defp init_batch() do
    []
  end

  defp create_batch(json_line, acc) do
    index_statement = ~s({"index": { "_index": "elixir-csv"}}\n)
    [index_statement | [json_line | [~s(\n) | acc]]]
  end

  defp convert_csv_lines_to_map(stream) do
    header =
      stream
      |> Stream.take(1)
      |> Enum.to_list()
      |> List.first()

    stream
    |> Stream.drop(1)
    |> Stream.map(fn values -> Stream.zip(header, values) |> Enum.to_list() |> Map.new() end)
  end
end
