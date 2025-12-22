## Christmas Tree
## Author: Nan He, Southern Medical University, 2025.12.22
rm(list = ls())
library(yulab.utils)
pload(ggplot2)
pload(gganimate)
pload(dplyr)
pload(tidyr)
pload(showtext)
pload(gifski)
pload(av)

## set up font
setup_fonts <- function() {
  font_add_google("Great Vibes", "xmas_font")
  showtext_auto()
}

get_theme_config <- function(style) {
  themes <- list(
    # Style 1: Classic Dark (Red/Green/Gold)
    "1" = list(bg="#0f0505", tree=c("#0B3D0B", "#144514", "#006400"), trunk="#3e2723", light=c("#FFD700", "#CCA43B", "#8B0000"), star="#FFD700", text="#FFD700", snow="white"),
    
    # Style 2: Silver/Blue (Light Theme)
    "2" = list(bg="#F0F2F5", tree=c("#2F4F4F", "#5F9EA0", "#708090"), trunk="#696969", light=c("#B0C4DE", "#FFFAF0", "#E0FFFF"), star="#B0C4DE", text="#708090", snow="#87CEFA"),
    
    # Style 3: Earthy/Olive (Natural)
    "3" = list(bg="#1a1a1a", tree=c("#556B2F", "#6B8E23", "#808000"), trunk="#5D4037", light=c("#CD853F", "#FFCC00", "#DAA520"), star="#FFCC00", text="#DEB887", snow="white"),
    
    # Style 4: RGB Neon (Dark High Contrast)
    "4" = list(bg="#101010", tree=c("#006400", "#228B22"), trunk="#4E342E", light=c("#FF0000", "#00FF00", "#0000FF", "#FFFF00"), star="#FFD700", text="#FF6347", snow="white"),
    
    # Style 5: Noir (Black & White)
    "5" = list(bg="#000000", tree=c("#111111", "#050505"), trunk="#222222", light=c("#FFFFFF", "#FFFFE0", "#CCCCCC"), star="#FFFFFF", text="#FFFFFF", snow="gray30"),
    
    # Style 6: Pink Romance (Your custom pink)
    "6" = list(bg="#1F0F12", tree=c("#D87093", "#FF69B4", "#FFB6C1"), trunk="#4A3728", light=c("#FFFFFF", "#FFD700", "#FF1493"), star="#FFD700", text="#FFC0CB", snow="#FFF0F5"),
    
    # Style 7: Golden Luxury (Gatsby Style)
    "golden" = list(bg="#000000", tree=c("#3b2f0e", "#5c4d28", "#8a7538"), trunk="#2e2716", light=c("#ffd700", "#ffec8b", "#daa520", "#ffffff"), star="#fffacd", text="#daa520", snow="#fff8dc"),
    
    # Style 8: Cyberpunk (Neon Purple/Green)
    "cyberpunk" = list(bg="#050010", tree=c("#120024", "#2a003b", "#1a0b2e"), trunk="#111111", light=c("#00ff00", "#ff00ff", "#00ffff", "#ffea00"), star="#00ffff", text="#ff00ff", snow="#39ff14"),
    
    # Style 9: Candy Cane (Red & White Mint)
    "candy" = list(bg="#ffffff", tree=c("#2e8b57", "#3cb371", "#8fbc8f"), trunk="#8b4513", light=c("#ff0000", "#ffffff", "#ff4040"), star="#ff0000", text="#ff0000", snow="#d3d3d3"),
    
    # Style 10: Sunset (Vaporwave Orange/Purple)
    "sunset" = list(bg="#2d112b", tree=c("#551a8b", "#8a2be2", "#9932cc"), trunk="#2e0828", light=c("#ff4500", "#ffa500", "#ffd700"), star="#ff8c00", text="#ff69b4", snow="#ffdab9"),
    
    # Style 11: Matrix (Hacker Green Code)
    "matrix" = list(bg="#000000", tree=c("#003300", "#004400", "#005500"), trunk="#002200", light=c("#00ff00", "#33ff33", "#ccffcc"), star="#00ff00", text="#00ff00", snow="#00cc00")
  )
  
  # Logic: Check if style exists, otherwise default to "1"
  if (is.null(themes[[as.character(style)]])) {
    message("Style '", style, "' not found. Using default Style 1.")
    return(themes[["1"]])
  }
  return(themes[[as.character(style)]])
}

generate_tree_points <- function(cfg) {
  # Spiral tree generation
  n_leaves <- 6000
  h <- runif(n_leaves, 0, 1)
  r <- (1 - h) * 0.8
  theta <- 2.39996 * (1:n_leaves) # Golden angle
  
  df_tree <- data.frame(
    x = r * cos(theta), 
    y = h - 0.5, 
    z = r * sin(theta), 
    color = sample(cfg$tree, n_leaves, replace = TRUE),
    size = runif(n_leaves, 0.5, 1.5),
    type = "leaf",
    alpha = 0.8
  )
  
  # Lights (Ornaments)
  n_lights <- 400
  h_l <- runif(n_lights, 0.1, 0.9)
  r_l <- (1 - h_l) * 0.85
  theta_l <- runif(n_lights, 0, 2 * pi)
  
  df_lights <- data.frame(
    x = r_l * cos(theta_l),
    y = h_l - 0.5,
    z = r_l * sin(theta_l),
    color = sample(cfg$light, n_lights, replace = TRUE),
    size = runif(n_lights, 3, 5),
    type = "light",
    alpha = 1
  )
  
  bind_rows(df_tree, df_lights)
}

create_xmas_tree <- function(style = "classic", filename = "tree.gif", n_frames = 60) {
  setup_fonts()
  cfg <- get_theme_config(style)
  
  # Data Generation
  static_points <- generate_tree_points(cfg)
  
  snow_flakes <- data.frame(
    x = runif(300, -1.2, 1.2),
    y = runif(300, -0.8, 1.2),
    z = runif(300, -1, 1),
    size = runif(300, 0.5, 2.5),
    speed = runif(300, 0.01, 0.03),
    color = cfg$snow,
    type = "snow",
    alpha = 0.7
  )
  
  message("Calculating 3D frames...")
  
  frames <- lapply(1:n_frames, function(i) {
    angle <- 2 * pi * (i / n_frames)
    
    # 3D Rotation
    rotated <- static_points %>%
      mutate(
        x_rot = x * cos(angle) - z * sin(angle),
        z_rot = z * cos(angle) + x * sin(angle),
        y_rot = y
      )
    
    # Snow Movement
    snow_frame <- snow_flakes %>%
      mutate(
        y_rot = -0.8 + (y - i * speed - (-0.8)) %% 2,
        x_rot = x, 
        z_rot = z
      )
    
    # Star Rotation
    star_angle <- seq(pi/2, 2.5 * pi, length.out = 11)[-11] + angle
    star_pts <- data.frame(
      x_rot = 0 + (0.08 * cos(star_angle)) * rep(c(1, 0.4), 5),
      y_rot = 0.55 + (0.08 * sin(star_angle)) * rep(c(1, 0.4), 5),
      z_rot = 0,
      color = cfg$star,
      size = 1,
      type = "star_poly",
      alpha = 1
    )
    
    bind_rows(rotated, snow_frame, star_pts) %>%
      mutate(
        depth = 1 / (2.5 - z_rot),
        x_proj = x_rot * depth * 2,
        y_proj = y_rot * depth * 2,
        size_vis = size * depth * 1.5,
        alpha_vis = alpha * ifelse(type == "snow", 1, pmax(0.2, (z_rot + 1) / 2)),
        frame = i
      ) %>%
      arrange(depth)
  }) %>% bind_rows()
  
  message("Rendering animation...")
  
  p <- ggplot() +
    # Background
    theme_void() +
    theme(
      plot.background = element_rect(fill = cfg$bg, color = NA),
      panel.background = element_rect(fill = cfg$bg, color = NA)
    ) +
    coord_fixed(xlim = c(-1, 1), ylim = c(-1, 1)) +
    
    # Layer 1: Tree Leaves & Snow
    geom_point(data = filter(frames, type %in% c("leaf", "snow")), 
               aes(x = x_proj, y = y_proj, color = I(color), size = I(size_vis), alpha = I(alpha_vis))) +
    
    # Layer 2: Light Glow (Back layer, larger & transparent)
    geom_point(data = filter(frames, type == "light"), 
               aes(x = x_proj, y = y_proj, color = I(color), size = I(size_vis * 2), alpha = I(0.3)), 
               shape = 16) +
    
    # Layer 3: Light Core (Front layer, smaller & bright)
    geom_point(data = filter(frames, type == "light"), 
               aes(x = x_proj, y = y_proj, color = I(color), size = I(size_vis * 0.8), alpha = I(1)), 
               shape = 19) +
    
    # Layer 4: Star
    geom_polygon(data = filter(frames, type == "star_poly"),
                 aes(x = x_proj, y = y_proj, group = frame),
                 fill = cfg$star, color = "white", size = 0.5) +
    
    # Text
    annotate("text", x = 0, y = -0.9, label = "Merry Christmas", 
             family = "xmas_font", color = cfg$text, size = 10) +
    
    transition_manual(frame)
  
  # Output
  renderer <- if (grepl("mp4$", filename)) av_renderer(filename) else gifski_renderer(filename, loop = TRUE)
  output <- animate(p, nframes = n_frames, fps = 24, width = 600, height = 800, res = 120, renderer = renderer)
  
  print(output)
  message("Saved to ", filename)
}


## usage
create_xmas_tree(style = "1", filename = "/Users/hinna/Desktop/tree_classic.gif")
