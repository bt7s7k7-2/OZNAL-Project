from functools import cache, partial
from json import dumps
from typing import Callable

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from shiny import reactive
from shiny.express import expressify, input, render, ui
from sklearn.cross_decomposition import PLSRegression
from sklearn.decomposition import PCA
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.linear_model import ElasticNetCV, Lasso, LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsRegressor
from sklearn.preprocessing import PowerTransformer, StandardScaler
from sklearn.tree import DecisionTreeRegressor

from src.StrategyType import StrategyType

ui.page_opts(title="Communities and Crime Dataset")


def lda_process(lda, params, X, y):
    y_binned = pd.qcut(y.iloc[:, 0], q=params["n_components"] + 1, labels=False, duplicates="drop")
    actual_classes = len(np.unique(y_binned))

    max_lda_components = actual_classes - 1
    lda = LinearDiscriminantAnalysis(n_components=max_lda_components)
    return lda.fit_transform(X, y_binned)


dimensional_reduction_strategies = [
    StrategyType("none", "None"),
    StrategyType("pca", "Principal Component Analysis", lambda: PCA(), {"n_components": lambda key: ui.input_slider(key, "Number of Components", 1, 30, 20, step=1)}),
    StrategyType("pls", "Partial Least Squares", lambda: PLSRegression(), {"n_components": lambda key: ui.input_slider(key, "Number of Components", 1, 20, 3, step=1)}),
    StrategyType(
        "lda",
        "Linear Discriminant Analysis",
        lambda: LinearDiscriminantAnalysis(),
        {"n_components": lambda key: ui.input_slider(key, "Number of Components", 2, 20, 3, step=1)},
        custom_executor=lda_process,
    ),
]

ml_strategies = [
    StrategyType(
        "elastic_net",
        "ElasticNetCV",
        lambda: ElasticNetCV(n_jobs=-1, random_state=2611),
        {
            "cv": lambda key: ui.input_slider(key, "CV Folds", 5, 30, 15, step=5),
        },
    ),
    StrategyType(
        "lasso",
        "LASSO",
        lambda: Lasso(random_state=2611),
        {
            "alpha": lambda key: ui.input_numeric(key, "Alpha", 0.001490, min=0, max=1),
        },
    ),
    StrategyType("linear_regression", "LinearRegression", lambda: LinearRegression()),
    StrategyType("decision_tree", "DecisionTree", lambda: DecisionTreeRegressor(random_state=2611)),
    StrategyType(
        "random_forest",
        "RandomForest",
        lambda: RandomForestRegressor(n_jobs=-1, random_state=2611, oob_score=False),
        {
            "n_estimators": lambda key: ui.input_slider(key, "Estimators", 50, 300, 200, step=50),
            "max_depth": lambda key: ui.input_slider(key, "Max Depth", 3, 8, 6, step=1),
            "max_samples": lambda key: ui.input_slider(key, "Max Samples", 0, 1, 0.4, step=0.1),
            "criterion": lambda key: ui.input_select(key, "Criterion", ["squared_error", "absolute_error", "friedman_mse", "poisson"], selected="squared_error"),
        },
    ),
    StrategyType(
        "gradient_boost",
        "GradientBoost",
        lambda: GradientBoostingRegressor(random_state=2611),
        {
            "n_estimators": lambda key: ui.input_slider(key, "Estimators", 10, 200, 20, step=10),
            "learning_rate": lambda key: ui.input_slider(key, "Learning Rate", 0, 1, 0.2, step=0.1),
            "max_depth": lambda key: ui.input_slider(key, "Max Depth", 1, 8, 3, step=1),
            "subsample": lambda key: ui.input_slider(key, "Subsample", 0, 1, 0.9, step=0.1),
            "loss": lambda key: ui.input_select(key, "Loss", ["squared_error", "absolute_error", "huber", "quantile"], selected="squared_error"),
        },
    ),
    StrategyType(
        "knn",
        "kNN",
        lambda: KNeighborsRegressor(n_jobs=-1),
        {
            "n_neighbours": lambda key: ui.input_slider(key, "Neighbours", 10, 200, 50, step=10),
            "metric": lambda key: ui.input_select(key, "Metric", ["uniform", "distance"], selected="uniform"),
            "weights": lambda key: ui.input_select(key, "Weights", ["euclidean", "manhattan", "minkowski"], selected="manhattan"),
        },
    ),
]

strategy_lookup = dict[str, StrategyType]()


@expressify
def create_strategy_input(key: str, label: str, strategies: list[StrategyType], default: str | None):
    ui.input_select(key, label, dict([(strategy.key, strategy.label) for strategy in strategies]), selected=default)

    for strategy in strategies:
        strategy_lookup[f"{key}/{strategy.key}"] = strategy

        if len(strategy.parameters) == 0:
            continue

        with ui.panel_conditional(f"input.{key} == {dumps(strategy.key)}"):
            with ui.card():
                ui.card_header(strategy.label)
                for parameter, render in strategy.parameters.items():
                    render(f"{key}__{strategy.key}__{parameter}")


def execute_strategy(key: str):
    strategy_key = input[key]()
    strategy = strategy_lookup[f"{key}/{strategy_key}"]

    if strategy.factory is None:
        return strategy, None

    executor = strategy.factory()
    callback_payload = {}

    for parameter in strategy.parameters:
        value = input[f"{key}__{strategy_key}__{parameter}"]()
        if strategy.auto_assign:
            setattr(executor, parameter, value)
        callback_payload[parameter] = value

    if strategy.callback is not None:
        strategy.callback(executor, callback_payload)

    if strategy.custom_executor:
        executor = partial(strategy.custom_executor, executor, callback_payload)

    return strategy, executor


with ui.sidebar(width=350):
    ui.input_checkbox("transform_y", "Transform Y", True)
    ui.input_checkbox("transform_x", "Transform X", True)

    create_strategy_input("reduction_method", "Dimensional Reduction", dimensional_reduction_strategies, default="lda")

    ui.input_slider("training_split", "Training Split", 0.1, 0.9, 0.8, step=0.1)

    create_strategy_input("ml_method", "Model", ml_strategies, default="random_forest")

    ui.input_action_button("go", "Run Pipeline").add_class("btn-primary w-100")


@cache
def get_data():
    df = pd.read_csv("./data/data.csv", na_values="?")

    metadata_cols = ["state", "county", "community", "communityname", "fold"]
    response_variable = "ViolentCrimesPerPop"

    X = df.drop(metadata_cols + [response_variable], axis=1)
    y = df[[response_variable]]

    return X, y


@reactive.calc
@reactive.event(input.go, input.transform_y, input.transform_x, ignore_none=False)
def pipeline():
    X, y = get_data()

    result = {}

    result["_1"] = f"Original shape: X={X.shape}, y={y.shape}"
    result["_1"] += f"\nFeatures: {X.shape[1]}, Samples: {X.shape[0]}"

    result["y_raw"] = y

    if input.transform_y():
        transformer = PowerTransformer()
        y = pd.DataFrame(transformer.fit_transform(y), columns=y.columns)
        result["y_processed"] = y

        result["_2"] = f"Transformed Y with PowerTransformer(lambda={transformer.lambdas_[0]})"
    else:
        transformer = None
        result["y_processed"] = None
        result["_2"] = "Skipping Y transformation."

    X = X.drop((_ := X.isnull().sum())[_ > 1].index, axis=1)
    X = X.drop(_ := X[X.OtherPerCap.isnull()].index[0])
    y = y.drop(_)
    result["_2"] += f"\nDataset shape after dropping missing values: {X.shape}"

    if input.transform_x():
        scaler = StandardScaler()
        X = pd.DataFrame(scaler.fit_transform(X), columns=X.columns)
        result["x_processed"] = X.agg(["min", "max"])
        result["_2"] += "\nTransformed dataset using StandardScaler"
    else:
        result["x_processed"] = None
        result["_2"] += "\nSkipping X transformation."

    reduction_strategy, reduction_executor = execute_strategy("reduction_method")
    result["_3"] = f"Using dimensionality reduction: {reduction_strategy.label}"

    if reduction_executor is not None:
        if isinstance(reduction_executor, Callable):
            X = reduction_executor(X, y)
        else:
            reduction_executor.fit(X, y)
            X = reduction_executor.transform(X)

    result["_3"] += f"\nReduced dataset shape: {X.shape}"

    ml_strategy, ml_executor = execute_strategy("ml_method")
    result["_4"] = f"Using model: {ml_strategy.label}"

    X_train, X_test, y_train, y_test = train_test_split(X, y, train_size=input.training_split(), random_state=9138)
    result["_4"] += f"\nTraining set: {X_train.shape}; Testing set: {X_test.shape}"

    assert ml_executor is not None

    if isinstance(ml_executor, Callable):
        y_pred = ml_executor(X_train, X_test, y_train, y_test)
    else:
        ml_executor.fit(X_train, y_train)
        y_pred = ml_executor.predict(X_test)

    r2 = r2_score(y_test, y_pred)
    mse = mean_squared_error(
        y_test if transformer is None else transformer.inverse_transform(y_test),
        y_pred if transformer is None else transformer.inverse_transform(y_pred.reshape(-1, 1)),
    )

    result["_4"] += f"\nScore: MSE: {mse:.6f}; R²: {r2:.4f}"

    return result


PRE_WRAP = "white-space: pre-wrap; overflow-wrap: anywhere;"

with ui.card() as card:
    ui.card_header("Input Data")

    @render.express
    def output_1():
        result = pipeline()
        ui.span(result["_1"]).add_style(PRE_WRAP)

    @render.plot
    def output_y_raw():
        result = pipeline()
        y = result["y_raw"]

        fig, [ax, ay] = plt.subplots(1, 2, figsize=(10, 5), width_ratios=(1 / 3, 2 / 3))
        fig.suptitle("Raw Y")
        y.boxplot(ax=ax)
        y.hist(bins=20, ax=ay)

        return fig

    with ui.panel_conditional("input.transform_y"):

        @render.plot
        def output_y_processed():
            result = pipeline()
            y = result["y_processed"]
            if y is None:
                return

            fig, [ax, ay] = plt.subplots(1, 2, figsize=(10, 5), width_ratios=(1 / 3, 2 / 3))
            fig.suptitle("Transformed Y")
            y.boxplot(ax=ax)
            y.hist(bins=20, ax=ay)

            return fig

    @render.express
    def output_2():
        result = pipeline()
        ui.span(result["_2"]).add_style(PRE_WRAP)

    with ui.panel_conditional("input.transform_x"):

        @render.data_frame
        def output_x_processed():
            result = pipeline()
            X = result["x_processed"]
            if X is None:
                return

            return X


with ui.card(**{"class": "mt-4"}):  # pyright: ignore[reportArgumentType]
    ui.card_header("Dimensionality Reduction")

    @render.express
    def output_3():
        result = pipeline()
        ui.span(result["_3"]).add_style(PRE_WRAP)


with ui.card(**{"class": "mt-4"}):  # pyright: ignore[reportArgumentType]
    ui.card_header("Model Performance")

    @render.express
    def output_4():
        result = pipeline()
        ui.span(result["_4"]).add_style(PRE_WRAP)
