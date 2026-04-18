defmodule CaravelaDemoWeb.GeneratorDiff do
  @moduledoc """
  Compares a baseline snapshot with live generator output and returns
  a flat per-file status plus aggregate counts.
  """

  @type status :: :added | :removed | :changed | :unchanged
  @type file_diff :: %{path: String.t(), status: status(), bytes_delta: integer()}
  @type summary :: %{
          total: non_neg_integer(),
          added: non_neg_integer(),
          removed: non_neg_integer(),
          changed: non_neg_integer(),
          unchanged: non_neg_integer(),
          has_baseline: boolean(),
          files: %{optional(String.t()) => status()}
        }

  @spec compare([map()], [map()]) :: summary()
  def compare(baseline, current) when is_list(baseline) and is_list(current) do
    base = Map.new(baseline, fn f -> {f.path, f} end)
    curr = Map.new(current, fn f -> {f.path, f} end)

    file_statuses =
      (Map.keys(base) ++ Map.keys(curr))
      |> Enum.uniq()
      |> Enum.into(%{}, fn path -> {path, status_for(Map.get(base, path), Map.get(curr, path))} end)

    counts = Enum.frequencies_by(Map.values(file_statuses), & &1)

    %{
      total: map_size(file_statuses),
      added: Map.get(counts, :added, 0),
      removed: Map.get(counts, :removed, 0),
      changed: Map.get(counts, :changed, 0),
      unchanged: Map.get(counts, :unchanged, 0),
      has_baseline: baseline != [],
      files: Enum.into(file_statuses, %{}, fn {k, v} -> {k, Atom.to_string(v)} end)
    }
  end

  defp status_for(nil, _curr), do: :added
  defp status_for(_base, nil), do: :removed
  defp status_for(%{content: a}, %{content: b}) when a == b, do: :unchanged
  defp status_for(_, _), do: :changed
end
