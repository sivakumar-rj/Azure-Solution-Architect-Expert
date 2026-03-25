#!/bin/bash

# Create placeholder files for all labs
for i in {01..26}; do
  case $i in
    01) title="Virtual-Machine" ;;
    02) title="App-Service" ;;
    03) title="Storage-Account" ;;
    04) title="Azure-Files" ;;
    05) title="Docker-Basics" ;;
    06) title="AKS-Deployment" ;;
    07) title="AKS-Advanced" ;;
    08) title="Azure-SQL" ;;
    09) title="MySQL-Database" ;;
    10) title="Cosmos-DB" ;;
    11) title="Virtual-Network" ;;
    12) title="Load-Balancer" ;;
    13) title="Application-Gateway" ;;
    14) title="Azure-CDN" ;;
    15) title="Azure-DevOps-Setup" ;;
    16) title="CICD-Pipeline" ;;
    17) title="Deployment-Strategies" ;;
    18) title="Azure-AD" ;;
    19) title="Key-Vault" ;;
    20) title="Network-Security" ;;
    21) title="Azure-Monitor" ;;
    22) title="Log-Analytics" ;;
    23) title="Application-Insights" ;;
    24) title="Three-Tier-App" ;;
    25) title="Microservices-Architecture" ;;
    26) title="Disaster-Recovery" ;;
  esac
  
  echo "# Lab $i: ${title//-/ }" > "Lab-$i-$title.md"
  echo "" >> "Lab-$i-$title.md"
  echo "**Last Updated: March 2026**" >> "Lab-$i-$title.md"
  echo "**© Copyright Sivakumar J**" >> "Lab-$i-$title.md"
  echo "" >> "Lab-$i-$title.md"
  echo "---" >> "Lab-$i-$title.md"
  echo "" >> "Lab-$i-$title.md"
  echo "*Content coming soon...*" >> "Lab-$i-$title.md"
done

echo "Created $(ls Lab-*.md | wc -l) lab files"
