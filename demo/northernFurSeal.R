data(northernFurSeal)

argosClasses <- c("3", "2", "1", "0", "A", "B")
ArgosMultFactors <- data.frame(Argos_loc_class=argosClasses,
                               errX=log(c(1, 1.5, 4, 14, 5.21, 20.78)),
                               errY=log(c(1, 1.5, 4, 14, 11.08, 31.03)))
nfsNew <- merge(northernFurSeal, ArgosMultFactors,
                by=c("Argos_loc_class"), all.x=TRUE)
nfsNew <- nfsNew[order(nfsNew$Time), ]

# State starting values
initial.drift <- list(a1.x=c(189.686, 0, 0), a1.y=c(57.145, 0, 0),
                      P1.x=diag(c(0, 0.001, 0.001)),
                      P1.y=diag(c(0, 0.001, 0.001)))

##Fit random drift model
# Check out the parameters 
displayPar(mov.model=~1, err.model=list(x=~errX, y=~errY), drift.model=TRUE,
           data=nfsNew, fixPar=c(NA, 1, NA, 1, NA, NA, NA, NA))

fit <- crwMLE(mov.model=~1, err.model=list(x=~errX, y=~errY), drift.model=TRUE,
              data=nfsNew, coord=c("longitude", "latitude"), polar.coord=TRUE,
              Time.name="Time", initial.state=initial.drift, 
              fixPar=c(NA, 1, NA, 1, NA, NA, NA, NA), 
              control=list(maxit=2000,trace=1, REPORT=10),
              initialSANN=list(maxit=300, trace=1, REPORT=1)
)

##Make hourly location predictions
predTime <- seq(ceiling(min(nfsNew$Time)), floor(max(nfsNew$Time)), 1)
predObj <- crwPredict(object.crwFit=fit, predTime, speedEst=TRUE, flat=TRUE)
head(predObj)
crwPredictPlot(predObj)

##Create simulation object with 100 parameter draws
set.seed(123)
simObj <- crwSimulator(fit, predTime, parIS=100, df=20, scale=18/20)

## Examine IS weight distribution
w <- simObj$thetaSampList[[1]][,1]
dev.new()
hist(w*100, main='Importance Sampling Weights', sub='More weights near 1 is desirable')

##Approximate number of independent samples
round(100/(1+(sd(w)/mean(w))^2))

dev.new(bg=gray(0.75))
jet.colors <-
  colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan",
                     "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))
crwPredictPlot(predObj, 'map')

## Sample 20 tracks from posterior predictive distribution
iter <- 20
cols <- jet.colors(iter)
for(i in 1:iter){
  samp <- crwPostIS(simObj)
  lines(samp$alpha.sim.x[,'mu'], samp$alpha.sim.y[,'mu'],col=cols[i])
}
