"""Minimal MLflow example using local file store by default.
Set env vars if you want remote tracking:
  export MLFLOW_TRACKING_URI=http://<your-server>:5000
  export MLFLOW_ARTIFACT_URI=azure-blob://<storage>/<container>
"""
import os, time, random
import mlflow

mlflow.set_experiment(os.getenv("MLFLOW_EXPERIMENT", "local-demo"))

with mlflow.start_run(run_name=f"demo-{int(time.time())}"):
    # Log params and metrics
    mlflow.log_param("model", os.getenv("MODEL", "llama3"))
    for step in range(10):
        mlflow.log_metric("loss", 1.0 / (step + 1), step=step)
        mlflow.log_metric("latency_ms", random.randint(50, 120), step=step)
    # Save a small artifact
    with open("metrics.txt", "w") as f:
        f.write("ok\n")
    mlflow.log_artifact("metrics.txt")
    print("Run logged. Check ./mlruns or your tracking server.")
