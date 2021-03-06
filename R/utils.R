
data_merge <- function(.data, atlas3d){

  # Find columns they have in common
  cols <- names(atlas3d)[names(atlas3d) %in% names(.data)]

  # Merge the brain with the data
  atlas3d <- dplyr::full_join(atlas3d, .data, by = cols, copy=TRUE)

  # Find if there are instances of those columns that
  # are not present in the atlas. Maybe mispelled?
  errs <- dplyr::filter(atlas3d, unlist(lapply(atlas3d$mesh, is.null)))
  errs <- dplyr::select(errs, !!cols)
  errs <- dplyr::distinct(errs)
  errs <- tidyr::unite_(errs, "tt", cols, sep = " - ")
  errs <- dplyr::summarise(errs, value = paste0(tt, collapse = ", "))

  if(errs != ""){
    warning(paste("Some data is not merged properly into the atlas. Check for spelling mistakes in:",
                  errs$value))

    atlas3d = dplyr::filter(atlas3d ,
                            !unlist(lapply(atlas3d$mesh, is.null)))
  }

  atlas3d
}



# from the package gplots
col2hex <- function (colour){
  col <- grDevices::col2rgb(colour)
  grDevices::rgb(red = col[1, ]/255,
                 green = col[2, ]/255,
                 blue = col[3, ]/255)
}


# get atlas depending on string or env object
get_atlas <- function(atlas, surface, hemisphere){
  atlas3d <- if(!is.character(atlas)){
    atlas
  }else{
    get(atlas)
  }

  if(!any(grepl("3d", atlas3d$atlas))){
    stop(paste0("This is not a 3d atlas, did you mean ", atlas3d$atlas[1], "_3d?"))
  }

  if(!any(atlas3d$surf %in% surface)){
    stop(paste0("There is no surface '",surface,"' in this atlas." ))
  }

  if(!any(atlas3d$hemi %in% hemisphere)){
    stop(paste0("There is no data for the ",hemisphere," hemisphere in this atlas." ))
  }


  atlas3d <- as_ggseg3d_atlas(atlas3d)

  # grab the correct surface and hemisphere
  k <-  dplyr::filter(atlas3d, surf %in% surface,
                  hemi %in% hemisphere)
  tidyr::unnest(k, cols = ggseg_3d)

}


get_palette <- function(palette){

  if(is.null(palette)){
    palette = c("skyblue", "dodgerblue")
  }

  if(!is.null(names(palette))){
     pal.colours <- names(palette)
     pal.values <- unname(palette)
     pal.norm <- range_norm(pal.values)
  }else{
    pal.colours <- palette
    pal.norm <- seq(0,1, length.out = length(pal.colours))
    pal.values <- seq(0,1, length.out = length(pal.colours))
  }

  # Might be a single colour
  pal.colours = if(length(palette) == 1){
    # If a single colour, dummy create a second
    # palette row for interpolation
    data.frame(values = c(pal.values,pal.values+1),
               norm = c(0, 1 ),
               orig = c(pal.colours,pal.colours),
               stringsAsFactors = F)
  }else{
    data.frame(values = pal.values,
               norm = pal.norm,
               orig = pal.colours,
               stringsAsFactors = F)
  }

  pal.colours$hex <- gradient_n_pal(
    colours = pal.colours$orig,
    values = pal.colours$values,
    space = "Lab")(pal.colours$values)

    pal.colours

}

range_norm <- function(x){ (x-min(x)) / (max(x)-min(x)) }



utils::globalVariables(c("region",
                         "atlas",
                         "colour",
                         "group",
                         "hemi",
                         ".lat",
                         ".long",
                         ".id",
                         "side",
                         "x"))
