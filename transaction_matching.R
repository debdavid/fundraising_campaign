# transaction_matching.R
# Author: Deborrah David
# Date: October 09, 2025
# Purpose: Analyze fundraising campaign, match transactions to contacts, and compute metrics

library(data.table)  # Load data.table; enables fast, efficient data manipulation
library(stringdist)  # Load stringdist; supports fuzzy matching 

# Step 1: Extract data
contacts <- fread("contacts.csv")  # Read contacts.csv; loads rows efficiently
transactions <- fread("transactions.csv")  # Read transactions.csv

# Step 2: Clean data
contacts[, urn := as.character(urn)]  # Convert urn to character; ensures consistent joins (integer in data)
transactions[, urn := as.character(urn)]  # Convert urn; avoids numeric mismatch issues in merge
transactions[is.na(amount), amount := 0]  # Set NA amounts to 0; precautionary
contacts[, full_name := tolower(trimws(paste(first, last)))]  # Create full_name; combines first/last for fuzzy matching
contacts[, full_address := tolower(trimws(paste(addr_line, addr_suburb, addr_postcode, addr_state)))]  # Create full_address; combines address fields for fuzzy matching
transactions[, full_name := tolower(trimws(paste(first, last)))]  # Same for transactions; standardizes names
transactions[, full_address := tolower(trimws(paste(addr_line, addr_suburb, addr_postcode, addr_state)))]  # Same for address; prepares for fuzzy matching

# Step 3: Match data
matched_exact <- merge(contacts, transactions, by = "urn", all.x = TRUE)  # Left join; keeps all 270 contacts, adds transactions where urn matches
unmatched_trans <- transactions[!urn %in% matched_exact[!is.na(amount), urn]]  # Find transactions without exact urn match
if (nrow(unmatched_trans) > 0) {  # Check if unmatched transactions exist; proceed with fuzzy matching
  dist_matrix_name <- stringdistmatrix(unmatched_trans$full_name, contacts$full_name, method = "lv")  # Compute Levenshtein distance; measures name similarity
  dist_matrix_addr <- stringdistmatrix(unmatched_trans$full_address, contacts$full_address, method = "lv")  # Compute distance; measures address similarity
  combined_dist <- (dist_matrix_name + dist_matrix_addr) / 2  # Average distances; balances name and address similarity
  best_matches <- apply(combined_dist, 1, which.min)  # Find index of closest contact per unmatched transaction
  min_dists <- apply(combined_dist, 1, min)  # Compute minimum distance for each unmatched transaction
  good_idx <- min_dists < 5  # Threshold: <5 edits; tuned for matches like "J Welch" to "Janie Welch"
  fuzzy_matches <- unmatched_trans[good_idx]  # Keep only good fuzzy matches
  fuzzy_matches[, matched_urn := contacts$urn[best_matches[good_idx]]]  # Assign matched urn from contacts
  setnames(fuzzy_matches, "urn", "original_urn")  # Rename original urn; tracks source for audit
  fuzzy_matches[, urn := matched_urn]  # Set urn to matched urn; aligns with contacts for joining
  fuzzy_matches <- fuzzy_matches[, .(urn, first, last, age, addr_line, addr_suburb, addr_postcode, addr_state, amount, full_name, full_address, original_urn, matched_urn)]  # Select columns; matches exact join structure
  setnames(fuzzy_matches, c("first", "last", "age", "addr_line", "addr_suburb", "addr_postcode", "addr_state", "full_name", "full_address"), c("first.y", "last.y", "age.y", "addr_line.y", "addr_suburb.y", "addr_postcode.y", "addr_state.y", "full_name.y", "full_address.y"))  # Rename columns; matches merge suffixes
  matched_all <- rbind(matched_exact, fuzzy_matches, fill = TRUE)  # Combine exact and fuzzy matches; fill handles column mismatches
} else {
  matched_all <- matched_exact  # Use exact matches only if no unmatched transactions
}
matched_all[, match_type := ifelse(is.na(amount), "No Match", "Exact")]  # Flag non-donors as "No Match"; donors as "Exact"
matched_all[!is.na(matched_urn), match_type := "Fuzzy"]  # Flag fuzzy-matched donors as "Fuzzy"

# Step 4: Compute metrics
num_gifts <- sum(!is.na(matched_all$amount))  # Count non-NA amounts; total gifts
response_rate <- num_gifts / nrow(contacts)  # Proportion of donors
avg_gift <- mean(matched_all$amount[!is.na(matched_all$amount)])  # Average gift
total_income <- sum(matched_all$amount[!is.na(matched_all$amount)])  # Sum of gifts
cost <- 3 * nrow(contacts)  # Cost per contact
net_income <- total_income - cost  # Calculate net income

# Step 5: Output results
cat("Number of gifts:", num_gifts, "\n")  # Print number of gifts
cat("Response rate:", round(response_rate, 4), "\n")  # Print rounded response rate for clarity
cat("Average gift:", round(avg_gift, 2), "\n")  # Print rounded average gift for clarity
cat("Total income:", total_income, "\n")  # Print total income
cat("Net income:", net_income, "\n")  # Print net income


