# Run antares function
.runAntares <- function(cmd){
  system(cmd, show.output.on.console = FALSE, intern = TRUE)
}