#!/usr/bin/env bash

# ==== CONFIG ====
INSTANCE_NAME="wgcna-analysis-sp-jul2025"
SSH_NAME="spandan_pandya@wgcna-analysis-sp-jul2025"
ZONE="us-central1-f"
PROJECT_ID="carbide-eye-418200"
REMOTE_PROJECT_DIR="/home/spandan_pandya/Differential-expression-and-WGCNA-analysis-of-GSE21933"
DOCKER_IMAGE="wgcna"
DATASET="GSE21933"
SOFT_POWER=10
BRANCH="main"  # or dev, etc.
COMMIT_MSG="Auto-commit: WGCNA output for $DATASET on $(date)"

# ==== STEP 1: Start the GCP VM ====
start=$(date +%s)

echo "Starting GCP instance..."
gcloud compute instances start "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID"

# Wait a few seconds
sleep 10

echo "Waiting for SSH to become available..."

until gcloud compute ssh "$SSH_NAME" --zone "$ZONE" --project "$PROJECT_ID" --command "echo 'SSH ready'" &>/dev/null; do
  echo "  ...still waiting for SSH access"
  sleep 5
done

echo "SSH is ready. Continuing..."

# ==== STEP 2: Push latest code from local to GitHub ====
# echo "Pushing local changes to GitHub..."
# git add script/  # or specific files
# find outputs -name "hub_*.txt" -exec git add {} +
# git commit -m "Auto-sync before GCP run: $(date)"
# git push origin "$BRANCH"

# ==== STEP 3: SSH into VM and run the Docker analysis ====
echo "Running Docker container remotely..."

gcloud compute ssh "$SSH_NAME" --zone "$ZONE" --project "$PROJECT_ID" << EOF
echo "SSH into the system...Yay!!"
cd "$REMOTE_PROJECT_DIR"
echo "Pulling latest code..."
git pull origin $BRANCH

echo "Cleaning up temp files..."
rm -rf outputs/*_files/ script/build.log

echo "Starting Docker container..."
docker run --rm \
  -v "$REMOTE_PROJECT_DIR:/home/rstudio/WGCNA" \
  -w /home/rstudio/WGCNA/script \
  "$DOCKER_IMAGE" \
  Rscript run_wgcna_analysis.R "$DATASET" "$SOFT_POWER"

echo "Staging results..."
find outputs -name "*.html" -exec git add {} +
find outputs -name "hub_*.txt" -exec git add {} +
find outputs -name "universe_WGCNA.txt" -exec git add {} +
[ -d figures ] && git add figures/

echo "Committing if changes exist..."
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MSG"
  git push origin $BRANCH
  echo "Changes pushed!"
fi
EOF

# ==== STEP 4: Shut down the GCP VM ====
echo "Stopping GCP instance..."
gcloud compute instances stop "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID"

echo "All done"

end=$(date +%s)
runtime=$((end - start))
echo "Elapsed time: $(($runtime / 60)) minutes and $(($runtime % 60)) seconds."
