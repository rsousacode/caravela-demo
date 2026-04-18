defmodule CaravelaDemoWeb.GeneratorSnapshot do
  @moduledoc """
  Reads and writes baseline snapshots of generator output to
  `priv/generator_snapshots/<id>.json`.

  Snapshots are a committed record of what each `mix caravela.gen.*`
  command emits at a known-good point in time. The UI diffs the live
  output against these baselines so stakeholders can see exactly what
  changes when the domain evolves.

  Regenerate with `mix caravela_demo.snapshot`.
  """

  @subpath "generator_snapshots"

  @doc "Load every snapshot on disk into `%{id => [files]}`."
  @spec load_all() :: %{optional(String.t()) => [map()]}
  def load_all do
    dir = read_dir()

    case File.ls(dir) do
      {:ok, entries} ->
        entries
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.into(%{}, fn entry ->
          id = Path.rootname(entry)
          {id, read(Path.join(dir, entry))}
        end)

      _ ->
        %{}
    end
  end

  @doc "Write a snapshot for a single generator id."
  @spec write(String.t(), [map()]) :: :ok | {:error, term()}
  def write(id, files) when is_binary(id) and is_list(files) do
    dir = write_dir()
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{id}.json")
    payload = %{id: id, captured_at: DateTime.utc_now() |> DateTime.to_iso8601(), files: files}
    File.write(path, Jason.encode_to_iodata!(payload, pretty: true))
  end

  defp read(path) do
    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"files" => files}} when is_list(files) ->
            Enum.map(files, &normalize/1) |> Enum.reject(&is_nil/1)

          _ ->
            []
        end

      _ ->
        []
    end
  end

  defp normalize(%{"path" => p, "content" => c} = f) do
    %{
      path: p,
      content: c,
      language: Map.get(f, "language", "text"),
      bytes: Map.get(f, "bytes", byte_size(c))
    }
  end

  defp normalize(_), do: nil

  # Read from the compiled app's priv — this is where Mix copies
  # priv/generator_snapshots at build time.
  defp read_dir do
    try do
      Path.join(:code.priv_dir(:caravela_demo), @subpath)
    catch
      _, _ -> Path.join("priv", @subpath)
    end
  end

  # Write to the project's source tree so snapshots can be committed.
  defp write_dir, do: Path.join([File.cwd!(), "priv", @subpath])
end
