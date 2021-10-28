create_plot <- function(data, ...) {
  ggplot(data,
         aes(year, population, ...)) +
    geom_point() +
    geom_line()
}
