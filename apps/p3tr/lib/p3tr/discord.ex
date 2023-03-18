defmodule P3tr.Discord do
  use Discord, otp_app: :p3tr, role: P3tr.Repo.Role
end
