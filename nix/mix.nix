{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    bunt = buildMix rec {
      name = "bunt";
      version = "0.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "19bp6xh052ql3ha0v3r8999cvja5d2p6cph02mxphfaj4jsbyc53";
      };

      beamDeps = [];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.10.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0blhnxpy1r0i9wbjiy97gbdb8gfqpk6x8l3qi025i77ywzb9syp8";
      };

      beamDeps = [];
    };

    chacha20 = buildMix rec {
      name = "chacha20";
      version = "1.0.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0j93ph8j02lk6xw3kzn7kf0vimjscfq52zysy3qh76df479za9r0";
      };

      beamDeps = [];
    };

    connection = buildMix rec {
      name = "connection";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1746n8ba11amp1xhwzp38yfii2h051za8ndxlwdykyqqljq1wb3j";
      };

      beamDeps = [];
    };

    remedy_cowlib = buildRebar3 rec {
      name = "remedy_cowlib";
      version = "2.11.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0c5ij4f6bihg05q0rrsj2q83x1y3aldinpr86ihwp070131ksq8b";
      };

      beamDeps = [];
    };

    credo = buildMix rec {
      name = "credo";
      version = "1.7.0-rc.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0vpfrfjlskfipw34khmnh8xahshy9328h4adh1by4kyqbk5hk658";
      };

      beamDeps = [ bunt file_system jason ];
    };

    curve25519 = buildMix rec {
      name = "curve25519";
      version = "1.0.5";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0b8ryj7icn2x7b5nrvqd7yqpfawi3fwmzbn3bx6ls5gibgakmfhg";
      };

      beamDeps = [];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.4.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "04iwywfqf8k125yfvm084l1mp0bcv82mwih7xlpb7kx61xdw29y1";
      };

      beamDeps = [ connection telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0xzm8hfhn8q02rmg8cpgs68n5jz61wvqg7bxww9i1a6yanf6wril";
      };

      beamDeps = [];
    };

    earmark_parser = buildMix rec {
      name = "earmark_parser";
      version = "1.4.30";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "06ssrl0b61i50q802pzr2kdmmlj32f27p4h6nb87613bsg18alrv";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.9.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0xgfz1pzylj22k0qa8zh4idvd4139b1lwnmq33na8fia2j69hpyy";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.9.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0w1zplm8ndf10dwxffg60iwzvbz3hyyiy761x91cvnwg6nsfxd8y";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    ed25519 = buildMix rec {
      name = "ed25519";
      version = "1.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1iqfr14gzf1gbkdwjcic4c9yxp6qz4swl68hx1482gda7x7vib0d";
      };

      beamDeps = [];
    };

    equivalex = buildMix rec {
      name = "equivalex";
      version = "1.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1z25w0h81irkflyxfyni188p53srs859q6s6dv9iflc5vcd33yj6";
      };

      beamDeps = [];
    };

    ex_doc = buildMix rec {
      name = "ex_doc";
      version = "0.29.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1xkljn0ggg7fk8qv2dmr2m40h3lmfhi038p2hksdldja6yk5yx5p";
      };

      beamDeps = [ earmark_parser makeup_elixir makeup_erlang ];
    };

    expo = buildMix rec {
      name = "expo";
      version = "0.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1wmbycv8mdfngxnn3c3bi8b3kx9md4n1p96p7yjpyz4bxj1idvd8";
      };

      beamDeps = [];
    };

    exsync = buildMix rec {
      name = "exsync";
      version = "0.2.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "15h8x398jwag80l9gf5q8r9pmpxgj5py8sh6m9ry9fwap65jsqpp";
      };

      beamDeps = [ file_system ];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "0.2.10";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1p0myxmnjjds8bbg69dd6fvhk8q3n7lb78zd4qvmjajnzgdmw6a1";
      };

      beamDeps = [];
    };

    gen_stage = buildMix rec {
      name = "gen_stage";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "00xmyy835zqz148sn9z86jvfgj9jpwapavd1xp2djx1fqy90kr63";
      };

      beamDeps = [];
    };

    gettext = buildMix rec {
      name = "gettext";
      version = "0.22.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0pdcj2hmf9jgv40w3594lqksvbp9fnx98g8d1kwy73k6mf6mn45d";
      };

      beamDeps = [ expo ];
    };

    remedy_gun = buildRebar3 rec {
      name = "remedy_gun";
      version = "2.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0vj49hlh7c2dlddcs1bnnxjz7klgv2ry36w0hrzpaayizf2mls5n";
      };

      beamDeps = [ cowlib ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0891p2yrg3ri04p302cxfww3fi16pvvw1kh4r91zg85jhl87k8vr";
      };

      beamDeps = [ decimal ];
    };

    kcl = buildMix rec {
      name = "kcl";
      version = "1.4.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "01dzxbz1036zx2cdrb7np5ga289bm1j8a9abhgv2v42dhk9ks24z";
      };

      beamDeps = [ curve25519 ed25519 poly1305 salsa20 ];
    };

    makeup = buildMix rec {
      name = "makeup";
      version = "1.1.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "19jpprryixi452jwhws3bbks6ki3wni9kgzah3srg22a3x8fsi8a";
      };

      beamDeps = [ nimble_parsec ];
    };

    makeup_elixir = buildMix rec {
      name = "makeup_elixir";
      version = "0.16.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1rrqydcq2bshs577z7jbgdnrlg7cpnzc8n48kap4c2ln2gfcpci8";
      };

      beamDeps = [ makeup nimble_parsec ];
    };

    makeup_erlang = buildMix rec {
      name = "makeup_erlang";
      version = "0.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1fvw0zr7vqd94vlj62xbqh0yrih1f7wwnmlj62rz0klax44hhk8p";
      };

      beamDeps = [ makeup ];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0szzdfalafpawjrrwbrplhkgxjv8837mlxbkpbn5xlj4vgq0p8r7";
      };

      beamDeps = [];
    };

    nimble_parsec = buildMix rec {
      name = "nimble_parsec";
      version = "1.2.3";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1c3hnppmjkwnqrc9vvm72kpliav0mqyyk4cjp7vsqccikgiqkmy8";
      };

      beamDeps = [];
    };

    nostrum = buildMix rec {
      name = "nostrum";
      version = "0.6.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0spp5c3l30pxslqsinvc0qizv9w7k26b7glgj9j6cxhkwi3mm4i7";
      };

      beamDeps = [ certifi gen_stage gun jason kcl mime ];
    };

    poly1305 = buildMix rec {
      name = "poly1305";
      version = "1.0.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0fxwgp22jx9hb88vlnynb539smwk2r5dnf9ikca5w6d5c536hkp1";
      };

      beamDeps = [ chacha20 equivalex ];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.16.5";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1s5jbwfzsdsyvlwgx3bqlfwilj2c468wi3qxq0c2d23fvhwxdspd";
      };

      beamDeps = [ connection db_connection decimal jason ];
    };

    salsa20 = buildMix rec {
      name = "salsa20";
      version = "1.0.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1ilaqpynkcs1hkdf2d3qryi7jqhlsm4cxrv1znqdsqx5rzcdqpbl";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1mgyx9zw92g6w8fp9pblm3b0bghwxwwcbslrixq23ipzisfwxnfs";
      };

      beamDeps = [];
    };

    typed_ecto_schema = buildMix rec {
      name = "typed_ecto_schema";
      version = "0.4.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0fybixpflcr9rk92avycra029za0qfnwcnanvm1zanykg4prdil5";
      };

      beamDeps = [ ecto ];
    };
  };
in self

