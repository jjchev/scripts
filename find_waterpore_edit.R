library(ncdf4) # package for netcdf manipulation
library(ggplot2)

##########################  BLOQUE 1 #############################################
get_z_top_bot <- function(ref_z_1, ref_z_2){
  if (mean(ref_z_1 > ref_z_2)) {
    z_top <- ref_z_1
    z_bot <- ref_z_2
  } else {
    z_top <- ref_z_2
    z_bot <- ref_z_1
  }
  return(list('z_top' = z_top,'z_bot' = z_bot))
}

get_pore_center <- function(x_1, x_2, y_1, y_2) {
  x_center <- (x_1 + x_2)/2
  y_center <- (y_1 + y_2)/2
  return(list('x_cent' = x_center, 'y_cent' = y_center))
}

get_pore_center_nc <- function(ncin,atom_1,atom_2){
  
  atom_1_xy <- as.data.frame(t(ncvar_get(
    ncin,
    'coordinates',
    start = c(1, atom_1, 1),
    count = c(2, 1,-1)
  )))
  
  atom_2_xy <- as.data.frame(t(ncvar_get(
    ncin,
    'coordinates',
    start = c(1, atom_2, 1),
    count = c(2, 1,-1)
  )))
  pore_center <- get_pore_center(atom_1_xy[,1], atom_2_xy[,1], atom_1_xy[,2], atom_2_xy[,2])
  return(pore_center)
}

find_waterpore_cilinder <- function(nc_dataset, ref_z_atom, ref_xy_atom, ref_xyz_atom, pedazos = 20, radius = 6.0) {
  ncin <- nc_dataset
  atoms_length <- ncin[["var"]][["coordinates"]][["size"]][2]
  time_length <- ncin[["var"]][["coordinates"]][["size"]][3]
  
  wat_df <- data.frame(matrix(ncol = 0, nrow = 0))
  print("buscando_agua_dentro_del_poro")
  
  for (pedazo in (0:(pedazos - 1))) {
    print(paste("procesando_pedacito", pedazo + 1, "de", pedazos))
    
    xyz <- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, 1, 1 + pedazo * (time_length / pedazos)),
      count = c(3, -1, time_length / pedazos)
    )
    
    z_ref <- ncvar_get(
      ncin,
      'coordinates',
      start = c(3, ref_z_atom, 1 + pedazo * (time_length/pedazos)),
      count = c(1, 1, time_length/pedazos)
    )
    
    xyz_ref <- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, ref_xyz_atom, 1 + pedazo * (time_length/pedazos)),
      count = c(3, 1, time_length/pedazos)
    )
    
    xy_ref <- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, ref_xy_atom, 1 + pedazo * (time_length/pedazos)),
      count = c(2, 1, time_length/pedazos)
    )
    
    sorted_z <- get_z_top_bot(z_ref,xyz_ref[3,])
    z_top <- as.vector(sorted_z$z_top)
    z_bot <- as.vector(sorted_z$z_bot)
    z_max <- max(z_top)
    z_min <- min(z_bot)

    pore_center_coords <- get_pore_center(xyz_ref[1,], xy_ref[1,], xyz_ref[2,], xy_ref[2,])
    x_cent <- pore_center_coords$x_cent
    y_cent <- pore_center_coords$y_cent
    
    wat_df <- rbind(wat_df,
                    as.matrix(unique(
                      which(
                        t(radius^2>((t(xyz[1, , ]) - x_cent)^2 + (t(xyz[2, ,]) - y_cent)^2) & 
                                               (t(xyz[3, , ]) > z_bot) & 
                                               (t(xyz[3, , ]) < z_top)),arr.ind = TRUE)[,1])))
  }
  rm(xyz)
  gc()
  return(sort(unique(subset(wat_df, V1 != ref_z_atom & V1 != ref_xy_atom & V1 != ref_xyz_atom)[,1])))
}

find_waterpore_bounds <- function(nc_dataset, ref_z_atom, ref_xy_atom_1, ref_xy_atom_2, low, top, pedazos = 20, radius = 6.0) {
  ncin <- nc_dataset
  atoms_length <- ncin[["var"]][["coordinates"]][["size"]][2]
  time_length <- ncin[["var"]][["coordinates"]][["size"]][3]
  
  wat_df <- data.frame(matrix(ncol = 0, nrow = 0))
  print("buscando_agua_dentro_del_poro")
  
  for (pedazo in (0:(pedazos - 1))) {
    print(paste("procesando_pedacito", pedazo + 1, "de", pedazos))
    
    xyz <- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, 1, 1 + pedazo * (time_length / pedazos)),
      count = c(3, -1, time_length / pedazos)
    )
    
    z_ref <- as.vector(ncvar_get(
      ncin,
      'coordinates',
      start = c(3, ref_z_atom, 1 + pedazo * (time_length/pedazos)),
      count = c(1, 1, time_length/pedazos)
    ))
    
    xy_ref_1 <- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, ref_xy_atom_1, 1 + pedazo * (time_length/pedazos)),
      count = c(3, 1, time_length/pedazos)
    )
    
    xy_ref_2<- ncvar_get(
      ncin,
      'coordinates',
      start = c(1, ref_xy_atom_2, 1 + pedazo * (time_length/pedazos)),
      count = c(2, 1, time_length/pedazos)
    )
    
    pore_center_coords <- get_pore_center(xy_ref_1[1,], xy_ref_2[1,], xy_ref_1[2,], xy_ref_2[2,])
    x_cent <- pore_center_coords$x_cent
    y_cent <- pore_center_coords$y_cent
    
    wat_df <- rbind(wat_df,
                    as.matrix(unique(
                      which(
                        t(radius^2>((t(xyz[1, , ]) - x_cent)^2 + (t(xyz[2, ,]) - y_cent)^2) & 
                            (t(xyz[3, , ]) > z_ref+low) & 
                            (t(xyz[3, , ]) < z_ref+top)),arr.ind = TRUE)[,1])))
  }
  rm(xyz)
  gc()
  return(sort(unique(subset(wat_df, V1 != ref_z_atom & V1 != ref_xy_atom_1 & V1 != ref_xy_atom_2)[,1])))
}

extract.cords.bis <- function(ncin, atom_list) {
  t_length <- ncin$var$time$varsize
  df <- df <- data.frame(matrix(ncol = 5, nrow = 0))
  i <- 1
  for (atom in atom_list) {
    
    if (i%%100==0) {
      print(paste(i,'de',length(atom_list)))
    }
    
    atom_xyz <-
      t(ncvar_get(
        ncin,
        "coordinates",
        start = c(1, atom, 1),
        count = c(3, 1, -1)
      ))
    atom_coords <-
      cbind(c(1:t_length), c(rep(atom, t_length)), atom_xyz)
    df <- rbind(df, atom_coords)
    i <- i+1
  }
  colnames(df) <- c("time", "atom", "x", "y", "z")
  return(df)
}

extract_coords <- function(ncin, atom_list, pedazos = 20) {
  time_length <- ncin[["var"]][["coordinates"]][["size"]][3]
  atoms_length <- ncin[["var"]][["coordinates"]][["size"]][2]
  pedazo_length <- time_length / pedazos
  print("extrayendo_atomos_de_la_trayectoria")
  df <- data.frame(matrix(ncol = 5, nrow = 0))
  
  for (pedazo in (0:(pedazos - 1))) {
    print(paste("procesando_pedacito", pedazo + 1, "de", pedazos))
    atom_xyz <-
      t(ncvar_get(
        ncin,
        "coordinates",
        start = c(1, 1, (1 + pedazo * pedazo_length)),
        count = c(3, atoms_length, pedazo_length)
      ))

    for (atom in atom_list) {
      atom_coord <-
        cbind(c((1 + pedazo * pedazo_length):((1 + pedazo) * pedazo_length)),
              c(rep(atom, pedazo_length)),
              t(atom_xyz[, as.integer(atom), ])
              )
      df <- 
        rbind(df, atom_coord)
    }
  }
  colnames(df) <- c("time", "atom", "x", "y", "z")
  return(df)
}

process_atoms_dz <- function(ncin,atom_matrix,ref_z_atom,ref_xy_atom,ref_xyz_atom) {
  df <- as.data.frame(atom_matrix)
  dfdz <- data.frame(matrix(ncol = 3, nrow = 0))
  
  z_ref <- ncvar_get(
    ncin,
    'coordinates',
    start = c(3, ref_z_atom, 1),
    count = c(1, 1, -1)
  )
  
  xyz_ref <- ncvar_get(
    ncin,
    'coordinates',
    start = c(1, ref_xyz_atom, 1),
    count = c(3, 1, -1)
  )
  
  sorted_z <- get_z_top_bot(z_ref,xyz_ref[3,])
  z_top_vect <- as.vector(sorted_z$z_top)
  z_bot_vect <- as.vector(sorted_z$z_bot)
  contador <- 0
  
  for(k in unique(df[, 2])){
    contador <- contador + 1
    print(paste("procesando_atomo", k, contador, "de", length(unique(df[, 2]))))
    nuevo <- df[which(df$atom == k), ]
    time_length <- length(t(nuevo[,1]))
    diferencias_z <-
      df[which(df$atom == k), ][2:time_length, 5] -
      df[which(df$atom == k), ][1:(time_length-1), 5]
    
    diferencias_z[time_length] <- 0
    diferencias_z <- as.data.frame(diferencias_z)
    
    for (j in 2:time_length){

      z_top <- z_top_vect[j]
      z_top_p <- z_top_vect[j-1]
      z_bot <- z_bot_vect[j]
      z_bot_p <- z_bot_vect[j-1]

      x_2 <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(1, ref_xyz_atom, j),
                  count = c(1, 1, 1))
      y_2 <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(2, ref_xyz_atom, j),
                  count = c(1, 1, 1))

      x_3 <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(1, ref_xy_atom, j),
                  count = c(1, 1, 1))
      y_3 <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(2, ref_xy_atom, j),
                  count = c(1, 1, 1))
      x_cent <- (x_2 + x_3) / 2
      y_cent <- (y_2 + y_3) / 2
      x_atom <- nuevo[j, 3]
      y_atom <- nuevo[j, 4]
      z_atom <- nuevo[j, 5]

      x_2_p <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(1, ref_xyz_atom, j - 1),
                  count = c(1, 1, 1))
      y_2_p <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(2, ref_xyz_atom, j - 1),
                  count = c(1, 1, 1))
      x_3_p <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(1, ref_xy_atom, j - 1),
                  count = c(1, 1, 1))
      y_3_p <-
        ncvar_get(ncin,
                  "coordinates",
                  start = c(2, ref_xy_atom, j - 1),
                  count = c(1, 1, 1))
      
      x_cent_p <- (x_2_p + x_3_p) / 2
      y_cent_p <- (y_2_p + y_3_p) / 2
      
      x_atom_p <- nuevo[j - 1, 3]
      y_atom_p <- nuevo[j - 1, 4]
      z_atom_p <- nuevo[j - 1, 5]
      if ((((x_atom - x_cent) ^ 2 + (y_atom - y_cent) ^ 2 >= 36) ||
           (z_bot >= z_atom) ||
           (z_atom >= z_top)) &&
          (((x_atom_p - x_cent_p) ^ 2 + (y_atom_p - y_cent_p) ^ 2 >= 36) ||
           (z_bot_p >= z_atom_p) || (z_atom_p >= z_top_p)))
      {
        diferencias_z[j-1, 1] <- 0
      }
    }
    data <-
      cbind(c(1:time_length), c(rep(k, time_length)), diferencias_z[, 1])
    dfdz <- rbind(dfdz, data)
  }
  colnames(dfdz) <- c("time", "atom", "dz")
  return(dfdz)
}

process_pore_dn <- function(dz_matrix,ref_z_atom,ref_xyz_atom) {
  atom_num <- length(t(unique(dfdz['atom'])))
  time_length <- length(t(dfdz[1]))/atom_num
  dn <- data.frame(matrix(ncol = 2, nrow = 0))
  dif <- data.frame(matrix(ncol = 1, nrow = 0))
  for (iii in 1:time_length) {
    dif <- rbind(dif,sum(dz_matrix[which(dz_matrix$time == iii), 3]))
  }
  dn <- rbind(dn,cbind(c(1:time_length),dif))
  colnames(dn) <- c("time", "dn")
  
  longitud_tubo <- abs(mean(
    ncvar_get(
      ncin,
      "coordinates",
      start = c(3, ref_z_atom, 1),
      count = c(1, 1, time_length))-
      ncvar_get(
      ncin,
      "coordinates",
      start = c(3, ref_xyz_atom, 1),
      count = c(1, 1, time_length)
    )
  ))
  integral <- cbind(c(1:(time_length)),cumsum(dn[,2]/longitud_tubo))
  n <- data.frame(matrix(ncol = 2, nrow = 0))
  n <- rbind(n,integral)
  colnames(n) <- c("time", "n")
  return(n)
}

msd_process <- function(n_matrix, n_frag_len, drop_first = 10, frame_step = 1){
  row_n <- nrow(n_matrix)
  n_frag <- split(
    n_matrix,
    rep(1:ceiling(row_n / n_frag_len), each = n_frag_len, length.out = row_n)
    )
  a <- 0
  for (i in 1:length(n_frag)) {
    n_frag[[i]][, 2] <-
      (n_frag[[i]][, 2] - n_frag[[i]][1, 2]) ^ 2
    n_frag[[i]][, 1] <-
      n_frag[[i]][, 1] - n_frag[[i]][1, 1]
    a <- n_frag[[i]][, 2] + a
  }
  msd_raw <- as.data.frame(cbind(c(1:length(a)), a / (length(n_frag))))
  msd <- msd_raw[drop_first:n_frag_len,]
  colnames(msd) <- c("time", "MSD")
  msd$time <- msd$time * frame_step
  return(msd)
}

filter.coords <- function(coord_array, pore_xy_center, ref_xyz_1, radius, top, low){
  atom_length <- length(t(unique(coord_array['atom'])))
  colnames(ref_xyz_1) <- c('x','y','z')  
  colnames(pore_xy_center) <- c('x','y')
  coord_array$z <- coord_array$z-rep(t(ref_xyz_1['z']), atom_length)
  
  cond <- coord_array['z'] < top &
    coord_array['z'] > low & 
    (coord_array['x']-rep(t(pore_xy_center['x']), atom_length))^2 + (coord_array['y']-rep(t(pore_xy_center['y']),atom_length))^2 < radius^2
  
  filtered_coords <- coord_array[which(cond),]
  return(filtered_coords)
}

filter.coords.bounds.nc <- function(filename, ref_z_atom, ref_xy_atom_1, ref_xy_atom_2,low,top, pedazos = 20, radius = 6.0){
  ncin <- nc_open(filename)
  
  wat_atoms <- find_waterpore_bounds(ncin, ref_z_atom, ref_xy_atom_1, ref_xy_atom_2, pedazos, radius, low = low, top = top)

  wat_coord <- extract.cords.bis(ncin,wat_atoms)
  
  pore_xy_center <- as.data.frame(get_pore_center_nc(ncin, ref_xy_atom_1, ref_xy_atom_2))
  
  ref_xyz_1 <- as.data.frame(t(ncvar_get(
    ncin,
    'coordinates',
    start = c(1, ref_z_atom, 1),
    count = c(3, 1,-1)
  )))
  xyz_filtered <- filter.coords(wat_coord, pore_xy_center, ref_xyz_1, radius, top, low)
  return(xyz_filtered)
}

filter.coords.iterative <- function(xyz_atom,pore_xy_center,ref_xyz_1, xyz_cols,frame_col = FALSE){
  xyz <- as.data.frame.matrix(xyz_atom)
  colnames(ref_xyz_1) <- c('x','y','z')  
  colnames(pore_xy_center) <- c('x','y')
  if (frame_col) {
    frame <- as.data.frame.matrix(xyz_atom[frame_col])
    xyz <- cbind(frame,xyz)
    colnames(xyz) <- c('Frame','x','y','z')
  } else {
    colnames(xyz) <- c('x','y','z')    
  }
  xyz$z <- xyz$z - ref_xyz_1$z
  filtered_xyz <- xyz[which(xyz['z'] < 5 & xyz['z'] > -18 & (xyz['x']-pore_xy_center['x'])^2 + (xyz['y']-pore_xy_center['y'])^2 < 36),]
  return(filtered_xyz)
}

filter.coords.list <- function(atom_list, coord_array, pore_xy_center, ref_xyz_1, xyz_cols,frame_col = FALSE){
  xyz_filtered <-  data.frame(matrix(ncol = 3, nrow = 0))
  for (atom in atom_list) {
    xyz_atom <- coord_array[coord_array['atom']==5,][xyz_cols]
    xyz_filtered <- rbind(xyz_filtered,filter.coords(xyz_atom,pore_xy_center,ref_xyz_1,frame_col))
    print(atom)
  }
  return(xyz_filtered)
}

##########################  BLOQUE 2 #######################################


save_bounds <- function(nc_name, txt_name){

ncin <- nc_open(nc_name)
lista_bounds <- find_waterpore_bounds(nc_dataset = ncin, 1,2,3, low = -18, top = 5)
write.table(
lista_bounds,
txt_name,
col.names = FALSE, row.names = FALSE,
sep = " " 
)

} 


for (i in c("H2O_CA.nc","H2O_CC.nc","AOX_CA.nc","AOX_CC.nc")){

save_bounds(i, sub(".nc", ".txt", i))

}

#filename <- "./H2O_CA.nc"
#ncin <- nc_open(filename)
#lista_WAT_cilinder <- find_waterpore_cilinder(ncin,1,3,2)
#lista_WAT_bounds <- find_waterpore_bounds(nc_dataset = ncin,1,2,3,low = -18,top = 5)
#filtered_coords_bounds <- filter.coords.bounds.nc(filename,1,2,3,low = -18, top = 5)

#write.table(
#  lista_WAT_bounds,
#  'WAT_cil_bounds_A.txt',
#  col.names = FALSE,
#  row.names = FALSE,
#  sep = " "
#)
