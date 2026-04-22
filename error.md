error[E0425]: cannot find value `existing_meta` in this scope
   --> src/wish/core_parser.rs:329:43
    |
329 |             uid: extracted_uid.clone().or(existing_meta.0.clone()),
    |                                           ^^^^^^^^^^^^^ not found in this scope

error[E0425]: cannot find value `existing_meta` in this scope
   --> src/wish/core_parser.rs:330:45
    |
330 |             lang: extracted_lang.clone().or(existing_meta.1.clone()),
    |                                             ^^^^^^^^^^^^^ not found in this scope

error[E0061]: this function takes 4 arguments but 3 arguments were supplied
  --> src/api/api.rs:26:5
   |
26 |     crate::wish_parser::import_local_json(json_content, storage_dir, game)
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------------------- argument #4 of type `std::option::Option<std::string::String>` is missing
   |
note: function defined here
  --> src/wish_parser.rs:71:8
   |
71 | pub fn import_local_json(json_content: String, storage_dir: String, game: String, uid: Option<String>) -> Result<usize> {
   |        ^^^^^^^^^^^^^^^^^                                                          -------------------
help: provide the argument
   |
26 |     crate::wish_parser::import_local_json(json_content, storage_dir, game, /* std::option::Option<std::string::String> */)
   |                                                                          ++++++++++++++++++++++++++++++++++++++++++++++++


error[E0382]: use of moved value: `manual_uid`
  --> src/wish/core_parser.rs:46:14
   |
16 | pub fn import_local_json(json_content: String, storage_dir: String, meta: Box<dyn GachaMetadata>, manual_uid: Option<String>) -> Result<usize> {
   |                                                                                                   ---------- move occurs because `manual_uid` has type `std::option::Option<std::string::String>`, which does not implement the `Copy` trait
...
21 |     let import_result = json_parser::parse_universal_json(&json_content, game_id, manual_uid)?;
   |                                                                                   ---------- value moved here
...
46 |         uid: manual_uid.or(import_result.uid).or(store_meta.0),
   |              ^^^^^^^^^^ value used here after move
   |
note: consider changing this parameter type in function `parse_universal_json` to borrow instead if owning the value isn't necessary
  --> src/wish/json_parser.rs:48:68
   |
48 | pub fn parse_universal_json(content: &str, game: &str, manual_uid: Option<String>) -> Result<UniversalImportResult> {
   |        -------------------- in this function                       ^^^^^^^^^^^^^^ this parameter takes ownership of the value
help: consider cloning the value if the performance cost is acceptable
   |
21 |     let import_result = json_parser::parse_universal_json(&json_content, game_id, manual_uid.clone())?;
   |                                                                                             ++++++++
