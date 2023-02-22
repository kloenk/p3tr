defmodule P3tr.Discord.Pronoun do
  use Discord.Commands, otp_app: :p3tr

  command "pronoun", "Pronoun management" do
    subcommand("prompt", "send Prompt")

    sub_command_group "config", "Pronoun config" do
      subcommand("default", "Load default pronouns")
      subcommand("remove-all", "Remove all pronouns")

      subcommand "add", "Add pronoun" do
        string("key", "Pronoun key", required: true)
        string("name", "Pronoun name")
        string("color", "Pronoun color")
      end

      subcommand "remove", "Remove pronoun" do
        role("pronoun", "Pronoun to remove")
      end
    end
  end
end
