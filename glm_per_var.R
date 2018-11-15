data = read.csv(data_file,stringsAsFactors=F)

attributes = c(paste("bio",seq(1:20),"50",sep="_"),"alt_50","npp_50","human_footprint_50", "P_median","diff_glaciers",
               "lat","sp_richness","woody_perc","herbaceous_p_perc","herbaceous_a_perc",
               "basal_m_perc","commelinids_perc","basal_angios_perc","basal_d_perc","rosids_perc","asterids_perc",paste("paleo",seq(1:19),"50",sep="_"),
               "LF_PC1","LF_PC2","LF_PC3","tax_PC1","tax_PC2","tax_PC3")

results = data.frame(matrix(nrow = length(attributes),ncol = 10))
names(results) = c("attribute","pv_lin","beta_lin","AIC_lin","var_lin",
                   "pv_quad","beta_quad","AIC_quad","var_quad","sample_size") 
for (i in 1:length(attributes)){  
  curr_att = attributes[i]
  ind = which(names(data)==curr_att)
  sub_data = data[which(!is.na(data[,ind]) & is.finite(data[,ind])),]
  print(nrow(sub_data))
  perc_pp = cbind(sub_data$pp,sub_data$dp)
  m1 = try(glm(as.formula(paste("perc_pp~",curr_att,sep="")),family=binomial, data = sub_data))
  m2 = try(glm(as.formula(paste("perc_pp~",curr_att,"+ I(",curr_att,"^2)",sep="")),family=binomial, data = sub_data))
  if (inherits(m1,"try-error")){
    print(paste(curr_att,"failed in linear"))
    next
  }
  if (inherits(m2,"try-error")){
    print(paste(curr_att,"failed in quadratic"))
    next
  }
  
  results$attribute[i] = curr_att
  results$pv_lin[i] = summary(m1)$coefficients[nrow(summary(m1)$coefficients),4]
  results$beta_lin[i] = summary(m1)$coefficients[nrow(summary(m1)$coefficients),1]
  results$AIC_lin[i] = m1$aic
  results$var_lin[i] = 100*(m1$null.deviance-m1$deviance)/m1$null.deviance # pseudo R^2
  
  results$pv_quad[i] = summary(m2)$coefficients[nrow(summary(m2)$coefficients),4]
  results$beta_quad[i] = summary(m2)$coefficients[nrow(summary(m2)$coefficients),1]
  results$AIC_quad[i] = m2$aic
  results$var_quad[i] = 100*(m2$null.deviance-m2$deviance)/m2$null.deviance # pseudo R^2
  results$sample_size[i] = nrow(sub_data)
}

write.csv(results,output_file,row.names=F)
