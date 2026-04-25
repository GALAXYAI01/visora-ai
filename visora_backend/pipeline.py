from langgraph.graph import StateGraph, END
from models.state import AuditState
from agents.data_profiler import data_profiler_agent
from agents.bias_detector import bias_detector_agent
from agents.explainer     import explainer_agent
from agents.remediator    import remediator_agent
from agents.report_gen    import report_gen_agent


def build_pipeline() -> StateGraph:
    graph = StateGraph(AuditState)

    graph.add_node("DataProfiler", data_profiler_agent)
    graph.add_node("BiasDetector", bias_detector_agent)
    graph.add_node("Explainer",    explainer_agent)
    graph.add_node("Remediator",   remediator_agent)
    graph.add_node("ReportGen",    report_gen_agent)

    graph.set_entry_point("DataProfiler")
    graph.add_edge("DataProfiler", "BiasDetector")
    graph.add_edge("BiasDetector", "Explainer")
    graph.add_edge("Explainer",    "Remediator")
    graph.add_edge("Remediator",   "ReportGen")
    graph.add_edge("ReportGen",    END)

    return graph.compile()


# Singleton — compile once
pipeline = build_pipeline()
