library(targets)
# pacman::p_load("dplyr", "ggplot2")
source("R/functions.R")
tar_option_set(packages = c("dplyr"))

list(
  # format = "file" にしておくとファイル内容の変更を検出して
  # ワークフローの再実行を判定する
  tar_target(
    raw_data_file,
    "data-raw/2015_mi040001.csv",
    format = "file"
  ),
  tar_target(
    df_pops_raw,
    readr::read_csv(raw_data_file, 
                    skip = 10,
                    na = "\u3000\u3000\u3000\u3000\u3000 \u2026",
                    col_types = c("c",
                                  paste(rep("d", times = 19), collapse = "")),
                    locale = readr::locale(encoding = "cp932"))
  ),
  tar_target(
    df_pops_mod,
    df_pops_raw %>% 
      purrr::set_names(c("area",
                         paste0("year_",
                                names(df_pops_raw)[-1]))) %>% 
      mutate(area = stringr::str_remove_all(area, "[[:space:]]") %>%
               stringi::stri_trans_nfkc())
  ),
  tar_target(
    df_pops_prefecture,
    df_pops_mod %>% 
      filter(area != "全国") %>% 
      tidyr::extract(area,
                     into  = c("code", "prefecture"),
                     regex = "([0-9]+)(.+)")
  ),
  tar_target(
    df_pops_prefecture_long,
    df_pops_prefecture %>% 
      tidyr::pivot_longer(cols          = starts_with("year"),
                          names_to      = "year",
                          values_ptypes = list(value = double()),
                          names_prefix  = "year_",
                          values_to     = "population")
    ),
  # plotの呼び出しも可能
  tar_target(
    ts_plot_pref36,
    df_pops_prefecture_long %>% 
      filter(prefecture == "徳島") %>% 
      create_plot(),
    packages = c("dplyr", "ggplot2")
  )
)
