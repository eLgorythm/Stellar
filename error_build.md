error[E0425]: cannot find function `init_app` in the crate root
  --> src/api/api.rs:12:12
   |
12 |     crate::init_app();
   |            ^^^^^^^^ not found in the crate root
   |
help: consider importing this function
   |
 3 + use crate::logger::init_app;
   |
help: if you import `init_app`, refer to it directly
   |
12 -     crate::init_app();
12 +     init_app();
   |

warning: unexpected `cfg` condition name: `frb_expand`
  --> src/api/api.rs:10:1
   |
10 | #[frb(init)]
   | ^^^^^^^^^^^^
   |
   = help: expected names are: `docsrs`, `feature`, and `test` and 31 more
   = note: using a cfg inside a attribute macro will use the cfgs from the destination crate and not the ones from the defining crate
   = help: try referring to `frb` crate for guidance on how handle this unexpected cfg
   = help: the attribute macro `frb` may come from an old version of the `flutter_rust_bridge_macros` crate, try updating your dependency with `cargo update -p flutter_rust_bridge_macros`
   = note: see <https://doc.rust-lang.org/nightly/rustc/check-cfg/cargo-specifics.html> for more information about checking conditional configuration
   = note: `#[warn(unexpected_cfgs)]` on by default
   = note: this warning originates in the attribute macro `frb` (in Nightly builds, run with -Z macro-backtrace for more info)

warning: unexpected `cfg` condition name: `frb_expand`
  --> src/api/api.rs:23:1
   |
23 | #[frb]
   | ^^^^^^
   |
   = note: using a cfg inside a attribute macro will use the cfgs from the destination crate and not the ones from the defining crate
   = help: try referring to `frb` crate for guidance on how handle this unexpected cfg
   = help: the attribute macro `frb` may come from an old version of the `flutter_rust_bridge_macros` crate, try updating your dependency with `cargo update -p flutter_rust_bridge_macros`
   = note: see <https://doc.rust-lang.org/nightly/rustc/check-cfg/cargo-specifics.html> for more information about checking conditional configuration
   = note: this warning originates in the attribute macro `frb` (in Nightly builds, run with -Z macro-backtrace for more info)

warning: unexpected `cfg` condition name: `frb_expand`
  --> src/api/api.rs:33:1
   |
33 | #[frb]
   | ^^^^^^
   |
   = note: using a cfg inside a attribute macro will use the cfgs from the destination crate and not the ones from the defining crate
   = help: try referring to `frb` crate for guidance on how handle this unexpected cfg
   = help: the attribute macro `frb` may come from an old version of the `flutter_rust_bridge_macros` crate, try updating your dependency with `cargo update -p flutter_rust_bridge_macros`
   = note: see <https://doc.rust-lang.org/nightly/rustc/check-cfg/cargo-specifics.html> for more information about checking conditional configuration
   = note: this warning originates in the attribute macro `frb` (in Nightly builds, run with -Z macro-backtrace for more info)

warning: unused import: `crate::logger`
 --> src/api/api.rs:5:5
  |
5 | use crate::logger;
  |     ^^^^^^^^^^^^^
  |
  = note: `#[warn(unused_imports)]` (part of `#[warn(unused)]`) on by default

warning: unused import: `log::info`
 --> src/api/api.rs:7:5
  |
7 | use log::info;
  |     ^^^^^^^^^

warning: unused import: `crate::frb_generated::*`
 --> src/pair.rs:1:5
  |
1 | use crate::frb_generated::*;
  |     ^^^^^^^^^^^^^^^^^^^^^^^

warning: unused import: `once_cell::sync::Lazy`
  --> src/pair.rs:13:5
   |
13 | use once_cell::sync::Lazy;
   |     ^^^^^^^^^^^^^^^^^^^^^

error[E0599]: no method named `with_min_level` found for struct `Config` in the current scope
 --> src/logger.rs:9:14
  |
7 | /         Config::default()
8 | |             .with_tag("STELLAR_RUST")
9 | |             .with_min_level(LevelFilter::Trace)
  | |_____________-^^^^^^^^^^^^^^
  |
help: there is a method `with_max_level` with a similar name
  |
9 -             .with_min_level(LevelFilter::Trace)
9 +             .with_max_level(LevelFilter::Trace)
  |

error[E0433]: failed to resolve: use of unresolved module or unlinked crate `logger`
  --> src/logger.rs:20:9
   |
20 |         logger::init_logger();
   |         ^^^^^^ use of unresolved module or unlinked crate `logger`
   |
help: to make use of source file src/logger.rs, use `mod logger` in this file to declare the module
  --> src/lib.rs:1:1
   |
 1 + mod logger;
   |

Some errors have detailed explanations: E0425, E0433, E0599.
For more information about an error, try `rustc --explain E0425`.
warning: `rust_lib_stellar` (lib) generated 7 warnings
error: could not compile `rust_lib_stellar` (lib) due to 3 previous errors; 7 warnings emitted
