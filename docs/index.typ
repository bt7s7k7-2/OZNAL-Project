#set page(paper: "a4")
#set text(font: "Lato", size: 11pt)
#set heading(numbering: "1.")

// --- Table Show Rules ---
#let table-dark = rgb("#717171")
#let table-light = rgb("#e9e9e9")

// Style the text inside tables
#show table.cell.where(y: 0): set text(weight: "bold")

// Configure zebra striping, row borders, and alignment
#set table(
  align: left,
  stroke: (x, y) => (
    bottom: if y == 0 { 0.5pt + table-dark } else { none },
    top: none,
    left: none,
    right: none,
  ),
  fill: (x, y) => if y > 0 and calc.rem(y, 2) == 1 { table-light } else { none },
)

// Wrap tables in a shrink-fit box to apply the thick top and bottom outer borders
#show table: t => box(
  stroke: (
    top: 1.5pt + table-dark,
    bottom: 1.5pt + table-dark,
  ),
  t,
)

// Title Page
#align(center + horizon)[
  #text(size: 24pt, weight: "bold")[Task 5: Dimensionality Reduction]\
  #v(1em)
  #text(size: 16pt)[Communities and Crime Dataset]\
  #v(2em)
  #text(size: 14pt, style: "italic")[PCA, LDA and Explainability Analysis]\
  #v(4em)
  #text(size: 10pt, table-dark)[
    Dataset: UCI Machine Learning Repository (ID: 183)\
    Redmond, M. (2002). Communities and Crime.\
    https://doi.org/10.24432/C53W3X
  ]
]

#pagebreak()

// Table of Contents
#outline(title: "Table of Contents")

#pagebreak()

= Introduction
The Communities and Crime dataset from the UCI Machine Learning Repository combines socio-economic data from the 1990 US Census, law enforcement data from the 1990 US LEMAS survey, and crime data from the 1995 FBI UCR. The goal variable is the per capita violent crime rate (ViolentCrimesPerPop). The dataset contains 1994 communities described by 127 attributes.

With 127 features, this dataset is highly multidimensional. Many features are correlated (e.g., various income measures, multiple demographic percentages). This makes it an ideal candidate for dimensionality reduction techniques. In this report, we apply PCA (Principal Component Analysis) and LDA (Linear Discriminant Analysis) to reduce the feature space, compare their impact on regression and classification performance, and critically evaluate whether explainable machine learning remains feasible after the reduction.

= Dataset Description and Preprocessing
The raw dataset contains 127 features and 1994 samples. The following preprocessing steps were applied:

- *Non-predictive columns removed*: state, county, community, communityname, fold
- *Non-numeric columns dropped*: communityname (string type)
- *Missing values*: No columns exceeded 50% missing; remaining missing values imputed with column median
- *Standardization*: All features scaled to zero mean and unit variance (StandardScaler)

*After preprocessing, the dataset contains 99 numeric features and 1994 samples.*

The target variable ViolentCrimesPerPop is continuous, normalized to the range $[0, 1]$, with mean $= 0.238$ and standard deviation $= 0.233$. The distribution is right-skewed, with most communities having low crime rates.

= PCA - Principal Component Analysis

== How PCA Transforms the Feature Space
PCA is an unsupervised dimensionality reduction technique that finds orthogonal directions (principal components) along which the data has maximum variance. It works by computing the eigenvectors of the covariance matrix of the standardized data. Each principal component is a linear combination of all original features:

$ P C_k = w_(k 1) * x_1 + w_(k 2) * x_2 + ... + w_(k p) * x_p $

where $w_(k i)$ are the loadings (weights) and $x_i$ are the original standardized features. The components are ordered by the amount of variance they explain. PCA effectively rotates the coordinate system to align with the directions of greatest variability in the data.

== Explained Variance Analysis

#figure(
  table(
    columns: 3,
    align: left,
    [*Variance Threshold*], [*Components Needed*], [*Reduction (from 99)*],
    [90%], [22], [77.8%],
    [95%], [34], [65.7%],
    [99%], [58], [41.4%],
  ),
)

#figure(
  image("../figures/task5_pca_variance.pdf", width: 80%),
  caption: [PCA explained variance - individual components (left) and cumulative (right).],
)

The first principal component alone explains 25.3% of total variance. The variance curve shows a typical "elbow" pattern - the first few components capture large portions of variance, while later components contribute increasingly less. To retain 95% of variance, only 34 out of 99 components are needed, representing a 65.7% reduction in dimensionality.

== Top Feature Loadings
Examining the loadings of the first three principal components reveals what each component represents:

#figure(
  table(
    columns: 4,
    align: left,
    [*Component*], [*Var. Explained*], [*Top Positive Loadings*], [*Top Negative Loadings*],
    [PC1 (25.3%)], [25.3%], [medFamInc, medIncome,\ PctKids2Par], [PctPopUnderPov,\ pctWPubAsst,\ PctHousNoPhone],
    [PC2 (17.0%)], [17.0%], [PctRecImmig10,\ PctRecImmig8,\ PctRecImmig5], [PctSpeakEnglOnly,\ PctBornSameState],
    [PC3 (9.4%)], [9.4%], [PersPerOccupHous,\ PersPerFam,\ PersPerOwnOccHous], [HousVacant, numbUrban,\ population],
  ),
)

PC1 can be interpreted as a "socioeconomic status" axis: communities with high income and two-parent families on one end, and communities with high poverty and public assistance on the other. PC2 captures immigration patterns. PC3 represents household size vs. urbanization.

= LDA - Linear Discriminant Analysis

== How LDA Transforms the Feature Space
LDA is a supervised dimensionality reduction technique that projects data onto a lower-dimensional space by maximizing class separability. Unlike PCA, which maximizes variance regardless of labels, LDA maximizes the ratio of between-class scatter to within-class scatter (Fisher's criterion):

$ J(w) = (w^T S_B w) / (w^T S_W w) $

where $S_B$ is the between-class scatter matrix and $S_W$ is the within-class scatter matrix. LDA requires class labels, so the continuous target was discretized into 5 classes using quantile binning. The maximum number of LDA components is $min(n_"features", n_"classes" - 1) = 4$.

== LDA Results

#figure(
  table(
    columns: 2,
    align: left,
    [*Component*], [*Explained Variance Ratio*],
    [LD1], [83.7%],
    [LD2], [11.6%],
    [LD3], [2.9%],
    [LD4], [1.7%],
  ),
)

LDA achieves extreme dimensionality reduction: from 99 features to just 4 components (96% reduction). The first discriminant (LD1) captures 83.7% of the class-discriminative information, indicating that crime level classes are largely separable along a single axis.

#figure(
  image("../figures/task5_lda_projection.pdf", width: 80%),
  caption: [LDA 2D projection - communities colored by crime level (0=low, 4=high).],
)

The LDA projection shows clear separation between low-crime (green) and high-crime (red) communities along the LD1 axis. The intermediate classes overlap more, which is expected given that crime rates form a continuum rather than discrete categories.

= 2D Visualizations - PCA vs LDA

#figure(
  image("../figures/task5_2d_projections.pdf", width: 90%),
  caption: [Comparison of PCA (left) and LDA (right) 2D projections, colored by crime rate.],
)

The side-by-side comparison reveals a fundamental difference between the two methods:

- *PCA (left)*: The 2D projection explains 42.2% of total variance. Points are spread according to overall data variability. Crime rate coloring shows some gradient but with significant mixing - PCA does not optimize for target separation.
- *LDA (right)*: The 2D projection is specifically optimized for class separation. Low-crime and high-crime communities are more clearly separated along LD1. This makes LDA superior for classification visualization, but it requires labeled data and cannot be used for unsupervised exploration.

= Regression Comparison: Original vs Reduced Features
To evaluate the practical impact of dimensionality reduction on predictive performance, Ridge regression and Random Forest models were trained using 5-fold cross-validation.

#figure(
  table(
    columns: 4,
    align: left,
    [*Model*], [*Features*], [*Dimensions*], [*R² (mean +/- std)*],
    [Ridge Regression], [Original], [99], [0.6535 +/- 0.0228],
    [Ridge Regression], [PCA (95%)], [34], [0.6421 +/- 0.0255],
    [Ridge Regression], [PCA (20)], [20], [0.6381 +/- 0.0242],
    [Ridge Regression], [PCA (10)], [10], [0.6262 +/- 0.0232],
    [Random Forest], [Original], [99], [0.6438 +/- 0.0369],
    [Random Forest], [PCA (95%)], [34], [0.6123 +/- 0.0243],
  ),
)

Key observations from the regression comparison:

- PCA with 34 components (95% variance) achieves R² = 0.6421, only 1.7% lower than the original 99 features (R² = 0.6535). This minimal loss suggests that the discarded 5% of variance is mostly noise.
- Even with just 10 PCA components (89.9% reduction), Ridge regression achieves R² = 0.6262, demonstrating that the core predictive signal is concentrated in few dimensions.
- Random Forest suffers more from PCA reduction (R² drops from 0.6438 to 0.6123), likely because tree-based models benefit from operating on individual features rather than linear combinations.

= Classification Comparison: Original vs LDA vs PCA
For classification, the continuous target was discretized into 5 equal-frequency classes. Logistic Regression and Random Forest classifiers were evaluated using stratified 5-fold CV.

#figure(
  table(
    columns: 4,
    align: left,
    [*Model*], [*Features*], [*Dimensions*], [*Accuracy*],
    [Logistic Regression], [Original], [99], [0.5060 +/- 0.0156],
    [Logistic Regression], [LDA], [4], [0.5727 +/- 0.0230],
    [Logistic Regression], [PCA], [4], [0.4709 +/- 0.0247],
    [Logistic Regression], [PCA (95%)], [34], [0.5020 +/- 0.0243],
    [Random Forest], [Original], [99], [0.5216 +/- 0.0157],
    [Random Forest], [LDA], [4], [0.5441 +/- 0.0179],
  ),
)

The most striking result is that LDA with only 4 components outperforms all other configurations, including the original 99 features:

- LDA (4 features) achieves 57.3% accuracy vs. 50.6% for original features with Logistic Regression - a 6.7 percentage point improvement despite 96% fewer dimensions.
- PCA with the same 4 components achieves only 47.1% - worse than random for 5 classes. This demonstrates that unsupervised variance maximization is not aligned with class separation for this dataset.
- LDA's superiority stems from its supervised nature: it explicitly optimizes for the directions that best discriminate between crime level classes.

= Performance vs Number of PCA Components

#figure(
  image("../figures/task5_performance_vs_components.pdf", width: 80%),
  caption: [Ridge regression R² score as a function of the number of PCA components.],
)

The performance curve shows rapid improvement with the first 10-15 components, then a plateau. Beyond approximately 30 components, additional PCA dimensions provide negligible improvement. The red dashed line shows the baseline performance using all 99 original features - PCA approaches but never quite reaches this level, indicating a small but consistent information loss from the dimensionality reduction.

= Explainability Evaluation

== Feature Importance Comparison
A Random Forest regressor was trained on both original features and PCA-transformed features to compare interpretability through feature importances.

#figure(
  table(
    columns: 2,
    align: left,
    [], [*R² Score*],
    [RF on Original features], [0.6129],
    [RF on PCA features], [0.6089],
  ),
)

#figure(
  image("../figures/task5_feature_importances.pdf", width: 90%),
  caption: [Feature importances - original features (left) vs PCA components (right).],
)

== Original Features - Direct Interpretability
With original features, the model identifies clear, actionable predictors:

#figure(
  table(
    columns: 3,
    align: left,
    [*Feature*], [*Importance*], [*Meaning*],
    [PctIlleg], [0.3274], [Percentage of kids born to never married],
    [PctKids2Par], [0.2126], [Percentage of kids in two-parent families],
    [racePctWhite], [0.0286], [Percentage of population that is caucasian],
    [PctFam2Par], [0.0228], [Percentage of families headed by two parents],
    [NumIlleg], [0.0145], [Number of kids born to never married],
    [FemalePctDiv], [0.0133], [Percentage of females who are divorced],
  ),
)

These importances are directly interpretable. A policy maker can understand that family structure variables (PctIlleg, PctKids2Par) are the strongest predictors of violent crime rates. This kind of insight is immediately actionable.

== PCA Features - Abstract Components
After PCA transformation, the most important "feature" is PC1 (importance = 0.4423). However, PC1 is a linear combination of all 99 original features. Telling a stakeholder that "Principal Component 1 is the most important predictor" provides no actionable insight without further analysis of the component loadings.

= Mapping PCA Components to Original Features
To partially recover interpretability, we can examine the loadings of the most important PCA components to understand which original features they represent:

*PC1 (Importance: 0.44, Variance: 24.8%)*\
Positive loadings: medFamInc (0.180), medIncome (0.178), PctKids2Par (0.176), pctWInvInc (0.174), PctYoungKids2Par (0.172)\
Negative loadings: PctPopUnderPov (-0.174), pctWPubAsst (-0.166), PctHousNoPhone (-0.165), PctNotHSGrad (-0.163), PctUnemployed (-0.158)\
Interpretation: PC1 represents a "socioeconomic prosperity" axis - higher values indicate wealthier communities with stable family structures; lower values indicate poverty and social disadvantage.

*PC3 (Importance: 0.08, Variance: 9.7%)*\
Positive loadings: PersPerOccupHous (0.254), householdsize (0.230), PersPerFam (0.230)\
Negative loadings: HousVacant (-0.183), numbUrban (-0.165), NumInShelters (-0.163)\
Interpretation: PC3 contrasts dense household occupancy with urban vacancy and homelessness.

#figure(
  image("../figures/task5_pca_loadings_heatmap.pdf", width: 90%),
  caption: [Heatmap of PCA component loadings for the most influential features.],
)

While loading analysis provides partial interpretability, it introduces complexity: each component is influenced by many features simultaneously, and the relationship between a component and the target is indirect. This makes PCA-based models inherently harder to explain to non-technical stakeholders compared to models using original features.

= Summary and Comparison of Methods

#figure(
  table(
    columns: 6,
    align: left,
    [*Method*], [*Type*], [*Dimensions*], [*Reduction*], [*Best Use*], [*Interpretability*],
    [Original], [-], [99], [0%], [Baseline], [Full - direct features],
    [PCA (10)], [Unsupervised], [10], [89.9%], [Fast regression], [Low - abstract combos],
    [PCA (34)], [Unsupervised], [34], [65.7%], [Regression], [Low - abstract combos],
    [LDA (4)], [Supervised], [4], [96.0%], [Classification], [Low - class-driven combos],
  ),
)

#figure(
  table(
    columns: 3,
    align: left,
    [*Criterion*], [*PCA*], [*LDA*],
    [Supervision], [Unsupervised], [Supervised (needs labels)],
    [Objective], [Maximize variance], [Maximize class separation],
    [Max components], [min(n, p)], [n_classes - 1],
    [Regression], [Good (minimal R² loss)], [Not applicable],
    [Classification], [Poor at low dims], [Excellent at low dims],
    [Assumptions], [None (linear)], [Normal dist., equal covariance],
    [Interpretability], [Loadings analysis possible], [Loadings analysis possible],
  ),
)

= Conclusion
This analysis demonstrates that dimensionality reduction is highly effective for the Communities and Crime dataset, reducing 99 features to as few as 4-34 components with acceptable performance trade-offs.

*Key Findings*
- *PCA achieves efficient compression*: 34 components retain 95% of variance and achieve R² = 0.6421 in regression (vs. 0.6535 with all 99 features) - a loss of only 1.7%.
- *LDA excels at classification*: With only 4 components, LDA achieves 57.3% classification accuracy, outperforming the original 99 features (50.6%) and PCA with the same dimensionality (47.1%).
- *The methods are complementary*: PCA is better for regression (unsupervised, preserves variance), while LDA is better for classification (supervised, preserves class separability).

*Explainability Assessment*\
Explainable machine learning is significantly impacted by dimensionality reduction:

- *Before reduction*: Models operating on original features provide direct, interpretable insights. The strongest predictors of violent crime are family structure variables (PctIlleg = 0.33 importance, PctKids2Par = 0.21). These findings are immediately meaningful to policymakers and researchers.
- *After PCA reduction*: Models operate on abstract principal components. While loading analysis can partially map components back to original features (e.g., PC1 represents "socioeconomic prosperity"), the relationship is indirect and involves all features simultaneously. Explaining to a stakeholder that "PC1 has high importance" requires additional interpretation steps.
- *Information lost*: With a 95% variance threshold, approximately 5% of data variance is discarded. This may include subtle but meaningful patterns. Additionally, the non-linear relationships between individual features and the target are obscured by the linear combination into components. Feature-level granularity is fundamentally lost.

*Practical Recommendation*\
For this dataset, the choice between dimensionality reduction and original features depends on the use case:

- If the priority is computational efficiency or the model requires low-dimensional input: use PCA with 20-34 components for regression, or LDA for classification.
- If the priority is explainability (e.g., informing crime prevention policy): work with original features and apply feature selection methods (LASSO, mutual information) that preserve individual feature identity while reducing dimensionality.
- A hybrid approach is also viable: use PCA/LDA for initial exploratory analysis and model screening, then build the final model on selected original features for interpretability.
