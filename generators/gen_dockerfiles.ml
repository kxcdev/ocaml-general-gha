module Types = struct

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
      dockerfile_prefix : string;
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
  let dockerfile_prefix = ArgOptions.(get_option (StringOption "-dockerfile-prefix")) |? "Dockerfile-" in
  let config = { matrix; dockerfile_prefix } in
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
    let outf fmt = fprintf ppf fmt in
    outf "FROM %s@." image_spec;
    outf "COPY main.sh /main.sh@.";
    outf {|ENTRYPOINT [ "/main.sh" ]@.|};
  in
  let dockerfile_image_specs = image_specs |&> (?< ((^) config.dockerfile_prefix)) in
  match target, lazy (target >>? String.chop_prefix config.dockerfile_prefix) with
  | None, _ -> image_specs |!> !!(outf "%s : %s@.")
  | Some "dockerfiles-list.inc", _ ->
     dockerfile_image_specs |!> (fst &> outf "%s@\n");
     outf "@?"
  | Some "(all-dockerfiles)", _ -> (
    let dir = ArgOptions.(get_option_exn (StringOption "-outdir")) in
    (if not (Sys.is_directory dir)
     then
       (eprintf "outdir %s does not exist or is not a directory@." dir; exit 2));
    let file_counter = ref 0 in
    dockerfile_image_specs |!> (fun (filename, image_spec) ->
      let ppf =
        Filename.concat dir filename
        |> open_out |> Format.formatter_of_out_channel
      in
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
