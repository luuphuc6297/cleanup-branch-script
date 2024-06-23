#!/bin/bash

# Cài đặt các branch quan trọng
PROTECTED_BRANCHES="master develop"
# Ngày hiện tại và giới hạn 3 tháng trước
current_date=$(date +%s)
three_months_ago=$(date --date='3 months ago' +%s)

# Backup các branch quan trọng
for branch in $PROTECTED_BRANCHES; do
    git checkout $branch
    git tag backup/$(date +%Y%m%d)-$branch
    git push origin backup/$(date +%Y%m%d)-$branch
done

# Xóa các branch theo mẫu nhất định và kiểm tra ngày tạo
for pattern in fix/OSW-17*** fix/OSW-18*** feat/OSW-17** feat/osw-17** feat/osw-18** feature/OSW-17** feature/OSW-18**; do
    # Lấy tất cả các branch từ remote, kiểm tra ngày tạo
    git for-each-ref --sort=-committerdate refs/remotes --format='%(refname:short) %(committerdate:unix)' | grep $pattern | while read branch commit_date; do
        branch_name=${branch##*/}
        if [[ ! " $PROTECTED_BRANCHES " =~ " $branch_name " ]] && [[ $commit_date -lt $three_months_ago ]]; then
            # Xóa branch nếu nó cũ hơn 3 tháng và không nằm trong danh sách bảo vệ
            git push origin --delete $branch_name
        fi
    done
done
