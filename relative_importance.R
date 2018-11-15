require(relaimpo)
data = read.csv(data_file,stringsAsFactors=F)

atts_for_formula = function(atts,omit = NULL,coll = "Y"){
  # returns set of attributes ready to be placed in the formula as predictors
  atts = atts[which(!atts%in%omit)]
  if (coll=="N"){
    return (atts)
  }
  atts = paste(unlist(atts),collapse="+")
  return(atts)
}

relative_importance = function(formula,relimp.data,type = "lmg",groups = NULL,groupnames = NULL,w = NULL){
  # calculates the relative importance
  if (is.null(w)){ # non-weighted
    model = lm(formula, data = relimp.data)
  } else { # weighted
    model = lm(formula, data = relimp.data, weights = w)
  }
  relimp.res = calc.relimp(model, type =  type, rela = FALSE, groups=groups, groupnames=groupnames)
  return(relimp.res)
}

attributes = c(paste("bio",seq(1:20),"50",sep="_"),"npp_50", "P_median","alt_50",	"human_footprint_50","diff_glaciers",
               "sp_richness","woody_perc","herbaceous_p_perc","herbaceous_a_perc",
               "basal_m_perc","commelinids_perc","basal_angios_perc","basal_d_perc","rosids_perc","asterids_perc",paste("paleo",seq(1:19),"50",sep="_"))

# possible to omit variables
omit_vars = NA

w = data$dp+data$pp # weights, for future use
data = subset(data,select = c("pp_perc_resolved",attributes)) # reduce data to contain only relevant columns

# grouping of all variables
l = list(c(setdiff(paste("bio",seq(1:19),"50",sep="_"),omit_vars)),
         c("basal_m_perc","commelinids_perc","basal_angios_perc","basal_d_perc","rosids_perc","asterids_perc"),
         c("woody_perc","herbaceous_p_perc","herbaceous_a_perc"),
         c(setdiff(paste("paleo",seq(1:19),"50",sep="_"),omit_vars)))
groupnames = c("clim","tax","LF","paleo")


# weighted, grouped, all variables
formula = paste("pp_perc_resolved~",paste(unlist(l),collapse="+"),"+sp_richness+npp_50+P_median+human_footprint_50+alt_50+bio_20_50",sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, groups = l, groupnames=groupnames, w=w)


# BIOCLIM separated
formula = paste("pp_perc_resolved~",paste(unlist(l[1]),collapse="+"),sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, w=w)

# taxonomy separated
formula = paste("pp_perc_resolved~",paste(unlist(l[2]),collapse="+"),sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, w=w)


# lifeform separated
formula = paste("pp_perc_resolved~",paste(unlist(l[3]),collapse="+"),sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, w=w)

# change-in-climate separated 
formula = paste("pp_perc_resolved~",paste(unlist(l[4]),collapse="+"),sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, w=w)

# climate represented by 4 variables
l = list(c("bio_1_50","bio_4_50","bio_14_50","bio_15_50"),
         c("basal_m_perc","commelinids_perc","basal_angios_perc","basal_d_perc","rosids_perc","asterids_perc"),
         c("woody_perc","herbaceous_p_perc","herbaceous_a_perc"),
         c(setdiff(paste("paleo",seq(1:19),"50",sep="_"),omit_vars)))
formula = paste("pp_perc_resolved~",paste(unlist(l),collapse="+"),"+sp_richness+npp_50+P_median+human_footprint_50+alt_50+bio_20_50",sep="")
relimp.res = relative_importance(formula = formula, relimp.data = data, groups = l, groupnames=groupnames, w=w)

