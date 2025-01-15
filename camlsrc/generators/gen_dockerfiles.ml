module Types = struct
  open Ppx_yojson_conv_lib.Yojson_conv

  type docker_image_location_spec = {
      label : string;
      base : string;
    } [@@deriving yojson, show] 

  type available_docker_image_matrix = {
      image_location : docker_image_location_spec list [@key "image-location"];
      ocaml_version : string list [@key "ocaml-version"];
      node_version : string list [@key "node-version"];
      arch : string list [@key "arch"];
      os : string list [@key "os"];
    } [@@deriving yojson, show] [@@yojson.allow_extra_fields]

  type config = {
      matrix : available_docker_image_matrix;
    }

end [@@warning "-32"]
open Types

let available_docker_image_matrix_of_info_file =
  Yojson.Safe.Util.member "matrix" &> available_docker_image_matrix_of_yojson


let () =
  let matrix =
    ArgOptions.(get_option_exn (InChannelOption "-info"))
    |> Yojson.Safe.from_channel
    |> available_docker_image_matrix_of_info_file in
  let output_ch, target = match ArgOptions.(get_option (OutChannelOption' "-output")) with
    | None -> stdout, None
    | Some (ch, `StandardChannel) -> ch, None
    | Some (ch, `FileChannel target) -> ch, Some target
  in
  let target = ArgOptions.(get_option (StringOption "-target")) |> Option.otherwise target in
  let out_ppf = Format.formatter_of_out_channel output_ch in
  let outf fmt = fprintf out_ppf fmt in
  let config = { matrix } in
  let image_specs =
    let go { matrix; _ } =
      let open List.Ops_monad in
      matrix.image_location >>= fun { label; base } ->
      matrix.ocaml_version >>= fun ocaml_version ->
      matrix.node_version >>= fun node_version ->
      matrix.arch >>= fun arch ->
      matrix.os >>= fun os ->
      let tag =
        sprintf "%s-ocaml.%s-node.%s-%s"
          os ocaml_version node_version arch in
      [ (* suffix *)
        label ^ "--" ^ tag,
        (* docker image spec *)
        base ^ ":" ^ tag ]
    in
    config |> go in
  let emit_dockerfile ppf image_spec =
    let res path =
      match ArgOptions.(get_option (StringOption "-resdir")) with
      | None -> path
      | Some dir -> Filename.concat dir path in
    let outf fmt = fprintf ppf fmt in
    outf "FROM %s@." image_spec;
    outf "COPY %s /main.sh@." (res "main.sh");
    outf {|ENTRYPOINT [ "/main.sh" ]@.|};
  in
  let dockerfile_image_specs = image_specs |&> (?< (?. Filename.concat "Dockerfile")) in
  match target, lazy (target >>? String.chop_suffix (Filename.dir_sep ^ "Dockerfile")) with
  | None, _ -> image_specs |!> !!(outf "%s : %s@.")
  | Some "dockerfiles-list.txt", _ ->
     let decor path =
       match ArgOptions.(get_option (StringOption "-outdir")) with
       | None -> path
       | Some dir -> Filename.concat dir path in
     dockerfile_image_specs |!> (fst &> decor &> outf "%s@\n");
     outf "@?"
  | Some "(all-dockerfiles)", _ -> (
    let dir = ArgOptions.(get_option_exn (StringOption "-outdir")) in
    (if not (Sys.is_directory dir)
     then
       (eprintf "outdir %s does not exist or is not a directory@." dir; exit 2));
    let file_counter = ref 0 in
    dockerfile_image_specs |!> (fun (filename, image_spec) ->
      let path = Filename.concat dir filename in
      (let dir = Filename.dirname path in
       if not Sys.(file_exists dir && is_directory dir)
       then Sys.mkdir dir 0o755);
      let ppf = open_out path |> Format.formatter_of_out_channel in
      emit_dockerfile ppf image_spec;
      incr file_counter);
    Log0.verbose ~modul:__FILE__ "%d docker file(s) written to %s"
      !file_counter Filename.(
        if is_relative dir
        then concat (Sys.getcwd()) dir
        else dir);
  )
  | Some target, lazy (Some suffix) ->
     (match image_specs |> List.assoc_opt suffix with
      | Some image_spec -> emit_dockerfile out_ppf image_spec
      | _ -> eprintf "unknown target: %s@." target; exit 2
     )
  | Some target, _ ->
     eprintf "unknown target: %s@." target; exit 2
