#!/bin/bash

# ==============================================================================
# add_weekday_commits.sh
# A lancer depuis la racine de contributions-history
# Ajoute 20-50 commits en semaine pour chaque année 2014-2019
# ==============================================================================

set -e

add_days() {
  local date=$1
  local n=$2
  date -j -v+${n}d -f "%Y-%m-%d" "$date" +%Y-%m-%d
}

make_commit() {
  local date=$1
  local hour=$2
  local min=$3
  local idx=$4
  local timestamp="${date}T$(printf '%02d' $hour):$(printf '%02d' $min):00"

  echo "[$timestamp] weekday $idx" >> activity.log
  git add activity.log

  GIT_AUTHOR_DATE="$timestamp" \
  GIT_COMMITTER_DATE="$timestamp" \
  git commit -q -m "chore: activity update $idx"
}

add_weekday_commits() {
  local label=$1
  local target=$2
  local start=$3
  local end=$4

  echo ""
  echo ">>> $label — $target commits en semaine ($start -> $end)"

  # Collecter les jours de semaine (lun-ven)
  local days_arr=()
  local cur="$start"
  while [[ "$cur" < "$end" || "$cur" == "$end" ]]; do
    local dow
    dow=$(date -j -f "%Y-%m-%d" "$cur" +%u)
    [[ "$dow" -le 5 ]] && days_arr+=("$cur")
    cur=$(add_days "$cur" 1)
  done

  local nb_days=${#days_arr[@]}
  local counts_arr=()
  for (( i=0; i<nb_days; i++ )); do
    counts_arr+=(0)
  done

  # Distribuer les commits (max 2 par jour en semaine, plus discret)
  local commits_done=0
  local max_attempts=$(( target * 20 ))
  local attempts=0
  while [[ $commits_done -lt $target && $attempts -lt $max_attempts ]]; do
    local r=$(( RANDOM % nb_days ))
    if [[ ${counts_arr[$r]} -lt 2 ]]; then
      counts_arr[$r]=$(( counts_arr[$r] + 1 ))
      (( commits_done++ ))
    fi
    (( attempts++ ))
  done

  # Créer les commits
  local idx=0
  for (( i=0; i<nb_days; i++ )); do
    local count=${counts_arr[$i]}
    [[ "$count" -eq 0 ]] && continue
    local d="${days_arr[$i]}"
    for (( c=1; c<=count; c++ )); do
      local hour=$(( RANDOM % 10 + 9 ))  # 9h-18h, heures de bureau
      local min=$(( RANDOM % 60 ))
      (( idx++ ))
      make_commit "$d" "$hour" "$min" "$idx"
    done
  done

  echo "    OK - $idx commits ajoutés pour $label"
}

# ==============================================================================
# VÉRIFICATION
# ==============================================================================

if [[ ! -d ".git" ]]; then
  echo "Erreur : lance ce script depuis la racine du repo contributions-history"
  exit 1
fi

# ==============================================================================
# AJOUT DES COMMITS DE SEMAINE — cibles aléatoires entre 20 et 50
# ==============================================================================

add_weekday_commits "2014" $(( 20 + RANDOM % 31 )) "2014-01-01" "2014-12-31"
add_weekday_commits "2015" $(( 20 + RANDOM % 31 )) "2015-01-01" "2015-12-31"
add_weekday_commits "2016" $(( 20 + RANDOM % 31 )) "2016-01-01" "2016-12-31"
add_weekday_commits "2017" $(( 20 + RANDOM % 31 )) "2017-01-01" "2017-12-31"
add_weekday_commits "2018" $(( 20 + RANDOM % 31 )) "2018-01-01" "2018-12-31"
add_weekday_commits "2019" $(( 20 + RANDOM % 31 )) "2019-01-01" "2019-12-31"

# ==============================================================================
# PUSH
# ==============================================================================

echo ""
echo "======================================================"
echo " Commits ajoutés ! Pour pousser :"
echo "   git push"
echo "======================================================"