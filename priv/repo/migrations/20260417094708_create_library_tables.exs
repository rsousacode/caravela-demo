defmodule Caravela.Migrations.Library.Create do
  use Ecto.Migration

  def change do
    create table(:library_publishers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :country, :string

      timestamps(type: :utc_datetime)
    end

    create table(:library_authors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :bio, :text
      add :born, :date

      timestamps(type: :utc_datetime)
    end

    create table(:library_books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :isbn, :string
      add :published, :boolean, default: false
      add :price, :decimal, precision: 10, scale: 2
      add :author_id, references(:library_authors, type: :binary_id, on_delete: :nilify_all)

      add :publisher_id, references(:library_publishers, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:library_books, [:author_id])
    create index(:library_books, [:publisher_id])
  end
end
