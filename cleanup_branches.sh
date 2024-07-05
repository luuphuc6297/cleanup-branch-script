#!/bin/bash

PROTECTED_BRANCHES=("main" "product" "develop" "rc/1.70.0" "rc/1.70.1" "rc/1.70.2" "rc/1.69.*")
# GITHUB_TOKEN="token"
REPO="luuphuc6297/cleanup-branches"
THREE_MONTHS_AGO=$(date --date='2 weeks ago' +%s)

# Fetch all branches
git fetch --all

set_branch_protection() {
    local branch=$1
    local repo=$2
    local token=$3

    local data='{
      "required_status_checks": null,
      "enforce_admins": true,
      "required_pull_request_reviews": {
        "dismiss_stale_reviews": true,
        "require_code_owner_reviews": false
      },
      "restrictions": null
    }'

    curl -X PUT -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.luke-cage-preview+json" \
        -d "$data" \
        "https://api.github.com/repos/$repo/branches/${branch#origin/}/protection"
}

# Function to get the last updated date of remote branch PRs
get_last_updated_date_and_status() {
    local branch=$1
    local repo=$2
    local token=$3

    local prs=$(curl -s -H "Authorization: token $token" \
        "https://api.github.com/repos/$repo/pulls?state=all&head=$repo:${branch#origin/}")
    local last_updated=$(echo "$prs" | jq -r '[.[] | select(.state == "closed" and .merged_at != null) | .updated_at] | max')
    local has_closed_merged_prs=$(echo "$prs" | jq -r '[.[] | select(.state == "closed" and .merged_at != null)] | length')

    echo "$last_updated $has_closed_merged_prs"
}

# Protect and backup important branches
for branch in "${PROTECTED_BRANCHES[@]}"; do
    if git rev-parse --verify $branch >/dev/null 2>&1; then
        set_branch_protection $branch $REPO $GITHUB_TOKEN
        git checkout $branch
        git tag backup/$(date +%Y%m%d)-${branch#origin/}
        git push origin backup/$(date +%Y%m%d)-${branch#origin/}
    else
        echo "Branch $branch does not exist."
    fi
done

git for-each-ref refs/remotes --format='%(refname:short)' | while read branch; do
    branch_name=${branch#origin/}
    if [[ ! " ${PROTECTED_BRANCHES[@]} " =~ " $branch_name " ]]; then
        read last_updated has_closed_merged_prs < <(get_last_updated_date_and_status $branch $REPO $GITHUB_TOKEN)
        if [[ "$has_closed_merged_prs" -gt 0 && $(date --date="$last_updated" +%s) -lt $THREE_MONTHS_AGO ]]; then
            echo "Deleting $branch_name as it has closed, merged PRs last updated on $last_updated"
            git push origin --delete $branch_name
        elif [[ "$last_updated" == "null" || -z "$last_updated" ]]; then
            echo "$branch_name has no updates or pull requests and will not be deleted."
        elif [[ $(git log -1 --since="6 months ago" --branches="$branch" --format="%H") == "" ]]; then
            echo "Deleting $branch_name as it has no recent updates and no pull requests."
            git push origin --delete $branch_name
        fi
    fi
done

# Print branches to delete
echo "Branches that will be deleted:"
printf '%s\n' "${branches_to_delete[@]}"
