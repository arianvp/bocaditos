import json
import sys
from collections import defaultdict, deque


def parse_derivation_data(data_str):
    """Parse the derivation data from the input string."""
    derivations = []
    for line in data_str.strip().split("\n"):
        if line:
            derivations.append(json.loads(line))
    return derivations


def build_dependency_graph(derivations):
    """Build a dependency graph from the derivations."""
    # Map from derivation path to its index in the derivations list
    drv_path_to_index = {}
    for i, drv in enumerate(derivations):
        drv_path_to_index[drv["drvPath"]] = i

    # Build the graph: node -> [dependencies]
    graph = defaultdict(list)
    # Build the reverse graph: node -> [dependents]
    reverse_graph = defaultdict(list)

    for i, drv in enumerate(derivations):
        for input_drv in drv["inputDrvs"]:
            if input_drv in drv_path_to_index:
                dep_idx = drv_path_to_index[input_drv]
                graph[i].append(dep_idx)
                reverse_graph[dep_idx].append(i)

    return graph, reverse_graph, drv_path_to_index


def compute_layers(derivations, graph, reverse_graph):
    """Compute layers of the build graph for maximum parallelism."""
    n = len(derivations)
    in_degree = [len(graph[i]) for i in range(n)]

    # Start with nodes that have no dependencies
    queue = deque([i for i in range(n) if in_degree[i] == 0])
    layers = []

    while queue:
        current_layer = []
        layer_size = len(queue)

        for _ in range(layer_size):
            node = queue.popleft()
            current_layer.append(node)

            # Reduce in-degree of all dependents
            for dependent in reverse_graph[node]:
                in_degree[dependent] -= 1
                if in_degree[dependent] == 0:
                    queue.append(dependent)

        layers.append(current_layer)

    return layers


def format_output(derivations, layers):
    """Format the output with the build layers."""
    result = []

    for i, layer in enumerate(layers):
        layer_info = {"layer": i + 1, "derivations": []}

        for node_idx in layer:
            drv = derivations[node_idx]
            layer_info["derivations"].append(drv)
        result.append(layer_info)

    return result


def main(data_str):
    derivations = parse_derivation_data(data_str)
    graph, reverse_graph, drv_path_to_index = build_dependency_graph(
        derivations
    )
    layers = compute_layers(derivations, graph, reverse_graph)
    result = format_output(derivations, layers)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    # Read from stdin
    data_str = sys.stdin.read()

    main(data_str)
