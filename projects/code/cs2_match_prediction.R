# =============================================================================
# Predicting Professional CS2 Match Results
# Griffin DesRoches, Ian Ryu
#
# Reconstructed R script — base R only (no external packages required).
#
# CONTEXT / ASSUMPTIONS (please read before running):
#   The original code for this project was lost. This script was rebuilt from
#   the write-up's methodology (Sections 1-5) and from the exact structure of
#   its tables and figures, not from the original source file. It reproduces
#   the same pipeline, feature set, model, and evaluation approach described
#   there. Given a raw dataset shaped like the one assumed below, running this
#   should reproduce output of the same *form* as Tables 1-6 and Figures 1-2.5
#   -- but the exact numbers in the original report came from fitting real
#   HLTV data this script has no access to, so they won't match unless you
#   run it on that same data.
#
#   Assumed raw data shape (one row per completed map/match):
#     match_id, date, team1, team2, team1_win (1/0)
#     team1_<stat>, team2_<stat>  for each stat in RAW_STATS below
#   This mirrors the paper's description of HLTV "mapstatsid" pages scraped
#   in team1-vs-team2 format. If your actual CSV differs, adjust the column
#   names in RAW_STATS / read.csv() below -- the rest of the pipeline is
#   written generically against those names.
#
#   Table 1 in the original lists diff_roll5_kills as "average multikill
#   rounds" and diff_roll5_multi_kill_rounds as "average kills" -- the two
#   descriptions appear to be swapped (a typo in the write-up). This script
#   uses the sensible pairing: diff_roll5_kills <- raw "kills" stat,
#   diff_roll5_multi_kill_rounds <- raw "multi_kill_rounds" stat.
# =============================================================================

set.seed(1)

USE_SAMPLE_DATA <- TRUE  # FALSE once you point this at your real CSV

RAW_STATS <- c("adr", "assists", "clutches_won", "deaths", "kast_pct",
               "kills", "multi_kill_rounds", "opening_deaths",
               "opening_kills", "rating_3", "swing_pct")

# -----------------------------------------------------------------------------
# 0. Demo data (delete this block once USE_SAMPLE_DATA <- FALSE)
# -----------------------------------------------------------------------------
if (USE_SAMPLE_DATA) {

  n_matches <- 1500
  teams <- paste0("Team_", LETTERS[1:20])
  dates <- sort(sample(seq(as.Date("2023-01-01"), as.Date("2025-11-01"), by = "day"),
                        n_matches, replace = TRUE))

  raw <- data.frame(
    match_id = seq_len(n_matches),
    date     = dates,
    team1    = sample(teams, n_matches, replace = TRUE)
  )
  raw$team2 <- sapply(raw$team1, function(t1) sample(setdiff(teams, t1), 1))

  for (s in RAW_STATS) {
    base_scale <- switch(s,
      adr = 80, assists = 12, clutches_won = 2, deaths = 15, kast_pct = 70,
      kills = 16, multi_kill_rounds = 4, opening_deaths = 5, opening_kills = 5,
      rating_3 = 1.05, swing_pct = 12
    )
    raw[[paste0("team1_", s)]] <- round(rnorm(n_matches, base_scale, base_scale * 0.15), 2)
    raw[[paste0("team2_", s)]] <- round(rnorm(n_matches, base_scale, base_scale * 0.15), 2)
  }
  raw$team1_win <- rbinom(n_matches, 1, 0.55)

  rm(n_matches, teams, dates, base_scale, s)
} else {
  raw <- read.csv("your_raw_cs2_data.csv", stringsAsFactors = FALSE)
  raw$date <- as.Date(raw$date)
}

cat(sprintf("Raw data set: %d rows, %d columns\n", nrow(raw), ncol(raw)))

# =============================================================================
# 2. Data Description and Processing
#    -- rolling 5-game per-team averages, then team1-minus-team2 differences
# =============================================================================

roll_mean_past <- function(x, k = 5) {
  # mean of the PAST k games only (never the current game), NA until k
  # prior games exist for that team
  n <- length(x)
  out <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    if (i > k) out[i] <- mean(x[(i - k):(i - 1)])
  }
  out
}

# --- reshape wide (team1/team2 per row) into long (one row per team per match)
# so each team's rolling average is computed from its own match history,
# regardless of whether it was listed as "team1" or "team2" in a given row
long1 <- data.frame(match_id = raw$match_id, date = raw$date,
                     team = raw$team1, raw[paste0("team1_", RAW_STATS)])
long2 <- data.frame(match_id = raw$match_id, date = raw$date,
                     team = raw$team2, raw[paste0("team2_", RAW_STATS)])
names(long1)[-(1:3)] <- RAW_STATS
names(long2)[-(1:3)] <- RAW_STATS
long <- rbind(long1, long2)
long <- long[order(long$team, long$date), ]

for (s in RAW_STATS) {
  long[[paste0("roll5_", s)]] <- ave(long[[s]], long$team,
                                      FUN = function(x) roll_mean_past(x, 5))
}

long$key <- paste(long$match_id, long$team, sep = "_")
raw$team1_key <- paste(raw$match_id, raw$team1, sep = "_")
raw$team2_key <- paste(raw$match_id, raw$team2, sep = "_")
idx1 <- match(raw$team1_key, long$key)
idx2 <- match(raw$team2_key, long$key)

for (s in RAW_STATS) {
  roll_col <- paste0("roll5_", s)
  diff_col <- paste0("diff_roll5_", s)
  raw[[diff_col]] <- long[[roll_col]][idx1] - long[[roll_col]][idx2]
}

feature_cols <- paste0("diff_roll5_", RAW_STATS)

before_n <- nrow(raw)
match_data <- raw[stats::complete.cases(raw[, feature_cols]), ]
after_n <- nrow(match_data)
cat(sprintf("Removed %d rows with missing values or <5 prior games (%d -> %d)\n",
            before_n - after_n, before_n, after_n))

# =============================================================================
# Table 1: Description of Derived Features
# =============================================================================
feature_table <- data.frame(
  Variable = feature_cols,
  Description = c(
    "Average ADR of team1 minus the average ADR of team2 over past 5 games",
    "Average assists of team1 minus the average assists of team2 over past 5 games",
    "Average clutches won of team1 minus the average clutches won of team2 over past 5 games",
    "Average deaths of team1 minus the average deaths of team2 over past 5 games",
    "Average KAST of team1 minus the average KAST of team2 over past 5 games",
    "Average kills of team1 minus the average kills of team2 over past 5 games",
    "Average multikill rounds of team1 minus the average multikill rounds of team2 over past 5 games",
    "Average opening deaths of team1 minus the average opening deaths of team2 over past 5 games",
    "Average opening kills of team1 minus the average opening kills of team2 over past 5 games",
    "Average rating of team1's highest-rated player minus the average rating of team2's highest-rated player over past 5 games",
    "Average swing percentage of team1 minus the average swing percentage of team2 over past 5 games"
  )
)
print(feature_table, row.names = FALSE)

# =============================================================================
# 4. Data Exploration
# =============================================================================

# --- Figure 1 / Table 2: distribution of diff_roll5_rating_3
hist(match_data$diff_roll5_rating_3, freq = FALSE,
     main = "", xlab = "diff_roll5_rating_3", col = "grey85")

table2 <- data.frame(
  ratingdiff_mean = mean(match_data$diff_roll5_rating_3),
  ratingdiff_sd   = sd(match_data$diff_roll5_rating_3),
  ratingdiff_min  = min(match_data$diff_roll5_rating_3),
  ratingdiff_max  = max(match_data$diff_roll5_rating_3)
)
print(round(table2, 3), row.names = FALSE)

# --- Figure 2 / Table 3: distribution of diff_roll5_swing_pct
hist(match_data$diff_roll5_swing_pct, freq = FALSE,
     main = "", xlab = "diff_roll5_swing_pct", col = "grey85")

table3 <- data.frame(
  swingdiff_mean = mean(match_data$diff_roll5_swing_pct),
  swingdiff_sd   = sd(match_data$diff_roll5_swing_pct),
  swingdiff_min  = min(match_data$diff_roll5_swing_pct),
  swingdiff_max  = max(match_data$diff_roll5_swing_pct)
)
print(round(table3, 3), row.names = FALSE)

# --- Figure 2.5: class balance of the outcome variable
outcome_counts <- table(factor(match_data$team1_win, levels = c(1, 0),
                                labels = c("Team 1 Win", "Team 2 Win")))
barplot(outcome_counts, col = c("firebrick3", "steelblue3"),
        ylab = "Count of Wins", xlab = "Outcome")
print(outcome_counts)
cat(sprintf("Team 1 win share: %.1f%%\n", 100 * prop.table(outcome_counts)[1]))

# =============================================================================
# 5. Modeling
# 5.3 Model 1: Logistic Regression
# =============================================================================

# chronological 75/25 split -- test on the most recent 25% of matches
match_data <- match_data[order(match_data$date), ]
split_idx <- floor(0.75 * nrow(match_data))
train <- match_data[seq_len(split_idx), ]
test  <- match_data[(split_idx + 1):nrow(match_data), ]

model1 <- glm(
  team1_win ~ diff_roll5_adr + diff_roll5_assists + diff_roll5_clutches_won +
    diff_roll5_deaths + diff_roll5_kast_pct + diff_roll5_kills +
    diff_roll5_multi_kill_rounds + diff_roll5_opening_deaths +
    diff_roll5_opening_kills + diff_roll5_rating_3 + diff_roll5_swing_pct,
  data = train, family = binomial
)

# --- Table 4: Regression Model Coefficients
table4 <- round(summary(model1)$coefficients, 6)
print(table4)

# --- predict on the held-out (future) test set
test$prob_team1_win <- predict(model1, newdata = test, type = "response")
pred_class   <- factor(ifelse(test$prob_team1_win > 0.5, "Win", "Lose"),
                        levels = c("Lose", "Win"))
actual_class <- factor(ifelse(test$team1_win == 1, "Win", "Lose"),
                        levels = c("Lose", "Win"))

# --- Table 5 / Table 6: confusion matrix + performance statistics
# (hand-rolled equivalent of caret::confusionMatrix(), positive = "Win")
confusion_summary <- function(pred, actual, positive = "Win") {
  tab <- table(Prediction = pred, Reference = actual)
  TP <- tab["Win", "Win"]; TN <- tab["Lose", "Lose"]
  FP <- tab["Win", "Lose"]; FN <- tab["Lose", "Win"]
  n <- sum(tab)

  accuracy <- (TP + TN) / n
  ci <- binom.test(TP + TN, n)$conf.int
  nir <- max(sum(actual == "Win"), sum(actual == "Lose")) / n
  p_acc_gt_nir <- binom.test(TP + TN, n, p = nir, alternative = "greater")$p.value
  p_e <- (sum(pred == "Win") * sum(actual == "Win") +
            sum(pred == "Lose") * sum(actual == "Lose")) / n^2
  kappa <- (accuracy - p_e) / (1 - p_e)
  mcnemar_p <- mcnemar.test(tab)$p.value
  sensitivity <- TP / (TP + FN)
  specificity <- TN / (TN + FP)

  list(
    table = tab,
    stats = c(
      Accuracy = accuracy, `95% CI lower` = ci[1], `95% CI upper` = ci[2],
      `No Information Rate` = nir, `P-Value [Acc > NIR]` = p_acc_gt_nir,
      Kappa = kappa, `Mcnemar's Test P-Value` = mcnemar_p,
      Sensitivity = sensitivity, Specificity = specificity,
      `Pos Pred Value` = TP / (TP + FP), `Neg Pred Value` = TN / (TN + FN),
      Prevalence = (TP + FN) / n, `Detection Rate` = TP / n,
      `Detection Prevalence` = (TP + FP) / n,
      `Balanced Accuracy` = (sensitivity + specificity) / 2
    )
  )
}

cm <- confusion_summary(pred_class, actual_class, positive = "Win")
cat("\nTable 5: Model Confusion Matrix\n"); print(cm$table)
cat("\nTable 6: Model Performance Statistics\n"); print(round(cm$stats, 4))

# --- ROC curve + AUC (hand-rolled, no pROC dependency)
thresholds <- seq(0, 1, by = 0.01)
roc_pts <- t(sapply(thresholds, function(th) {
  pc <- ifelse(test$prob_team1_win > th, 1, 0)
  tp <- sum(pc == 1 & test$team1_win == 1); fp <- sum(pc == 1 & test$team1_win == 0)
  fn <- sum(pc == 0 & test$team1_win == 1); tn <- sum(pc == 0 & test$team1_win == 0)
  c(fpr = fp / (fp + tn), tpr = tp / (tp + fn))
}))
roc_pts <- roc_pts[order(roc_pts[, "fpr"]), ]
auc <- sum(diff(roc_pts[, "fpr"]) *
             (roc_pts[-nrow(roc_pts), "tpr"] + roc_pts[-1, "tpr"]) / 2)

plot(roc_pts[, "fpr"], roc_pts[, "tpr"], type = "l", lwd = 2,
     xlab = "False Positive Rate", ylab = "True Positive Rate",
     main = sprintf("ROC Curve (AUC = %.3f)", auc))
abline(0, 1, lty = 2, col = "grey50")
