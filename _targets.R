
# _targets.R
# Purpose: Define a reproducible pipeline for the fundraising campaign analysis

library(targets)  # Load targets; enables reproducible pipeline
library(data.table)  # Load data.table; supports fast data manipulation
library(stringdist)  # Load stringdist; supports fuzzy matching

list(  # Define pipeline; list of targets for reproducibility
  tar_target(contacts, fread("contacts.csv")),  # Load contacts.csv; creates data.table with 270 rows
  tar_target(transactions, fread("transactions.csv")),  # Load transactions.csv; creates data.table with 30 rows
  tar_target(matched_all, {  # Clean and match data; depends on contacts and transactions
    # Clean data
    contacts[, urn := as.character(urn)]  # Convert urn to character; ensures consistent joins
    transactions[, urn := as.character(urn)]  # Convert urn; avoids numeric mismatch issues
    transactions[is.na(amount), amount := 0]  # Set NA amounts to 0; precautionary (no NAs)
    contacts[, full_name := tolower(trimws(paste(first, last)))]  # Create full_name; for fuzzy matching
    contacts[, full_address := tolower(trimws(paste(addr_line, addr_suburb, addr_postcode, addr_state)))]  # Create full_address; for fuzzy matching
    transactions[, full_name := tolower(trimws(paste(first, last)))]  # Same for transactions; standardizes names
    transactions[, full_address := tolower(trimws(paste(addr_line, addr_suburb, addr_postcode, addr_state)))]  # Same for address; for fuzzy matching
    # Exact matching
    matched_exact <- merge(contacts, transactions, by = "urn", all.x = TRUE)  # Left join; keeps all 270 contacts
    unmatched_trans <- transactions[!urn %in% matched_exact[!is.na(amount), urn]]  # Find unmatched transactions; expect ~3-4
    # Fuzzy matching
    if (nrow(unmatched_trans) > 0) {  # Check for unmatched transactions; proceed with fuzzy matching
      dist_matrix_name <- stringdistmatrix(unmatched_trans$full_name, contacts$full_name, method = "lv")  # Compute Levenshtein distance; name similarity
      dist_matrix_addr <- stringdistmatrix(unmatched_trans$full_address, contacts$full_address, method = "lv")  # Compute distance; address similarity
      combined_dist <- (dist_matrix_name + dist_matrix_addr) / 2  # Average distances; balances name and address
      best_matches <- apply(combined_dist, 1, which.min)  # Find index of closest contact
      min_dists <- apply(combined_dist, 1, min)  # Compute minimum distance for each transaction
      good_idx <- min_dists < 5  # Threshold: <5 edits; tuned for matches like "J Welch" to "Janie Welch"
      fuzzy_matches <- unmatched_trans[good_idx]  # Keep good fuzzy matches; expect ~3-4
      fuzzy_matches[, matched_urn := contacts$urn[best_matches[good_idx]]]  # Assign matched urn
      setnames(fuzzy_matches, "urn", "original_urn")  # Rename original urn; for audit
      fuzzy_matches[, urn := matched_urn]  # Set urn to matched urn; for joining
      fuzzy_matches <- fuzzy_matches[, .(urn, first, last, age, addr_line, addr_suburb, addr_postcode, addr_state, amount, full_name, full_address, original_urn, matched_urn)]  # Select columns
      setnames(fuzzy_matches, c("first", "last", "age", "addr_line", "addr_suburb", "addr_postcode", "addr_state", "full_name", "full_address"), c("first.y", "last.y", "age.y", "addr_line.y", "addr_suburb.y", "addr_postcode.y", "addr_state.y", "full_name.y", "full_address.y"))  # Rename columns
      rbind(matched_exact, fuzzy_matches, fill = TRUE)  # Combine exact and fuzzy matches
    } else {
      matched_exact  # Use exact matches only
    }
  }),
  tar_target(metrics, {  # Compute metrics; depends on matched_all
    matched_all[, match_type := ifelse(is.na(amount), "No Match", "Exact")]  # Flag non-donors as "No Match"
    matched_all[!is.na(matched_urn), match_type := "Fuzzy"]  # Flag fuzzy-matched donors
    num_gifts <- sum(!is.na(matched_all$amount))  # Count gifts; expect ~27
    response_rate <- num_gifts / nrow(contacts)  # Proportion of donors; expect ~0.1
    avg_gift <- mean(matched_all$amount[!is.na(matched_all$amount)])  # Average gift; expect ~$44
    total_income <- sum(matched_all$amount[!is.na(matched_all$amount)])  # Sum of gifts; expect ~$1160
    cost <- 3 * nrow(contacts)  # Cost: $3 per contact; 270 * 3 = 810
    net_income <- total_income - cost  # Net income; expect ~$350
    list(num_gifts = num_gifts, response_rate = response_rate, avg_gift = avg_gift, total_income = total_income, cost = cost, net_income = net_income)  # Return metrics
  }),
  tar_target(output, {  # Output metrics; depends on metrics
    cat("Number of gifts:", metrics$num_gifts, "\n")  # Print number of gifts
    cat("Response rate:", round(metrics$response_rate, 4), "\n")  # Print rounded response rate
    cat("Average gift:", round(metrics$avg_gift, 2), "\n")  # Print rounded average gift
    cat("Total income:", metrics$total_income, "\n")  # Print total income
    cat("Net income:", metrics$net_income, "\n")  # Print net income
    NULL  # Return NULL to avoid storing unnecessary output
  })
)