
#!/bin/bash
cd /Users/richie/Projects/LejuTV
echo "确定要更新代码吗?"
select yn in "Yes" "No"; do
  case $yn in
    Yes )  git fetch --all && git reset --hard origin/master && git pull;;
    No ) osascript -e 'tell application "Terminal" to close first window' & exit;;
  esac
done
