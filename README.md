# DSCI 532 Individual Assignment: World Education Dashboard

## About
This repository contains an interactive R Shiny dashboard designed to explore and visualize the Global Education Dataset. The application allows users to analyze completion rates, out-of-school rates, and literacy gaps across different regions and education levels. 

A key feature of this dashboard is the **AI-Powered Data Filtering** tab, which integrates a Large Language Model (Anthropic's Claude via the `ellmer` package) to dynamically filter the dataset using natural language queries and instantly visualize the results.

**Live Application URL:** [View the deployed dashboard on Posit Connect](https://wnsong-d532-individual-assignment-r-shiny.share.connect.posit.cloud)

## App Features
- Interactive world map of education indicators
- Regional comparisons of completion rates and literacy gaps
- Filterable data table with selectable features
- AI‑powered data querying using large language models
- Clean, responsive UI built with bslib and Plotly

## Installation & Local Setup

To run this application locally on your computer, you will need R installed ([downloaded directly from CRAN](https://cran.r-project.org/)).
And follow the steps:

### 1. Clone the Repository
Open your terminal and clone this repository to your local machine:
```
git clone https://github.com/canadasung/d532-individual-assignment-r-shiny.git
cd d532-individual-assignment-r-shiny
```

### 2. Install Required R Packages
Open your R console and run the following command to install all necessary dependencies:
```
install.packages(c("shiny", "bslib", "dplyr", "tidyr", "readr", "plotly", "DT", "dotenv", "ellmer"))
```

### 3. Restore Dependencies
In R console, run
```
renv::restore()
```

### 4. Anthropic API and Set Environment Variable (Local Only)
You may skip this step if you don't have an Anthropic API key ready, but Chat Bot wouldn't be able to response if this step can't be satisfied.
To make Chat Bot working, you need to prepare your own Anthropic API key and add to a .Renviron file locally in the project folder under the same path as the app.R file.
In your newly added .Renviron file, please add API keys like following format:
```
ANTHROPIC_API_KEY="your_api_key_here"
```

### 5. Run the App Locally
In R console, run
```
shiny::runApp()
```

## Data Source

The dataset is sourced from [Kaggle - World Educational Data](https://www.kaggle.com/datasets/nelgiriyewithana/world-educational-data/data), compiled from UNESCO Institute for Statistics, UNICEF, and UN Statistics Division.

## License

See [LICENSE](LICENSE) for details.
