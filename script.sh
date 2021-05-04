#!/bin/bash

#read -p "BB DC Username    : " bbdcuser
#read -p "BB DC Token       : " bbdctoken
#read -p "BB DC Repo        : " bbdcrepo
#read -p "BC Cloud Username : " bbcuser
#read -p "BB Cloud Token    : " bbctoken
#read -p "BB Cloud Repo     : " bbcrepo

srepolink=$(echo $bbdcrepo | awk -F "https://" '{ print $2}')
git clone https://${srepolink}

fname=$(echo $bbdcrepo| awk -F "/"  '{ print $6}' | awk -F ".git" '{print $1}')
echo $fname
cd $fname

srepolink=$(echo $bbcrepo | sed "s/@/:{bbctoken}@/g")
git remote add -f gcloud $srepolink

git branch -a > branches
cat branches | tr -d "  " | tr -d "*" | sed s#remotes/##g > comparefile
arra=()
counta=0
arrb=()
countb=0
while read line || [ -n "$line" ]
do
        var="$line"
        if [[ $var == gcloud* ]]
        then
                arra[$counta]="$(echo $var | sed 's#gcloud/##g')"
                echo ${arra[$counta]} >> allbranches
                counta=$(($counta+1))

        fi

        if [[ $var == origin* ]]
        then
                arrb[$countb]="$(echo $var | sed 's#origin/##g' | sed 's/HEAD->//g')"
                #echo ${arrb[$countb]}
                countb=$(($countb+1))
        fi
done < "comparefile"

for i in ${arra[@]}
do
        brnor=$(echo "$i" | sed -e 's/\r//g')
        for j in ${arrb[@]}
        do
                if [[ $i == $j ]]
                then
                        echo $i >> updatedbranches
                        git checkout --track origin/${i}
                        git merge gcloud/${i} --allow-unrelated-histories
                fi
        done
done

comm -2 -3 <(sort allbranches) <(sort updatedbranches) > newbranches
while read line || [ -n "$line" ]
do
        git fetch gcloud $line:$line
done < "newbranches"
