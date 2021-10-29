library(targets)
library(tarchetypes) # for tar_render()
# pacman::p_load("dplyr", "ggplot2")
source("R/functions.R")
tar_option_set(packages = c("dplyr", "ggplot2"))

list(
  # 1. 指定したURLからデータをダウンロードする
  tar_target(
    file_download,
    download.file("https://www.e-stat.go.jp/stat-search/file-download?statInfId=000031502694&fileKind=1",
                  "data-raw/2015_mi040001.csv")
  ),
  # 2. ローカルのファイルの変更を検出可能にする
  # format = "file" にしておくとファイル内容の変更を検出して
  # ワークフローの再実行を判定する
  tar_target(
    raw_data_file,
    "data-raw/2015_mi040001.csv",
    format = "file"
  ),
  # 3. データファイルを読み込む
  tar_target(
    df_pops_raw,
    readr::read_csv(raw_data_file, 
                    skip = 10,
                    na = "\u3000\u3000\u3000\u3000\u3000 \u2026",
                    col_types = c("c",
                                  paste(rep("d", times = 19), collapse = "")),
                    locale = readr::locale(encoding = "cp932"))
  ),
  # 4. データ加工1: データの列名を変更し、特定の列への処理を加える
  tar_target(
    df_pops_mod,
    df_pops_raw %>% 
      purrr::set_names(c("area",
                         paste0("year_",
                                names(df_pops_raw)[-1]))) %>% 
      mutate(area = stringr::str_remove_all(area, "[[:space:]]") %>%
               stringi::stri_trans_nfkc())
  ),
  # 5. データ加工2: 都道府県コードと名前を複数の列に分ける
  tar_target(
    df_pops_prefecture,
    df_pops_mod %>% 
      filter(area != "全国") %>% 
      tidyr::extract(area,
                     into  = c("code", "prefecture"),
                     regex = "([0-9]+)(.+)")
  ),
  # 6. データ加工3: データを縦長に変形させる
  tar_target(
    df_pops_prefecture_long,
    df_pops_prefecture %>% 
      tidyr::pivot_longer(cols          = starts_with("year"),
                          names_to      = "year",
                          values_ptypes = list(value = double()),
                          names_prefix  = "year_",
                          values_to     = "population")
  ),
  # 7. 対象の地域を指定
  tar_target(
    prefs,
    c("徳島", "愛媛", "香川", "高知")
  ),
  # 8. グラフの作成
  # plotの呼び出しも可能
  # グラフの内容を変更して tar_make() --> 図が作り直される
  tar_target(
    filter_plots,
    df_pops_prefecture_long %>% 
      filter(prefecture == prefs) %>% 
      create_plot(color = prefecture, group = prefecture),
    pattern = map(prefs),
    iteration = "list"
  ),
  # 9. レポートの生成
  tar_render(
    report,
    "report.qmd"
  )
)
