#set text(font: "Lato", size: 11pt)
#set page(margin: (top: 40pt, bottom: 0pt, x: 20pt))
#set par(justify: true)

#show emph: set text(fill: rgb("#11554c"))

#align(center)[
  #text(size: 24pt, weight: "bold")[Communities and Crime Dataset]\
  #v(0.25em)
  #text(size: 16pt)[Branislav Trstenský]\
  #v(0.25em)
  #text(size: 10pt, rgb("#717171"))[
    Dataset: UCI Machine Learning Repository (ID: 183)\
    Redmond, M. (2002). Communities and Crime.\
    #link("https://doi.org/10.24432/C53W3X")
  ]
  #v(1em)
]

#columns(2)[
  = Project description

  Violent crime is a symptom of many systemic factors. Using the combination of socio-economic and crime rate data, a predictive model will be created to predict crime rate based on external influence. Determining which factors are most influential could guide action to mitigate these factors and thus possibly lower the resulting crime rate.

  = Dimensionality Reduction

  The dataset has a very large number of features and many of them are correlated. According to tests, _Linear Discriminant Analysis_ dimensionality reduction allowed the models to best fit the data, even better compared to using all original features at once.

  The feature space has been simplified to three components. By analysing how these components are influenced by original features, the following approximate meaning was determined:

  - _Component 1_: correlated with poor rural areas with high populations and large but unstable family structures, recent immigration
  - _Component 2_: correlated with rich urban neighbourhoods with stable families, old but not recent immigration
  - _Component 3_: similar to _1_, but with lower income for white people and with a well integrated immigrant population

  = Model Evaluation

  For best explainability the _Linear Regression_ model will be used. This provides the best performance while showing the coefficients for each feature which can be mapped back to the original features.

  Another model useful for explainability is _Random Forest_ which, while not being as easy to interpret as numeric coefficients, can describe non-linear relationships. Compared to _Gradient Boosting_, due its nature of averaging results from multiple trees, smoother values that are easier to interpret can be obtained.

  #colbreak()

  = Explanation of Crime Rate

  Crime rate is mostly explained by a single composite feature. _Component 1_ has the greatest correlation with rising crime rate.

  #v(1em)

  #align(center)[
    #text(size: 3em)[$69.24\%$]\
    *No dimensionality reduction*

    #text(size: 2em)[↓]

    #text(size: 3em)[$71.47\%$]\
    *LDA Dimensionality Reduction*

    #text(size: 2em)[↓]

    #text(size: 3em)[$70.07\%$]\
    *Explained by _Component 1_*
  ]

  #v(1em)

  This component is correlated with high population, high numbers of people living together. It is negatively correlated with urbanisation and home ownership. There is also a negative correlation with median income in contrast with positive correlation with total family income, pointing to families needing many earners. In addition, a negative correlation with children living with both parents suggests unstable families.

  This paints a picture of rural and highly populated counties with low standards of living, pushing people towards cohabitation and children staying with their families due to difficulty of home ownership.

  These are the factors most influential on crime rate.

  *In conclusion:* The best way to prevent violent crime is developing communities (e.g. urbanisation), mitigating poverty and supporting family stability.
]
