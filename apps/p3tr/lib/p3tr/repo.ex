defmodule P3tr.Repo do
  use Ecto.Repo,
    otp_app: :p3tr,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Changeset

  def validate_snowflake(changeset, field, required \\ true) do
    changeset =
      changeset
      |> validate_number(field,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 18_446_744_073_709_551_615
      )

    if required do
      changeset
      |> validate_required(field)
    else
      changeset
    end
  end
end
