#!/bin/bash

# Khởi tạo số lượng branch và danh sách mẫu tên branch
num_branches=200
declare -a patterns=("feat/OSW-" "feature/OSW-" "hotfix/OSW-")

# Vòng lặp tạo các branch
for ((i=1; i<=num_branches; i++)); do
    # Chọn một mẫu ngẫu nhiên từ mảng các mẫu
    pattern=${patterns[$RANDOM % ${#patterns[@]}]}
    # Tạo một số ngẫu nhiên cho tên branch
    number=$RANDOM
    # Tạo tên branch
    branch_name="${pattern}${number}"
    # Tính toán ngày tạo ngẫu nhiên từ 1 đến 730 ngày trước
    days_ago=$(($RANDOM % 730 + 1))
    commit_date=$(date --date="$days_ago days ago" +%Y-%m-%dT%H:%M:%S)

    # Checkout tạo branch mới
    git checkout -b $branch_name
    # Tạo commit với ngày đã tính
    GIT_COMMITTER_DATE="$commit_date" GIT_AUTHOR_DATE="$commit_date" git commit --allow-empty -m "Initial commit for $branch_name"
    # Quay về branch chính
    git checkout master
done

echo "Created $num_branches branches."
