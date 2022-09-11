---
title: "Identifying metabotypes from tensor data"
author: 
    - name: "Viktor Skantze"
      affiliations: 
        - name: "Chalmers University of technology"
date: "2022-09-12"
---

Metabolic response to diet shows large individual variation, which
warrants tailored dietary recommendation i.e., personalized nutrition
(PN). A step towards PN is to tailor diet to groups of individuals with
similar metabolic phenotype, so called metabotypes (i.e., clusters of
individuals with similar metabolism). Metabotyping of high-dimensional
data is commonly performed in matrix form using matrix decompositions
(e.g., PCA). However, data from e.g., crossover studies can be
conveniently organized in multi-dimensional form (i.e., as tensor data)
and methods for detecting metabotypes in such data are still lacking.

We therefore aimed to develop and evaluate tools to identify potential
metabotypes in high-dimensional tensor data.

We developed two methods: The first uses CANDECOMP/PARAFAC (CP)
decomposition directly on tensor data where clustering was performed on
individual’s scores, whereas the second was developed specifically for
time-resolved data and uses dynamic mode decomposition (DMD) to model
metabolite dynamics, where clustering was performed on individual’s
dynamic state trajectories. We applied the methods to identify
metabotypes in data from a crossover acute post-prandial dietary
intervention study on 17 overweight males (BMI 25–30 kg/m2, 41–67 y of
age) undergoing three dietary interventions (pickled herring, baked
herring and baked beef, measuring 79 metabolites (from GC-MS
metabolomics) at 8 time points (0-7h).

Both methods identified two potential metabotype clusters, predominantly
in amino acids after the meat diet. The clustering associated to
baseline levels of creatinine, strengthening the plausibility of found
metabotypes. The CP method is a general approach, not specific to
time-resolved data, and provides better fit if the data is multilinear.
Conversely, DMD is designed for time-resolved data, for which it often
provides a better fit than CP. We concluded that both the CP and the DMD
approach are well suited to identify metabotypes in tensor data from a
wide variety of complex experimental designs.

Presentation format: *Poster Only*
