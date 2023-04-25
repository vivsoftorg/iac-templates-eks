#! /bin/bash
git_branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
case $git_branch in
dev) branch="dev" ;;
qa) branch="qa" ;;
main | master) branch="prod" ;;
*)
    branch="prod" # Defaults to prod
    if [[ $git_branch =~ release.* ]]; then
        branch="qa"
    fi
    if [[ $git_branch =~ feat.* ]]; then
        branch="dev"
    fi
    ;;
esac
echo $branch
