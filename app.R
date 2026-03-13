library(shiny)
library(bslib)
library(querychat)
library(lubridate)
library(dplyr)
library(tidyr)
library(leaflet)
library(echarts4r)
library(reactable)
library(readr)
library(ggplot2)
library(duckdb)
library(plotly)
library(DT)
# Assuming you have equivalent R implementations for ellmer and QueryChat
# library(ellmer)



# ==========================================
#   SETUP & DATA LOADING
# ==========================================
# Load data
df <- read_csv("data/processed/processed_global_education.csv")

table_feature_choices <- colnames(df)
region_choices <- c("North America", "South America", "Europe", "Asia", "Africa", "Oceania")

region_color_map <- c(
  "North America" = "#66c2a5",
  "South America" = "#fc8d62",
  "Europe" = "#8da0cb",
  "Asia" = "#e78ac3",
  "Africa" = "#a6d854",
  "Oceania" = "#ffd92f"
)

# Note: In R selectInput, lists format as c("Label" = "Value")
map_metric_choices <- list(
  "Access" = c(
    "Out-of-school rate (Primary, avg)" = "OOSR_Avg_Primary",
    "Out-of-school rate (Lower secondary, avg)" = "OOSR_Avg_Lower_Secondary",
    "Out-of-school rate (Upper secondary, avg)" = "OOSR_Avg_Upper_Secondary",
    "Out-of-school rate gender gap (Primary)" = "OOSR_Gap_Primary",
    "Out-of-school rate gender gap (Lower secondary)" = "OOSR_Gap_Lower_Secondary",
    "Out-of-school rate gender gap (Upper secondary)" = "OOSR_Gap_Upper_Secondary",
    "Gross primary enrollment" = "Gross_Primary_Education_Enrollment",
    "Gross tertiary enrollment" = "Gross_Tertiary_Education_Enrollment"
  ),
  "Completion" = c(
    "Completion rate (Primary, avg)" = "Completion_Avg_Primary",
    "Completion rate (Lower secondary, avg)" = "Completion_Avg_Lower_Secondary",
    "Completion rate (Upper secondary, avg)" = "Completion_Avg_Upper_Secondary",
    "Completion rate gender gap (Primary)" = "Completion_Gap_Primary",
    "Completion rate gender gap (Lower secondary)" = "Completion_Gap_Lower_Secondary",
    "Completion rate gender gap (Upper secondary)" = "Completion_Gap_Upper_Secondary"
  ),
  "Learning" = c(
    "Grade 2–3 proficiency (Reading)" = "Grade_2_3_Proficiency_Reading",
    "Grade 2–3 proficiency (Math)" = "Grade_2_3_Proficiency_Math",
    "Primary end proficiency (Reading)" = "Primary_End_Proficiency_Reading",
    "Primary end proficiency (Math)" = "Primary_End_Proficiency_Math",
    "Lower secondary end proficiency (Reading)" = "Lower_Secondary_End_Proficiency_Reading",
    "Lower secondary end proficiency (Math)" = "Lower_Secondary_End_Proficiency_Math"
  ),
  "Context" = c(
    "Youth literacy rate (Male)" = "Youth_15_24_Literacy_Rate_Male",
    "Youth literacy rate (Female)" = "Youth_15_24_Literacy_Rate_Female",
    "Youth literacy gender gap (Male - Female)" = "Literacy_Gap",
    "Birth rate" = "Birth_Rate",
    "Unemployment rate" = "Unemployment_Rate"
  )
)

metric_label <- function(metric_key) {
  for (group in map_metric_choices) {
    if (metric_key %in% group) {
      return(names(group)[group == metric_key])
    }
  }
  return(metric_key)
}

ACTIVE_MODEL <- "Cloud: Anthropic (Claude Haiku 4.5)"

# QueryChat Setup
greeting <- readLines("greeting.md", warn = FALSE) |> paste(collapse = "\n")
data_desc <- readLines("data_desc.md", warn = FALSE) |> paste(collapse = "\n")

# Assuming QueryChat translates to an R6 class or similar initialization
qc <- QueryChat$new(
  data = df,
  "global_education",
  client = "claude/claude-haiku-4-5-20251001",
  # client = "claude/claude-sonnet-4-5"
  greeting = "greeting.md",
  data_description = "data_desc.md"
)

# ==========================================
#   UI DEFINITION
# ==========================================
ui <- page_fluid(
  tags$head(tags$title("World Education Dashboard")),
  
  navset_tab(
    # --- Tab 1: Main Dashboard ---
    nav_panel(
      "Main Dashboard",
      h2("World Education Dashboard"),
      layout_sidebar(
        sidebar = sidebar(
          width = 300,
          card(
            card_header("Filters"),
            checkboxGroupInput(
              "input_region",
              "Select Region:",
              choices = region_choices,
              selected = region_choices
            ),
            div(class = "mb-2",
                actionButton("select_all_regions", "Select All", class = "btn-outline-primary btn-sm me-2"),
                actionButton("reset_regions", "Reset", class = "btn-outline-secondary btn-sm")
            ),
            p(
              "The selected regions apply to the map and KPI cards in the Overview tab, charts in the Completion & Literacy tab, and the table in the Data Table tab.",
              class = "text-muted small mt-2"
            )
          )
        ),
        navset_tab(
          nav_panel(
            "Overview",
            layout_columns(
              col_widths = c(8, 4),
              card(
                card_header("Global Education Indicators Map"),
                p("Select a metric to map across the chosen regions. The region filter also updates the KPI cards.", class = "text-muted small"),
                selectInput("input_map_metric", "Map metric", choices = map_metric_choices),
                plotlyOutput("world_map", height = "450px") # Kept as plotly for native ISO3 map handling
              ),
              layout_column_wrap(
                width = 1,
                uiOutput("metric_average_box"),
                uiOutput("metric_vs_world_box"),
                uiOutput("metric_coverage_box")
              )
            )
          ),
          nav_panel(
            "Completion & Literacy",
            layout_column_wrap(
              width = 1/3,
              card(
                card_header("Average Education Level by Region"),
                p("Compare regional patterns in average education level", class = "text-muted small"),
                plotOutput("education_level_by_region_bar") # Updated to plotOutput
              ),
              card(
                card_header("Completion Rate Gap by Region"),
                p("Compare regional patterns in completion rate gap between genders", class = "text-muted small"),
                plotOutput("completion_rate_gap_by_region_bar") # Updated to plotOutput
              ),
              card(
                full_screen = TRUE,
                card_header("Male vs Female Literacy Rate by Region"),
                p("Compare regional patterns in gender disparities in literacy rates", class = "text-muted small"),
                plotOutput("literacy_scatterplot") # Updated to plotOutput
              )
            )
          ),
          nav_panel(
            "Data Table",
            card(
              card_header("Data Table"),
              p("Inspect the filtered country-level data and choose which features to display", class = "text-muted"),
              selectizeInput(
                "input_table_features",
                "Table features:",
                choices = table_feature_choices,
                selected = c("Countries and areas", "Region"),
                multiple = TRUE
              ),
              DTOutput("tbl")
            )
          )
        )
      )
    ),
    
    # --- Tab 2: Query with Chat ---
    nav_panel(
      "Query with Chat",
      h2(sprintf("AI-Powered Data Filtering (Powered by %s)", ACTIVE_MODEL)),
      layout_sidebar(
        sidebar = qc$sidebar(),
        height = "80vh",
        layout_column_wrap(
          width = 1,
          heights_equal = "row",
          card(
            card_header(
              class = "d-flex justify-content-between align-items-center",
              textOutput("chat_title", inline = TRUE),
              downloadButton("download_chat_data", "Download CSV", class = "btn-success btn-sm")
            ),
            DTOutput("chat_tbl")
          ),
          layout_column_wrap(
            width = 1/2,
            card(
              card_header("Literacy Rate Scatterplot (Filtered)"),
              plotOutput("chat_scatter") # Updated to plotOutput
            ),
            card(
              card_header("Avg Education Level by Region (Filtered)"),
              plotOutput("chat_bar") # Updated to plotOutput
            )
          )
        )
      )
    )
  )
)

# ==========================================
#   SERVER LOGIC
# ==========================================
server <- function(input, output, session) {
  
  # ----------------------------------------
  # TAB 1 LOGIC (Main Dashboard)
  # ----------------------------------------
  
  processed_df <- reactive({ df })
  
  filtered_df <- reactive({
    d <- processed_df()
    if (!is.null(input$input_region) && length(input$input_region) > 0) {
      d <- d |> filter(Region %in% input$input_region)
    }
    d
  })
  
  selected_metric <- reactive({ input$input_map_metric })
  
  filtered_metric_series <- reactive({
    filtered_df()[[selected_metric()]] |> na.omit()
  })
  
  global_metric_series <- reactive({
    df[[selected_metric()]] |> na.omit()
  })
  
  region_completion_rate_df <- reactive({
    filtered_df() |>
      select(Region, iso3, Completion_Avg_Primary, Completion_Avg_Lower_Secondary, Completion_Avg_Upper_Secondary) |>
      pivot_longer(
        cols = starts_with("Completion_Avg_"),
        names_to = "Completion_Rate_Group",
        values_to = "Completion_Rate"
      ) |>
      mutate(
        Education_Level = gsub("Completion_Avg_", "", Completion_Rate_Group),
        Education_Level = gsub("_", " ", Education_Level)
      ) |>
      group_by(Region, Education_Level) |>
      summarise(Completion_Rate = mean(Completion_Rate, na.rm = TRUE), .groups = "drop")
  })
  
  completion_gap_by_region_df <- reactive({
    filtered_df() |>
      select(Region, Completion_Gap_Primary, Completion_Gap_Lower_Secondary, Completion_Gap_Upper_Secondary) |>
      pivot_longer(
        cols = starts_with("Completion_Gap_"),
        names_to = "Gap_Group",
        values_to = "Completion_Rate_Gap"
      ) |>
      mutate(
        Education_Level = gsub("Completion_Gap_", "", Gap_Group),
        Education_Level = gsub("_", " ", Education_Level)
      ) |>
      group_by(Region, Education_Level) |>
      summarise(Completion_Rate_Gap = mean(Completion_Rate_Gap, na.rm = TRUE), .groups = "drop")
  })
  
  # Map Output (Kept as Plotly)
  output$world_map <- renderPlotly({
    req(input$input_map_metric)
    d <- filtered_df()
    metric <- input$input_map_metric
    
    plot_ly(
      d, 
      type = 'choropleth', 
      locations = ~iso3, 
      z = ~get(metric), 
      colorscale = "Viridis",
      hoverinfo = "text",
      text = ~paste("<b>", `Countries and areas`, "</b><br>Value:", round(get(metric), 2))
    ) |>
      layout(
        geo = list(showcoastlines = TRUE, showcountries = TRUE, showframe = FALSE, projection = list(type = "natural earth")),
        margin = list(l = 0, r = 0, t = 30, b = 0)
      )
  })
  
  output$literacy_scatterplot <- renderPlot({
    d <- filtered_df()
    
    xy_min <- min(c(d$Youth_15_24_Literacy_Rate_Male, d$Youth_15_24_Literacy_Rate_Female), na.rm = TRUE) - 5
    xy_max <- max(c(d$Youth_15_24_Literacy_Rate_Male, d$Youth_15_24_Literacy_Rate_Female), na.rm = TRUE) + 5
    
    ggplot(d, aes(x = Youth_15_24_Literacy_Rate_Male, y = Youth_15_24_Literacy_Rate_Female, color = Region)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") + # Adds the y=x diagonal line
      scale_color_manual(values = region_color_map) +
      coord_cartesian(xlim = c(xy_min, xy_max), ylim = c(xy_min, xy_max)) +
      labs(x = "Male Literacy Rate (%)", y = "Female Literacy Rate (%)") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  output$completion_rate_gap_by_region_bar <- renderPlot({
    d <- completion_gap_by_region_df()
    d$Education_Level <- factor(d$Education_Level, levels = c("Primary", "Lower Secondary", "Upper Secondary"))
    
    ggplot(d, aes(x = Education_Level, y = Completion_Rate_Gap, fill = Region)) +
      geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
      scale_fill_manual(values = region_color_map) +
      labs(x = "Education Level", y = "Completion Rate Gap (Male - Female, %)") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  output$education_level_by_region_bar <- renderPlot({
    d <- region_completion_rate_df()
    d$Education_Level <- factor(d$Education_Level, levels = c("Primary", "Lower Secondary", "Upper Secondary"))
    
    ggplot(d, aes(x = Education_Level, y = Completion_Rate, fill = Region)) +
      geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
      scale_fill_manual(values = region_color_map) +
      scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
      labs(x = "Education Level", y = "Completion Rate (%)") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
    
  output$tbl <- renderDT({
    d <- filtered_df()
    cols <- input$input_table_features
    if (is.null(cols) || length(cols) == 0) cols <- colnames(d)
    
    datatable(
      d[, intersect(cols, colnames(d)), drop = FALSE],
      options = list(scrollY = "300px", scrollX = TRUE),
      selection = "single"
    )
  })
  
  # KPIs
  output$metric_average_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    vals <- filtered_metric_series()
    
    if (length(vals) == 0) return(value_box(title = paste("Average:", label), value = "No data", theme = "secondary"))
    
    avg_val <- mean(vals, na.rm = TRUE)
    value_box(
      title = paste("Average:", label),
      value = sprintf("%.1f", avg_val),
      HTML("<strong style='opacity:0.9'>Across selected regions</strong>"),
      theme = "primary"
    )
  })
  
  output$metric_vs_world_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    filtered_vals <- filtered_metric_series()
    global_vals <- global_metric_series()
    
    if (length(filtered_vals) == 0 || length(global_vals) == 0) {
      return(value_box(title = paste("Vs world average:", label), value = "No data", theme = "secondary"))
    }
    
    filtered_avg <- mean(filtered_vals, na.rm = TRUE)
    global_avg <- mean(global_vals, na.rm = TRUE)
    diff <- filtered_avg - global_avg
    
    caption <- if (diff >= 0) {
      sprintf("%.1f above world average (%.1f)", diff, global_avg)
    } else {
      sprintf("%.1f below world average (%.1f)", -diff, global_avg)
    }
    
    theme <- if (abs(diff) < 1) "success" else "warning"
    
    value_box(
      title = paste("Vs world average:", label),
      value = sprintf("%+.1f", diff),
      HTML(sprintf("<strong style='opacity:0.9'>%s</strong>", caption)),
      theme = theme
    )
  })
  
  output$metric_coverage_box <- renderUI({
    metric <- selected_metric()
    label <- metric_label(metric)
    d <- filtered_df()
    
    n_total <- nrow(d)
    n_available <- sum(!is.na(d[[metric]]))
    
    if (n_total == 0) return(value_box(title = paste("Data coverage:", label), value = "No data", theme = "secondary"))
    
    pct <- 100 * n_available / n_total
    
    value_box(
      title = paste("Data coverage:", label),
      value = sprintf("%d/%d", n_available, n_total),
      HTML(sprintf("<strong style='opacity:0.9'>%.0f%% of selected countries have data</strong>", pct)),
      theme = "info"
    )
  })
  
  observeEvent(input$select_all_regions, {
    updateCheckboxGroupInput(session, "input_region", selected = region_choices)
  })
  
  observeEvent(input$reset_regions, {
    updateCheckboxGroupInput(session, "input_region", selected = region_choices)
  })
  
  # ----------------------------------------
  # TAB 2 LOGIC (QueryChat)
  # ----------------------------------------
  qc_vals <- qc$server() 
  
  output$chat_title <- renderText({
    title <- qc_vals$title()
    if (is.null(title) || title == "") "Global Education Dataset" else title
  })
  
  output$chat_tbl <- renderDT({
    d <- qc_vals$df()
    
    if ("Unnamed: 0" %in% colnames(d)) d <- d |> select(-`Unnamed: 0`)
    
    cat_cols <- c("Countries and areas", "Region", "iso3")
    num_cols <- setdiff(colnames(d), cat_cols)
    final_order <- c(cat_cols, num_cols)
    valid_cols <- intersect(final_order, colnames(d))
    
    datatable(d[, valid_cols, drop = FALSE], options = list(scrollY = "250px", scrollX = TRUE), selection = "single")
  })
   
  output$chat_scatter <- renderPlot({
    d <- qc_vals$df()
    if (nrow(d) == 0) {
      return(ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No Data Available for this query") + theme_void())
    }
    
    ggplot(d, aes(x = Youth_15_24_Literacy_Rate_Male, y = Youth_15_24_Literacy_Rate_Female, color = Region)) +
      geom_point(size = 3, alpha = 0.8) +
      scale_color_brewer(palette = "Set2") +
      labs(x = "Male Literacy Rate (%)", y = "Female Literacy Rate (%)") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  output$chat_bar <- renderPlot({
    d <- qc_vals$df()
    if (nrow(d) == 0) {
      return(ggplot() + annotate("text", x = 0.5, y = 0.5, label = "No Data Available for this query") + theme_void())
    }
    
    d_grouped <- d |>
      select(Region, iso3, Completion_Avg_Primary, Completion_Avg_Lower_Secondary, Completion_Avg_Upper_Secondary) |>
      pivot_longer(
        cols = starts_with("Completion_Avg_"),
        names_to = "Completion_Rate_Group",
        values_to = "Completion_Rate"
      ) |>
      mutate(
        Education_Level = gsub("Completion_Avg_", "", Completion_Rate_Group),
        Education_Level = gsub("_", " ", Education_Level)
      ) |>
      group_by(Region, Education_Level) |>
      summarise(Completion_Rate = mean(Completion_Rate, na.rm = TRUE), .groups = "drop")
    
    d_grouped$Education_Level <- factor(d_grouped$Education_Level, levels = c("Primary", "Lower Secondary", "Upper Secondary"))
    
    ggplot(d_grouped, aes(x = Education_Level, y = Completion_Rate, fill = Region)) +
      geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
      scale_fill_brewer(palette = "Set2") +
      scale_y_continuous(limits = c(0, 100)) +
      labs(x = "Education Level", y = "Completion Rate (%)") +
      theme_minimal() +
      theme(legend.position = "bottom")
  })
  
  output$download_chat_data <- downloadHandler(
    filename = function() { "global_education_filtered.csv" },
    content = function(file) { write_csv(qc_vals$df(), file) }
  )
}

shinyApp(ui, server)