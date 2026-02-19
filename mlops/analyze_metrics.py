#!/usr/bin/env python3
"""
Analyze and manipulate MLflow metrics from API runs.
Shows how to query, filter, and compare experiment data.
"""

import os
import mlflow
import pandas as pd

# Set MLflow tracking URI (defaults to ./mlruns for local file store)
mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "file:./mlruns")
mlflow.set_tracking_uri(mlflow_uri)


def get_experiment_runs(experiment_name: str = "llmops-api"):
    """Fetch all runs from an experiment."""
    try:
        exp = mlflow.get_experiment_by_name(experiment_name)
        if not exp:
            print(f"❌ Experiment '{experiment_name}' not found")
            return None
        
        # Get all runs from this experiment
        runs = mlflow.search_runs(experiment_ids=[exp.experiment_id])
        return runs
    except Exception as e:
        print(f"❌ Error fetching experiments: {e}")
        return None


def display_run_metrics():
    """Display a summary of all run metrics."""
    runs = get_experiment_runs()
    if runs is None or runs.empty:
        print("No runs found. Run 'make test-chats' to generate data.")
        return
    
    print("\n📊 MLflow Run Summary")
    print("=" * 80)
    print(f"Total runs: {len(runs)}\n")
    
    # Display each run with key metrics
    for idx, run in runs.iterrows():
        run_id = run["run_id"]
        run_name = run.get("tags.mlflow.runName", "chat-request")
        
        # Extract metrics
        latency = run.get("metrics.latency_ms")
        success = run.get("metrics.success")
        input_tokens = run.get("metrics.input_tokens")
        output_tokens = run.get("metrics.output_tokens")
        tps = run.get("metrics.tokens_per_second")
        
        status = "✅" if success == 1.0 else "❌"
        print(f"{status} Run {idx+1}: {run_name}")
        print(f"   Input tokens:  {input_tokens:.0f}")
        print(f"   Output tokens: {output_tokens:.0f}")
        print(f"   Total tokens:  {input_tokens + output_tokens:.0f}")
        print(f"   Latency:       {latency:.0f}ms")
        print(f"   Throughput:    {tps:.2f} tokens/sec")
        print(f"   Run ID:        {run_id[:8]}")
        print()


def compare_temperature():
    """Compare metrics across different temperature settings."""
    runs = get_experiment_runs()
    if runs is None or runs.empty:
        return
    
    print("\n🌡️  Temperature Impact Analysis")
    print("=" * 80)
    
    # Group by temperature parameter
    temps = {}
    for idx, run in runs.iterrows():
        temp = run.get("params.temperature")
        if temp is None:
            continue
        
        if temp not in temps:
            temps[temp] = []
        
        temps[temp].append({
            "latency_ms": run.get("metrics.latency_ms"),
            "output_tokens": run.get("metrics.output_tokens"),
            "tps": run.get("metrics.tokens_per_second"),
        })
    
    print(f"\nTested temperatures: {sorted(temps.keys())}\n")
    
    for temp in sorted(temps.keys()):
        runs_at_temp = temps[temp]
        avg_latency = sum(r["latency_ms"] for r in runs_at_temp) / len(runs_at_temp)
        avg_output = sum(r["output_tokens"] for r in runs_at_temp) / len(runs_at_temp)
        avg_tps = sum(r["tps"] for r in runs_at_temp) / len(runs_at_temp)
        
        print(f"Temperature: {temp}")
        print(f"  Avg latency:  {avg_latency:.0f}ms")
        print(f"  Avg output:   {avg_output:.0f} tokens")
        print(f"  Avg throughput: {avg_tps:.2f} tokens/sec")
        print()


def get_aggregate_stats():
    """Compute aggregate statistics across all runs."""
    runs = get_experiment_runs()
    if runs is None or runs.empty:
        return
    
    print("\n📈 Aggregate Statistics")
    print("=" * 80)
    
    # Filter successful runs only
    successful = runs[runs["metrics.success"] == 1.0]
    
    if successful.empty:
        print("No successful runs found.")
        return
    
    latencies = successful["metrics.latency_ms"].dropna()
    outputs = successful["metrics.output_tokens"].dropna()
    tpss = successful["metrics.tokens_per_second"].dropna()
    
    print(f"\nBased on {len(successful)} successful runs:\n")
    
    print("Latency (ms):")
    print(f"  Mean:   {latencies.mean():.0f}ms")
    print(f"  Median: {latencies.median():.0f}ms")
    print(f"  Min:    {latencies.min():.0f}ms")
    print(f"  Max:    {latencies.max():.0f}ms")
    
    print("\nOutput tokens:")
    print(f"  Mean:   {outputs.mean():.0f}")
    print(f"  Median: {outputs.median():.0f}")
    print(f"  Min:    {outputs.min():.0f}")
    print(f"  Max:    {outputs.max():.0f}")
    
    print("\nThroughput (tokens/sec):")
    print(f"  Mean:   {tpss.mean():.2f}")
    print(f"  Median: {tpss.median():.2f}")
    print(f"  Min:    {tpss.min():.2f}")
    print(f"  Max:    {tpss.max():.2f}")
    print()


def export_to_csv():
    """Export runs to CSV for further analysis."""
    runs = get_experiment_runs()
    if runs is None or runs.empty:
        return
    
    # Select relevant columns
    export_cols = [
        "run_id",
        "metrics.latency_ms",
        "metrics.latency_sec", 
        "metrics.success",
        "metrics.input_tokens",
        "metrics.output_tokens",
        "metrics.total_tokens",
        "metrics.tokens_per_second",
        "params.temperature",
        "params.model",
    ]
    
    df = runs[[col for col in export_cols if col in runs.columns]].copy()
    df.columns = [col.replace("metrics.", "").replace("params.", "") for col in df.columns]
    
    csv_path = "./mlruns/runs_export.csv"
    df.to_csv(csv_path, index=False)
    print(f"\n✅ Exported {len(df)} runs to {csv_path}")


if __name__ == "__main__":
    print("\n🔍 MLflow Metrics Analysis Tool")
    print("=" * 80)
    
    display_run_metrics()
    compare_temperature()
    get_aggregate_stats()
    export_to_csv()
    
    print("\n💡 Tip: Open MLflow UI to visualize: make mlflow-ui")
    print("   Then browse http://127.0.0.1:5000\n")
