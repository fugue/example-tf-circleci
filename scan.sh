#!/bin/sh

echo "Initiating Fugue scan..."
curl -s -X POST https://api.riskmanager.fugue.co/v0/scans?environment_id=$FUGUE_ENV_ID \
   -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET | jq '.' > scaninfo.json 

SCAN_ID=$(jq -r '.id' scaninfo.json)

echo "Fugue is now scanning your environment. Scan ID:"
echo $SCAN_ID

while [ "$(curl -s -X GET https://api.riskmanager.fugue.co/v0/scans/$SCAN_ID -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET | jq --raw-output '.status')" == "IN_PROGRESS" ]; do
  printf "Scan in progress...\n"
  sleep 15
done

curl -s -X GET https://api.riskmanager.fugue.co/v0/scans/$SCAN_ID -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET > scan_results.json

NONCOMPLIANT=$(jq -r '.resource_summary.noncompliant' scan_results.json)

SCAN_STATUS=$(jq -r '.status' scan_results.json)

cat scan_results.json | jq '.'

if [ "$SCAN_STATUS" == "SUCCESS" ] && [ "$NONCOMPLIANT" != "0" ]; then
   curl -s -X GET https://api.riskmanager.fugue.co/v0/scans/$SCAN_ID/compliance_by_resource_types -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET > scan_results_noncompliant.json
   printf "\nScan completed. Found $NONCOMPLIANT NONCOMPLIANT resource(s):\n\n"
   cat scan_results_noncompliant.json | jq -r '.items[].noncompliant[].resource_id'

   printf "\nUpdating baseline with scan ID $SCAN_ID..."
   curl -s -X PATCH https://api.riskmanager.fugue.co/v0/environments/$FUGUE_ENV_ID -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET --data '{ "baseline_id": "'"$SCAN_ID"'" }' > update_baseline.json
   BASELINE_ID=$(jq -r '.baseline_id' update_baseline.json)

   if [ "$BASELINE_ID" == "$SCAN_ID" ]; then
      printf "\nBaseline has been updated."

   else
      printf "\nError updating baseline."

   fi

   printf "\nBuild failed. See scan_results_noncompliant.json for details."
   exit 1

elif [ "$SCAN_STATUS" == "SUCCESS" ] && [ "$NONCOMPLIANT" == "0" ]; then
   printf "\nScan completed. All resources are compliant."
   printf "\nUpdating baseline with scan ID $SCAN_ID..."
   curl -s -X PATCH https://api.riskmanager.fugue.co/v0/environments/$FUGUE_ENV_ID -u $FUGUE_CLIENT_ID:$FUGUE_CLIENT_SECRET --data '{ "baseline_id": "'"$SCAN_ID"'" }' > update_baseline.json
   BASELINE_ID=$(jq -r '.baseline_id' update_baseline.json)

   if [ "$BASELINE_ID" == "$SCAN_ID" ]; then
      printf "\nBaseline has been updated."

   else
      printf "\nError updating baseline. Build failed."
      exit 1

   fi

else
   printf "\nScan error. Build failed. Baseline has not been updated."
   exit 1
fi