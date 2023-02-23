# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      subcommand: 2,
      subcommand: 3,
      command: 2,
      sub_command_group: 2,
      sub_command_group: 3,
      string: 2,
      string: 3,
      role: 2,
      role: 3
    ]
  ]
]
