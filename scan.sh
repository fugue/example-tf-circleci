#!/bin/sh

# Check for deprecated env vars and use them if present, but print note
if [ ! -z "$FUGUE_CLIENT_ID" ] || [ ! -z "$FUGUE_CLIENT_SECRET" ]; then
   printf "\nFUGUE_CLIENT_ID and FUGUE_CLIENT_SECRET are deprecated and will be removed in a future release. Please use FUGUE_API_ID and FUGUE_API_SECRET instead.\n"
   export FUGUE_API_ID=$FUGUE_CLIENT_ID
   export FUGUE_API_SECRET=$FUGUE_CLIENT_SECRET
fi

# If required credentials are not detected, print error and exit
if [ -z "$FUGUE_API_ID" ] || [ -z "$FUGUE_API_SECRET" ]; then
   printf "\nError: No credentials detected. Please set the FUGUE_API_ID and FUGUE_API_SECRET credentials.\n"
   exit 1
fi

echo "Initiating Fugue scan..."

# Scan environment and redirect output
fugue scan $FUGUE_ENV_ID --wait --output json | jq '.' > scan_results.json

# Set scan ID env var
SCAN_ID=$(jq -r '.id' scan_results.json)

# Set noncompliant resources env var
NONCOMPLIANT=$(jq -r '.resource_summary.noncompliant' scan_results.json)

# Set scan status env var
SCAN_STATUS=$(jq -r '.status' scan_results.json)

# Print results
cat scan_results.json | jq '.'

# If scan succeeds and any resources are noncompliant, get compliance by resource type, redirect output, and print noncompliant resources
if [ "$SCAN_STATUS" == "SUCCESS" ] && [ "$NONCOMPLIANT" != "0" ]; then
   fugue get compliance-by-resource-types $SCAN_ID --output json > scan_results_noncompliant.json
   printf "\nScan completed. Found $NONCOMPLIANT NONCOMPLIANT resource(s):\n\n"
   cat scan_results_noncompliant.json | jq -r '.items[].noncompliant[].resource_id'

   # Update baseline with scan ID
   printf "\nUpdating baseline with scan ID $SCAN_ID..."
   fugue update env $FUGUE_ENV_ID --baseline-id $SCAN_ID --output json > update_baseline.json
   BASELINE_ID=$(jq -r '.baseline_id' update_baseline.json)

   if [ "$BASELINE_ID" == "$SCAN_ID" ]; then
      printf "\nBaseline has been updated."

   else
      printf "\nError updating baseline."

   fi

   printf "\nBuild failed. See scan_results_noncompliant.json for details."
   exit 1

# If scan succeeds and all resources are compliant, print compliance message, update baseline with scan ID
elif [ "$SCAN_STATUS" == "SUCCESS" ] && [ "$NONCOMPLIANT" == "0" ]; then
   printf "\nScan completed. All resources are compliant."
   printf "\nUpdating baseline with scan ID $SCAN_ID..."
   fugue update env $FUGUE_ENV_ID --baseline-id $SCAN_ID --output json > update_baseline.json
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