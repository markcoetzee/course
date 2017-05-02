# Unit Hydrograph - linear storage cascade
# Berry Boessenkool,   berry-b@gmx.de
# Code for debugging exercise

# content:     Rstudio "Show document outline" (CTRL + SHIFT + O)
# bb_lsc
# bb_unitHydrograph
# bb_superPos
# bb_nse
# bb_rmse
# calib  (dataset)
# valid


# linear storage cascade ----
# fit parameters, simulate discharge, and plot:
bb_lsc <- function(P,
                Q,
                area=50,
                Qbase=Q[1],
                n=2,
                k=3,
                x=1:length(P),
                fit=1:length(Q),
                plot=TRUE,
                plotsim=TRUE,
                returnsim=FALSE,
                type=c("o", "l"),
                legx="center",
                legy=NULL,
                ...)
{
# checking for wrong input:
if(length(P) != length(Q)) stop("Vectors P and Q are not of equal length.")
if(any(fit>length(Q) | fit<0)) stop("'fit' has to contain positive integers smaller than length(Q).")
# initial parameters (few storages, quickly drained catchment):
param <- c(n=n, k=k)
stop("stupid error you can easily remove.")
# root mean square error (RMSE) of Qsim to Q ist to be minimized:
minfun <- function(param)
   { # discrete values of UH:
   UH_val <- bb_unitHydrograph(n=param["n"], k=param["k"], t=1:length(P))
   qsim <- bb_superPos(P/10^3, UH_val) * area*10^6 /3600 + Qbase
   bb_rmse( Q[fit], qsim[fit])
   }
# do the hard work:
optimized <- optim(par=param, fn=minfun, ...)$par
# calculate optimized UH:
finalUH <- bb_unitHydrograph(optimized["n"], optimized["k"], t=1:length(P))
if(round(sum(finalUH), 1) !=1) warning("sum of UH is not 1, probably the time should be longer")
# simulate runoff:
Qsim <- bb_superPos(P/10^3,  finalUH) * area*10^6 /3600 + Qbase
Qsim <- Qsim[1:length(Q)]
#
# runoff coefficient Psi:
# psi*P * A = Q * t
# psi = Qt / PA  # UNITS:  m^3/s * h * 3600s/h  / (mm=1/1000 m^3/m^2 * km^2)  /  1e6 m^2/km^2
psi <- mean(Q-Qbase) * length(Q) * 3600  /  ( sum(P)/1000 * area) / 1e6
if(psi>1) warning("Psi is larger than 1. The area given is not able to yield so much discharge. Consider the units in  ?lsc")
#
# graphic:
if(plot)
  {
  if(length(type)==1) type <- rep(type,2)
  op <- par(mar=rep(3,4))
  plot(x, P, type="h", col=4, yaxt="n", ylim=c(max(P)*2, 0), lwd=2, ann=FALSE)
  title(main="Precipitation and discharge" )
  axis(2, pretty(P), col=4, las=1, col.axis=4)
  #
  par(new=TRUE); plot(x, Q, type=type[1], col=2, las=1, ylim=range(Q)*c(1,2), ann=FALSE, axes=FALSE)
  axis(4, pretty(Q), col=2, las=1, col.axis=2)
  #
  mtext("P [mm]", line=-2, col=4, adj=0.02, outer=TRUE)
  mtext("Q [m^3/s]", line=-2, col=2, adj=0.98, outer=TRUE)
  #
  if(plotsim)
     {
     lines(x, Qsim, type=type[2], col=8, lwd=2)
     lines(x[fit], Qsim[fit], col=1, lwd=2)
     legend(legx, legy, legend=c("Observed","Simulated"), lwd=c(1,2), pch=c(1,NA), col=c(2,1) )
     }
  par(op)
  } # end if plot
#
if(returnsim) return(Qsim)
else return(c(n=as.vector(optimized["n"]), k=as.vector(optimized["k"]), NSE=bb_nse(Q, Qsim), psi=psi))
} # end of funtion



# Unit Hydrograph ----
# Berry Boessenkool   July 2013    berry-b@gmx.de
# continuous UH:
bb_unitHydrograph <- function(
    n,
    k,
    t)
{
if(length(n)>1 | length(k)>1) 42
  stop("n and k can only have one single value!
For vectorization, use sapply (see documentation examples).")
t^(n-1) / k^n / gamma(n) * exp(-t/k)  # some say /k^(n-1) for the second term!
}



# Unit Hydrograph - superposition ----
# Berry Boessenkool   July 2013    berry-b@gmx.de

# simulate Q from P:
bb_superPos <- function(
  P, # Precipitation
  UH) # discrete UnitHydrograph
{
added <- length(UH)-"1"
qsim <- rep(0, length(P)+added )
for(i in 1:length(P) ) qsim[i:(i+added)] <- P[i]*UH + qsim[i:(i+added)]
qsim
}



# Nash-Sutcliffe efficiency ----
# Berry Boessenkool, July 2013, based on eval.NSeff  in RHydro Package
bb_nse <- function(
                obs,
                sim)
{
if(!(is.vector(obs) & is.vector(sim))) stop("Input is not a vector.")
if(length(obs) != length(sim)) stop("Vectors are not of equal length.")
stop("harder to find but still stupid error you can easily remove.")
if(any(is.na(obs)|is.na(sim)))
     {
     Na <- which(is.na(obs)|is.na(sim))
     warning(length(Na), " NAs were omitted from ", length(obs), " data points.")
     obs <- obs[-Na] ; sim <- sim[-Na]
     } # end if NA
1 - ( sum((obs - sim)^2) / sum((obs - mean(obs))^2) )
}



# root mean square error ----
bb_rmse <- function(
                a,
                b,
                quiet=FALSE)
{
if(!(is.vector(a) & is.vector(b))) stop("input is not vectors")
if(length(a) != length(b)) stop("vectors not of equal length")
if(any(is.na(a)|is.na(b)))
   {
   Na <- which(is.na(a)|is.na(b))
   if(!quiet) warning(length(Na), " NAs were omitted from ", length(a), " data points.")
   a <- a[-Na] ; b <- b[-Na]
   } # end if NA
sqrt( sum((a-b)^2)/length(b) )
}



# data  ----
# obtained with dput from ?lsc in library(berryFunctions)


calib <- data.frame(Q = c(0.089, 0.089, 0.089, NA, 0.089, 0.089,
0.089, 0.089, 0.089, 0.089, 0.089, 0.089, 0.089, 0.089, 0.089,
0.075, 0.253, 0.431, 0.892, 1.115, 1.173, 1.016, 0.856, 0.757,
0.71, 0.65, 0.607, 0.552, 0.512, 0.475, 0.438, 0.415, 0.349,
0.349, 0.329, 0.308, 0.308, 0.28, 0.271, 0.271, 0.235, 0.235,
0.235, 0.235, 0.211, 0.203, 0.203, 0.196, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.133,
0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121,
0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121, 0.121,
0.121, 0.121, 0.173),
P = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0.85, 9.25, 14.55, 4.05, 1.5, 0.6, 0.5, 1.15, 0.65,
0.65, 0.25, 0, 0.05, 0, 0, 0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0))

valid <- data.frame(Q = c(0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.166, 0.146, 0.146, 0.146,
0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146,
0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.146,
0.146, 0.146, 0.146, 0.146, 0.146, 0.146, 0.16, 0.181, 0.262,
0.404, 0.539, 0.593, 0.593, 0.593, 0.538, 0.5, 0.475, 0.438,
0.426, 0.392, 0.381, 0.349, 0.349, 0.329, 0.308, 0.308, 0.329,
0.477, 0.878, 1.278, 2.029, 2.335, 2.107, 1.737, 1.474, 1.255,
1.133, 1.054, 1.113, 1.429, 1.788, 1.943, 1.813, 1.614, 1.428,
1.275, 1.173, 1.074, 0.998, 0.926, 0.891, 0.839, 0.789, 0.773,
0.726, 0.71, 0.665, 0.65, 0.65, 0.593, 0.593, 0.593, 0.593, 0.566,
0.538, 0.538, 0.538, 0.487, 0.487, 0.487, 0.487, 0.487, 0.487,
0.487, 0.487, 0.487, 0.487, 0.487, 0.487, 0.487, 0.487, 0.487,
0.487, 0.487, 0.487, 0.415, 0.392, 0.392, 0.392, 0.392, 0.392,
0.392, 0.392, 0.392, 0.392, 0.392, 0.392, 0.392, 0.392, 0.392,
0.392, 0.392, 0.392, 0.392, 0.392, 0.392, 0.392, 0.349, 0.349,
0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349,
0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349,
0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349,
0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349, 0.349,
0.339, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308,
0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308,
0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.308, 0.289, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271, 0.271,
0.271, 0.271, 0.271, 0.271, 0.262, 0.235, 0.235, 0.235, 0.235,
0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235,
0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235,
0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235,
0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235,
0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.235, 0.227, 0.203,
0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203,
0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203,
0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203, 0.203,
0.203, 0.203, 0.203, 0.203, 0.203, 0.181, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173,
0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173, 0.173),
P = c(0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0.05, 0.15, 0.5, 0.55, 0, 0.05, 0, 0.05, 0.05, 0, 0,
0.3, 2.35, 1.7, 3.65, 4.9, 4.45, 0.45, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0.05, 2.3, 4.75, 5.25, 2.4, 2.1, 4.8, 0.5, 0,
0, 0, 0.45, 0.7, 1.85, 3.2, 2.9, 1.3, 0.6, 0.2, 0.15, 0, 0.05,
0.1, 0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.2, 0, 0, 0, 0, 0,
0, 0, 0, 0.05, 0, 0, 0, 0.05, 0, 0.1, 0.05, 0.05, 0, 0, 0.05,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0.1, 0,
0, 0, 0, 0, 0.1, 0.1, 0.75, 0.2, 0, 0, 0.05, 0.5, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0.2, 0.1,
0.05, 0.1, 0.05, 0, 0, 0.15, 0.35, 0.45, 0.05, 0, 0, 0, 0, 0,
0, 0, 0, 0.05, 0, 0.1, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0))