#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Dec 27 17:19:53 2024

@author: aristomenischryssafesprogopoulos
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import adfuller
import statsmodels.api as sm
from mpl_toolkits.mplot3d import Axes3D

# Example Dataset Creation
def generate_sample_data():
    np.random.seed(42)
    dates = pd.date_range(start="2020-01-01", periods=100)
    data = {
        'Date': dates,
        'GDP Growth (%)': np.random.normal(loc=2, scale=0.5, size=100),
        'Inflation Rate (%)': np.random.normal(loc=3, scale=1, size=100),
        'Unemployment Rate (%)': np.random.uniform(4, 10, size=100),
        'Policy Rate (%)': np.random.uniform(0.5, 5, size=100),
        'Exports (Billions)': np.random.uniform(50, 200, size=100),
        'Imports (Billions)': np.random.uniform(40, 180, size=100)
    }
    return pd.DataFrame(data)

# Visualizations for Economic Analysis
def generate_visualizations(df):
    # Set up the style for seaborn
    sns.set(style="whitegrid")

    # Time Series Visualization
    plt.figure(figsize=(12, 6))
    for column in df.columns[1:]:
        plt.plot(df['Date'], df[column], label=column)
    plt.title("Economic Indicators Over Time")
    plt.xlabel("Date")
    plt.ylabel("Value")
    plt.legend()
    plt.show()

    # Correlation Heatmap
    plt.figure(figsize=(10, 6))
    corr = df.drop('Date', axis=1).corr()
    sns.heatmap(corr, annot=True, cmap="coolwarm", fmt='.2f')
    plt.title("Correlation Between Economic Indicators")
    plt.show()
    
    # Heatmap with Clustermap
    sns.clustermap(df.drop('Date', axis=1).corr(), annot=True, cmap="coolwarm", figsize=(10, 8))
    plt.title("Clustermap of Economic Indicators")
    plt.show()


    # Pairplot for Distribution and Relationships
    sns.pairplot(df.drop('Date', axis=1))
    plt.show()

    # Histogram for Distribution Analysis
    df.drop('Date', axis=1).hist(figsize=(12, 8), bins=15)
    plt.suptitle("Distribution of Economic Indicators", size=16)
    plt.show()

    # Regression Analysis - Example: Inflation Rate vs GDP Growth
    plt.figure(figsize=(8, 6))
    sns.regplot(x='Inflation Rate (%)', y='GDP Growth (%)', data=df)
    plt.title("Regression: Inflation vs GDP Growth")
    plt.xlabel("Inflation Rate (%)")
    plt.ylabel("GDP Growth (%)")
    plt.show()

    # Seasonal Decomposition for Time Series Analysis
    decomposition = seasonal_decompose(df['GDP Growth (%)'], model='additive', period=12)
    fig, axes = plt.subplots(4, 1, figsize=(12, 10), sharex=True)
    decomposition.observed.plot(ax=axes[0], title="Observed")
    decomposition.trend.plot(ax=axes[1], title="Trend")
    decomposition.seasonal.plot(ax=axes[2], title="Seasonal")
    decomposition.resid.plot(ax=axes[3], title="Residual")
    fig.suptitle("Seasonal Decomposition of GDP Growth", size=16, y=1.05)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.show()
    
    # ADF Test for Stationarity
    adf_test = adfuller(df['GDP Growth (%)'])
    print("ADF Test Statistic:", adf_test[0])
    print("p-value:", adf_test[1])
    print("Critical Values:", adf_test[4])

    # Scatter Plot Matrix with Regression Lines
    sns.pairplot(df.drop('Date', axis=1), kind='reg', diag_kind='kde')
    plt.suptitle("Scatterplot Matrix with Regression Lines", size=16, y=1.02)
    plt.show()

    # Residual Plot for Regression Model
    plt.figure(figsize=(8, 6))
    model = sm.OLS(df['GDP Growth (%)'], sm.add_constant(df['Inflation Rate (%)']))
    results = model.fit()
    sns.residplot(x=results.fittedvalues, y=results.resid, lowess=True, line_kws={'color': 'red', 'lw': 1})
    plt.title("Residual Plot for Regression")
    plt.xlabel("Fitted Values")
    plt.ylabel("Residuals")
    plt.show()

    # Fancy 3D Plot
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(df['GDP Growth (%)'], df['Inflation Rate (%)'], df['Unemployment Rate (%)'], c='blue', marker='o')
    ax.set_title("3D Scatter Plot of Key Economic Indicators")
    ax.set_xlabel("GDP Growth (%)")
    ax.set_ylabel("Inflation Rate (%)")
    ax.set_zlabel("Unemployment Rate (%)")
    plt.show()

   

# Main Function to Run the Analysis
def main():
    # Generate or load the dataset
    data = generate_sample_data()
    
    # Generate visualizations
    generate_visualizations(data)

if __name__ == "__main__":
    main()
