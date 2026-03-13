# DSCI 532 Individual Assignment: World Education Dashboard

## About
This repository contains an interactive R Shiny dashboard designed to explore and visualize the Global Education Dataset. The application allows users to analyze completion rates, out-of-school rates, and literacy gaps across different regions and education levels. 

A key feature of this dashboard is the **AI-Powered Data Filtering** tab, which integrates a Large Language Model (Anthropic's Claude via the `ellmer` package) to dynamically filter the dataset using natural language queries and instantly visualize the results.

**Live Application:** [View the deployed dashboard on Posit Connect](https://wnsong-d532-individual-assignment-r-shiny.share.connect.posit.cloud)

## App Features
- Interactive world map of education indicators
- Regional comparisons of completion rates and literacy gaps
- Filterable data table with selectable features
- AI‑powered data querying using large language models
- Clean, responsive UI built with bslib and Plotly

## Installation & Local Setup

To run this application locally on your Mac, you will need R installed (downloaded directly from CRAN).

### 1. Clone the Repository
Open your terminal and clone this repository to your local machine:
```bash
git clone [https://github.com/canadasung/d532-individual-assignment-r-shiny.git](https://github.com/canadasung/d532-individual-assignment-r-shiny.git)
cd d532-individual-assignment-r-shiny
```

### 2. Install Required R Packages
Open your R console (or the Positron R terminal) and run the following command to install all necessary dependencies:
```
install.packages(c("shiny", "bslib", "dplyr", "tidyr", "readr", "plotly", "DT", "dotenv", "ellmer"))
```

### 3. Restore Dependencies
In R console, run
```
renv::restore()
```

### 4. Set Environment Variable (Local Only)
To make ChatBot work, you need to add .Renviron locally in the project folder in the same path as the app.R file.
In your newly added .Renviron file, please add API keys like following format:
```
ANTHROPIC_API_KEY="your_api_key_here"
OPENAI_API_KEY="your_api_key_here"
```

### 5. Run the App Locally
```
shiny::runApp()
```