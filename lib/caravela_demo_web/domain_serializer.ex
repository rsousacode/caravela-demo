defmodule CaravelaDemoWeb.DomainSerializer do
  @moduledoc """
  Converts a `Caravela.Schema.Domain` IR into a JSON-safe map that can
  be shipped as props to the Svelte layer.

  The wire format is intentionally shallow and stringy — opts that
  contain regexes, anonymous functions, or other non-JSON values are
  rendered as human-readable strings (e.g. `~r/^\\d{13}$/` → `"~r/^\\d{13}$/"`).
  """

  alias Caravela.Schema.{Domain, Entity, Field, Relation}

  @spec serialize(Domain.t()) :: map()
  def serialize(%Domain{} = domain) do
    %{
      module: inspect(domain.module),
      multi_tenant: Domain.multi_tenant?(domain),
      version: Domain.version(domain),
      entities: Enum.map(domain.entities, &entity/1),
      relations: Enum.map(domain.relations, &relation/1),
      hooks:
        Enum.map(domain.hooks, fn h ->
          %{action: to_string(h.action), entity: to_string(h.entity), arity: h.arity}
        end),
      permissions:
        Enum.map(domain.permissions, fn p ->
          %{action: to_string(p.action), entity: to_string(p.entity), arity: p.arity}
        end),
      stats: %{
        entity_count: length(domain.entities),
        field_count: domain.entities |> Enum.map(&length(&1.fields)) |> Enum.sum(),
        relation_count: length(domain.relations),
        hook_count: length(domain.hooks),
        permission_count: length(domain.permissions)
      }
    }
  end

  defp entity(%Entity{} = e) do
    %{
      name: to_string(e.name),
      field_count: length(e.fields),
      fields: Enum.map(e.fields, &field/1)
    }
  end

  defp field(%Field{} = f) do
    %{
      name: to_string(f.name),
      type: to_string(f.type),
      required: Keyword.get(f.opts || [], :required, false) == true,
      default: render_opt(Keyword.get(f.opts || [], :default)),
      constraints: constraints(f.opts)
    }
  end

  defp relation(%Relation{} = r) do
    %{
      from: to_string(r.from),
      to: to_string(r.to),
      type: to_string(r.type),
      opts: Enum.map(r.opts || [], fn {k, v} -> %{key: to_string(k), value: render_opt(v)} end)
    }
  end

  defp constraints(opts) do
    opts
    |> List.wrap()
    |> Enum.reject(fn {k, _} -> k in [:required, :default] end)
    |> Enum.map(fn {k, v} -> %{key: to_string(k), value: render_opt(v)} end)
  end

  defp render_opt(nil), do: nil
  defp render_opt(v) when is_binary(v), do: v
  defp render_opt(v) when is_atom(v), do: to_string(v)
  defp render_opt(v) when is_number(v), do: v
  defp render_opt(v) when is_boolean(v), do: v
  defp render_opt(%Regex{} = r), do: inspect(r)
  defp render_opt(v), do: inspect(v)
end
