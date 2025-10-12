# visuals.R
# Author: Deborrah David
# Date: October 10, 2025
# Purpose: Generate static and interactive visualisations for fundraising campaign

if (!require(data.table)) install.packages("data.table")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(scales)) install.packages("scales")
if (!require(plotly)) install.packages("plotly")
library(data.table)
library(ggplot2)
library(scales)
library(plotly)

#Please run the transaction_matching.R file first before running the codes below.

# 1. Bubble Chart: Donation Size by Age
# Purpose: Shows donation size vs. age, colored by state, with transparency for amount
p1 <- ggplot(donors, aes(x = age.x, y = jitter(rep(0, nrow(donors)), factor = 1), size = amount, color = addr_state.x, alpha = amount)) + 
  geom_point() +  # Plot bubbles for each donor
  scale_size_continuous(range = c(3, 15), name = "Donation Amount ($)") +  # Scale bubble size by donation amount
  scale_alpha_continuous(range = c(0.4, 1), name = "Donation Amount ($)") +  # Adjust transparency (smaller donations more translucent)
  scale_color_brewer(palette = "Set1", name = "State") +  # Use distinct colors for states
  labs(title = "Donation Size by Age", x = "Age", y = "", color = "State", size = "Amount", alpha = "Amount") +  # Add clear labels
  theme_minimal() +  # Use clean theme for professional look
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())  # Remove y-axis for focus on bubbles
print(p1)  # Display static chart
ggsave("bubble_chart.png", p1, width = 8, height = 6, dpi = 300)  # Save high-res PNG for PPT
ggplotly(p1)  # Convert to interactive widget (hover for donor details)


# 2. Histogram: Donation Amounts by Age Group
# Purpose: Shows distribution of donation amounts across age groups
p2 <- ggplot(donors, aes(x = amount, fill = age_bin)) +
  geom_histogram(binwidth = 10, position = "dodge") +  # Plot histogram with bars side-by-side
  scale_fill_brewer(palette = "Set2", name = "Age Group") +  # Use distinct colors for age bins
  labs(title = "Donation Amounts by Age Group", x = "Donation Amount ($)", y = "Count") +  # Add clear labels
  theme_minimal()  # Clean theme for clarity
print(p2)  # Display static chart
ggsave("histogram_donations_age.png", p2, width = 8, height = 6, dpi = 300)  # Save for PPT
ggplotly(p2)  # Interactive (hover for counts)


# 3. Boxplot: Donation Amounts by State
# Purpose: Shows variability and outliers in donation amounts per state
p3 <- ggplot(donors, aes(x = addr_state.x, y = amount, fill = addr_state.x)) +
  geom_boxplot() +  # Plot boxplot for each state
  scale_fill_brewer(palette = "Set1", name = "State") +  # Use distinct colors for states
  labs(title = "Donation Amounts by State", x = "State", y = "Donation Amount ($)") +  # Add clear labels
  theme_minimal() +  # Clean theme
  theme(legend.position = "none")  # Remove legend to avoid clutter
print(p3)  # Display static chart
ggsave("boxplot_donations_state.png", p3, width = 8, height = 6, dpi = 300)  # Save for PPT
ggplotly(p3)  # Interactive (hover for stats)


# 4. Stacked Bar: Match Types by State
# Purpose: Shows data quality (exact/fuzzy/no match) by state
match_by_state <- matched_all[, .N, by = .(addr_state.x, match_type)]  # Count records by state and match type
p4 <- ggplot(match_by_state, aes(x = addr_state.x, y = N, fill = match_type)) +
  geom_bar(stat = "identity") +  # Plot stacked bar chart
  scale_fill_brewer(palette = "Set1", name = "Match Type") +  # Distinct colors for match types
  labs(title = "Match Types by State", x = "State", y = "Count") +  # Add clear labels
  theme_minimal()  # Clean theme
print(p4)  # Display static chart
ggsave("stacked_match_state.png", p4, width = 8, height = 6, dpi = 300)  # Save for PPT
ggplotly(p4)  # Interactive (hover for counts)


# 5. Bubble Map: Donations by Location
# Purpose: Shows geographic distribution of donations
p5 <- ggplot(donors, aes(x = lon, y = lat, size = amount, color = addr_state.x)) +
  geom_point(alpha = 0.7) +  # Plot bubbles with slight transparency
  scale_size_continuous(range = c(3, 15), name = "Donation Amount ($)") +  # Scale bubble size
  scale_color_brewer(palette = "Set1", name = "State") +  # Distinct colors for states
  labs(title = "Donation Bubble Map", x = "Longitude", y = "Latitude") +  # Add clear labels
  theme_minimal() +  # Clean theme
  theme(legend.position = "right", panel.grid = element_blank()) +  # Remove grid, keep legend
  coord_fixed(ratio = 1)  # Equal aspect ratio for map-like appearance
print(p5)  # Display static chart
ggsave("bubble_map.png", p5, width = 8, height = 6, dpi = 300)  # Save for PPT
ggplotly(p5)  # Interactive (hover for donor details)




