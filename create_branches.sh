#!/bin/bash

num_branches=20
declare -a patterns=("feat/OSW-" "feature/OSW-" "hotfix/OSW-")

for ((i = 1; i <= num_branches; i++)); do
    pattern=${patterns[$RANDOM % ${#patterns[@]}]}
    number=$RANDOM
    branch_name="${pattern}${number}"
    months_ago=$(($RANDOM % 24 + 12))
    initial_commit_date=$(date --date="$months_ago months ago" +%Y-%m-%dT%H:%M:%S)

    git checkout -b $branch_name
    GIT_COMMITTER_DATE="$initial_commit_date" GIT_AUTHOR_DATE="$initial_commit_date" git commit --allow-empty -m "Initial commit for $branch_name"

    update_commit_date=$(date --date="6 months ago" +%Y-%m-%dT%H:%M:%S)
    GIT_COMMITTER_DATE="$update_commit_date" GIT_AUTHOR_DATE="$update_commit_date" git commit --allow-empty -m "Update commit for $branch_name"

    # Push branch lên remote
    git push origin $branch_name
    git checkout main
done

echo "Created $num_branches branches and pushed to remote."
