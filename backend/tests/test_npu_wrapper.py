from retrieval.qai_hub_wrapper import QAIHubWrapper

def test_qai_hub_wrapper_default_cpu_fallback():
    wrapper = QAIHubWrapper()
    status = wrapper.get_npu_status()
    
    assert "target_device" in status
    assert status["target_device"] == "Snapdragon X Elite Compute Spot"
    assert "latency_ms" in status
    assert status["latency_ms"] > 0
    assert "hexagon_npu_acceleration" in status

def test_qai_hub_wrapper_profile():
    wrapper = QAIHubWrapper()
    profile = wrapper.profile_on_device("all-MiniLM-L6-v2")
    
    assert profile["model_name"] == "all-MiniLM-L6-v2"
    assert "profiling_job" in profile
