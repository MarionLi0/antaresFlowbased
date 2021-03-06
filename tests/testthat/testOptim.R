context("Function askProblemeMat")


PTDF <- system.file("testdata/optim/PTDF.csv",package = "antaresFlowbased")
PTDF <- fread(PTDF)

face <- system.file("testdata/optim/B.csv",package = "antaresFlowbased")
face <- fread(face)

resultsAMPL <- system.file("testdata/optim/AMPLobjective.csv",package = "antaresFlowbased")
resultsAMPL <- fread(resultsAMPL)

res <- apply(resultsAMPL, 1, function(Z){
  Z <- data.frame(t(Z))
  PTDFsel <- PTDF[Id_day == Z$day & Period == Z$hour]
  pointX <- getVertices(as.matrix(PTDFsel[,.SD, .SDcols = c("BE","DE","FR","NL")]), PTDFsel$RAM_0)
  pointX <- data.table(pointX)

  res <- giveTuples(face, pointX)
  faceY <- do.call("cbind", apply(res, 2, function(X){
    face[X,]
  }))
  probleme <- askProblemeMat(pointX, faceY, face)
  alpha <- Z$alpha
  tt <- resolvBmat(face, pointX, faceY, probleme, alpha)
  round(tt$objval, 1) == round(Z$objective, 1)
})

expect_true(all(res))
