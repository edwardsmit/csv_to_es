defmodule CsvToEs.CLI do
  def main(args) do
    args
    |> parse_arguments
    |> start_load
  end

  defp parse_arguments(args) do
    {_, filename, _} = OptionParser.parse(args)
    filename
  end

  defp start_load(filename) do
    CsvToEs.Loader.start_load(filename)
  end
end
