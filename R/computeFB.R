#' Compute flowbased approximation
#'
#' @param PTDF \code{character}, path for PTDF file
#' @param outputName \code{character}, name of output directory
#' @param reports \code{boolean}, product html reports by typical day or not
#' @param dayType \code{character / numeric} default All, can specify dayType to compute
#' @param hour \code{character / numeric} default All, can specify hour to compute
#' @param nbFaces \code{numeric} number of faces to keep, default 36.
#' @param verbose \code{numeric} show log in console. Defaut to 0
#' @param allFB \code{data.table}, FB data.table directly load in R.
#' \itemize{
#'  \item 0 : No log
#'  \item 1 : Short log
#' }
#' @import ROI
#' @import ROI.plugin.clp
#'
#' @export
computeFB <- function(PTDF = system.file("/input/ptdf/PTDF.csv", package
                                         = "antaresFlowbased"),
                      outputName =  paste0(getwd(), "/antaresInput"),
                      reports = TRUE,
                      dayType = "All", hour = "All", nbFaces = 36,
                      verbose = 0)
{
  pb <- txtProgressBar(style = 3)
  univ <- .univ(nb = 500000, bInf = -10000, bSup = 10000)

  PTDF <- fread(PTDF)

  face <- giveBClassif(PTDF, nbClust = nbFaces)
  face <- round(face, 2)
  if(dayType[1] == "All"){
    dayType <- unique(PTDF$Id_day)
  }

  if(hour[1] == "All"){
    reports <- FALSE
    hour <- unique(PTDF$Period)
  }

  flowbased <- data.table(expand.grid(hour, dayType))
  names(flowbased) <- c("hour", "dayType")
  flowbased$outFlowBased <- rep(list(), nrow(flowbased))
  Nsim <- nrow(flowbased)
  RowUse <- 0
  sapply(hour, function(X){
    sapply(dayType, function(Y){
      if(verbose>0){
        cat(paste0("\n", "Optim for hour : ", X, " and typical day : ", Y, "\n"))
      }
      RowUse <<- RowUse + 1
      setTxtProgressBar(pb, RowUse/Nsim)
      PTDFsel <- PTDF[Id_day == Y & Period == X]

      pointX <- getVertices(as.matrix(PTDFsel[,.SD, .SDcols = c("BE","DE","FR","NL")]), PTDFsel$RAM_0)
      pointX <- data.table(pointX)

      res <- giveTuples(face, pointX)
      faceY <- do.call("cbind", apply(res, 2, function(X){
        face[X,]
      }))
      probleme <- askProblemeMat(pointX, faceY, face)
      out <- searchAlpha(face = face, pointX = pointX,
                         faceY = faceY,
                         probleme = probleme,
                         PTDF = PTDFsel,
                         univ = univ, verbose = verbose)
      out$pointX <- data.frame(pointX)
      names(out$pointX) <- c( "BE", "DE", "FR")
      out$param$hour <- X
      out$param$dayType <- Y
      out$param$alpha <- out$alpha
      out$alpha <- NULL
      flowbased[hour == X & dayType == Y]$outFlowBased[[1]] <<- list(out)
      NULL
    })
  })%>>%invisible

  ##From B to antares

 antaresFace <- .fromBtoAntares(face)
 
 ##Output
 allFaces <- rbindlist(apply(flowbased,1, function(X){
   data.table(Id_day = X$dayType, Id_hour = X$hour,
              X$outFlowBased$face,
              Name = paste0("FB", 1:nrow(X$outFlowBased$face)))
 }))
 setnames(allFaces, "B", "vect_b")

 dir.create(outputName)
 write.table(antaresFace, paste0(outputName, "/weight.txt"), row.names = FALSE, sep = "\t", dec = ".")
 saveRDS(flowbased, paste0(outputName, "/domainesFB.RDS"))
 write.table(allFaces, paste0(outputName, "/second_member.txt"), row.names = FALSE, sep = "\t", dec = ".")
 if(reports){
   outputNameReports <- paste0(outputName, "/reports")
   dir.create(outputNameReports)
   sapply(unique(flowbased$dayType), function(X){
     print(outputNameReports)
     generateRaportFb(allFB = flowbased, dayType = X, output_file = outputNameReports)
   })
  }

 outputName
}



#' Chronique file to optimisation output
#' 
#' @param outputName \code{character}, name of output directory
#' @export
addChroniquesFile <- function(outputName){
  Chroniques <- system.file("/input/ts.txt", package
                            = "antaresFlowbased")
  Chroniques <- fread(Chroniques)
  write.table(Chroniques,paste0(outputName, "/ts.txt"), row.names = FALSE, sep = "\t")
}
