require(lavaan)
data = read.csv(data_file, stringsAsFactors=F)

# Main
m = "sp_richness~bio_1_50
herbaceous_p_perc~bio_1_50
tax_PC1~bio_1_50
pp_perc_resolved~bio_1_50
herbaceous_p_perc~tax_PC1
sp_richness~tax_PC1
pp_perc_resolved~sp_richness
pp_perc_resolved~herbaceous_p_perc
pp_perc_resolved~tax_PC1"
m.fit = sem(m,data=data,std.ov=T)
summary(m.fit,rsq=T, standardized=T, fit.measures=T)

# Climate represented by PC1
m = "sp_richness~clim_PC1
herbaceous_p_perc~clim_PC1
tax_PC1~clim_PC1
pp_perc_resolved~clim_PC1
herbaceous_p_perc~tax_PC1
sp_richness~tax_PC1
pp_perc_resolved~sp_richness
pp_perc_resolved~herbaceous_p_perc
pp_perc_resolved~tax_PC1"
m.fit = sem(m,data=data,std.ov=T)
summary(m.fit,rsq=T, standardized=T, fit.measures=T)

# Climate represented by PC1 and PC2
m = "sp_richness~clim_PC1
herbaceous_p_perc~clim_PC1
tax_PC1~clim_PC1
pp_perc_resolved~clim_PC1
herbaceous_p_perc~tax_PC1
sp_richness~tax_PC1
pp_perc_resolved~sp_richness
pp_perc_resolved~herbaceous_p_perc
pp_perc_resolved~tax_PC1
sp_richness~clim_PC2
herbaceous_p_perc~clim_PC2
tax_PC1~clim_PC2
pp_perc_resolved~clim_PC2"
m.fit = sem(m,data=data,std.ov=T)
summary(m.fit,rsq=T, standardized=T, fit.measures=T)

# Climate represented by BIO1 and BIO15
m = "sp_richness~bio_1_50
herbaceous_p_perc~bio_1_50
tax_PC1~bio_1_50
pp_perc_resolved~bio_1_50
herbaceous_p_perc~tax_PC1
sp_richness~tax_PC1
pp_perc_resolved~sp_richness
pp_perc_resolved~herbaceous_p_perc
pp_perc_resolved~tax_PC1
sp_richness~bio_15_50
herbaceous_p_perc~bio_15_50
tax_PC1~bio_15_50
pp_perc_resolved~bio_15_50
bio_1_50~~bio_15_50"
m.fit = sem(m,data=data,std.ov=T)
summary(m.fit,rsq=T, standardized=T, fit.measures=T)
