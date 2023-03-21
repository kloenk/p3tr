defmodule P3tr.ReleaseTasks do
  def run(args) do
    [task | args] = String.split(args)

    case task do
      "migrate" -> migrate(args)
      "rollback" -> rollback(args)
    end
  end

  defp migrate(args) do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp rollback(args) do
    # FIXME: implement
  end

  @app :p3tr
  defp rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
