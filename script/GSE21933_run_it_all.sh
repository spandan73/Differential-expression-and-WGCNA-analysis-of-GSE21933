#!/usr/bin/env bash

# ==== CONFIG ====
INSTANCE_NAME="wgcna-analysis-sp-jul2025"
SSH_NAME="spandan_pandya@wgcna-analysis-sp-jul2025"
ZONE="us-central1-f"
PROJECT_ID="carbide-eye-418200"
REMOTE_PROJECT_DIR="/home/spandan_pandya/Differential-expression-and-WGCNA-analysis-of-GSE21933"
DOCKER_IMAGE="wgcna"
DATASET="GSE21933"
SOFT_POWER=15
BRANCH="main"  # or dev, etc.

# ==== STEP 1: Start the GCP VM ====
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
# git commit -m "Auto-sync before GCP run: $(date)"
# git push origin "$BRANCH"

# ==== STEP 3: SSH into VM and run the Docker analysis ====
echo "Running Docker container remotely..."

gcloud compute ssh "$SSH_NAME" --zone "$ZONE" --project "$PROJECT_ID" << EOF
echo "SSH into the system...Yay!!"
cd "$REMOTE_PROJECT_DIR"
echo "Pulling latest code..."
git pull origin $BRANCH
echo "Starting Docker container..."

docker run --rm \
  -v "$REMOTE_PROJECT_DIR:/home/rstudio/WGCNA" \
  -w /home/rstudio/WGCNA/script \
  "$DOCKER_IMAGE" \
  Rscript run_wgcna_analysis.R "$DATASET" "$SOFT_POWER"

echo "Committing results..."
git add outputs/ figures/
git commit -m "Auto-commit: WGCNA output for $DATASET on \$(date)"
git push origin $BRANCH
echo "Changes Pushed!"
EOF

# ==== STEP 4: Shut down the GCP VM ====
echo "Stopping GCP instance..."
gcloud compute instances stop "$INSTANCE_NAME" --zone "$ZONE" --project "$PROJECT_ID"

echo "All done"

