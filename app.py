import matplotlib.pyplot as plt
import numpy as np
from shiny.express import input, render, ui

ui.page_opts(title="Application Name")

with ui.sidebar():
    ui.input_slider("x_freq", "Frequency X", 1, 5, 1, step=1, ticks=True)
    ui.input_slider("y_freq", "Frequency Y", 1, 5, 1, step=1, ticks=True)
    ui.input_slider("t_max", "Max T", 50, 200, 100, step=50, ticks=True)
    ui.input_slider("length", "Length", 1, 4, 2, step=1, ticks=True)


with ui.card():
    ui.card_header("Plot")

    @render.plot(width=500, height=500)
    def greeting():
        t = np.linspace(0, np.pi * input.length(), input.t_max())
        x = np.cos(t * input.x_freq())
        y = np.sin(t * input.y_freq())

        fig, ax = plt.subplots()
        ax.plot(x, y)

        return fig
