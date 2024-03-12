import networkx as nx


def filter_big_scc(g,edges_to_be_removed):
	#Given a graph g and edges to be removed
	#Return a list of big scc subgraphs (# of nodes >= 2)
	# Create a new graph by removing edges from the original graph
	new_graph = g.copy()
	new_graph.remove_edges_from(edges_to_be_removed)
	
	# Get the strongly connected components
	strongly_connected_components = list(nx.strongly_connected_components(new_graph))
	# Create subgraphs from the strongly connected components
	strongly_connected_subgraphs = [new_graph.subgraph(component) for component in strongly_connected_components]

	sub_graphs = [scc for scc in strongly_connected_subgraphs if scc.number_of_nodes() >= 2]
	return sub_graphs

def get_big_sccs(g):
	#self_loop_edges = g.selfloop_edges()
	self_loop_edges = [(u, v) for u, v in g.edges() if u == v]
	g.remove_edges_from(self_loop_edges)
	num_big_sccs = 0
	edges_to_be_removed = []
	big_sccs = []
	
	# Get the strongly connected components
	strongly_connected_components = list(nx.strongly_connected_components(g))
	# Create subgraphs from the strongly connected components
	strongly_connected_subgraphs = [g.subgraph(component) for component in strongly_connected_components]
	# Now, you can iterate over the subgraphs
	for sub in strongly_connected_subgraphs:
	
	#for sub in nx.strongly_connected_component_subgraphs(g):
		number_of_nodes = sub.number_of_nodes()
		if number_of_nodes >= 2:
			# strongly connected components
			num_big_sccs += 1
			big_sccs.append(sub)
	#print(" # big sccs: %d" % (num_big_sccs))
	return big_sccs

def nodes_in_scc(sccs):
	scc_nodes = []
	scc_edges = []
	for scc in sccs:
		scc_nodes += list(scc.nodes())
		scc_edges += list(scc.edges())

	#print("# nodes in big sccs: %d" % len(scc_nodes))
	#print("# edges in big sccs: %d" % len(scc_edges))
	return scc_nodes

def scc_nodes_edges(g):
	scc_nodes = set()
	scc_edges = set()
	num_big_sccs = 0
	num_nodes_biggest_scc = 0
	biggest_scc = None
	# Get the strongly connected components
	strongly_connected_components = list(nx.strongly_connected_components(g))
	# Create subgraphs from the strongly connected components
	strongly_connected_subgraphs = [g.subgraph(component) for component in strongly_connected_components]
	# Now, you can iterate over the subgraphs
	for sub in strongly_connected_subgraphs:
	#for sub in nx.strongly_connected_component_subgraphs(g):
		number_nodes = sub.number_of_nodes()
		if number_nodes >= 2:
			scc_nodes.update(sub.nodes())
			scc_edges.update(sub.edges())
			num_big_sccs += 1
			if num_nodes_biggest_scc < number_nodes:
				num_nodes_biggest_scc = number_nodes
				biggest_scc = sub
	nonscc_nodes = set(g.nodes()) - scc_nodes
	nonscc_edges = set(g.edges()) - scc_edges
	print(num_nodes_biggest_scc)
	print(("num of big sccs: %d" % num_big_sccs))
	if biggest_scc == None:
		return scc_nodes,scc_nodes,nonscc_nodes,nonscc_edges
	print(("# nodes in biggest scc: %d, # edges in biggest scc: %d" % (biggest_scc.number_of_nodes(),biggest_scc.number_of_edges())))
	print(("# nodes,edges in scc: (%d,%d), # nodes, edges in non-scc: (%d,%d) " % (len(scc_nodes),len(scc_edges),len(nonscc_nodes),len(nonscc_edges))))
	num_of_nodes = g.number_of_nodes()
	num_of_edges = g.number_of_edges()
	print(("# nodes in graph: %d, # of edges in graph: %d, percentage nodes, edges in scc: (%0.4f,%0.4f), percentage nodes, edges in non-scc: (%0.4f,%0.4f)" % (num_of_nodes,num_of_edges,len(scc_nodes)*1.0/num_of_nodes,len(scc_edges)*1.0/num_of_edges,len(nonscc_nodes)*1.0/num_of_nodes,len(nonscc_edges)*1.0/num_of_edges)))
	return scc_nodes,scc_edges,nonscc_nodes,nonscc_edges


def c_c(graph_file):
	g = nx.read_edgelist(graph_file,create_using = nx.Graph(),nodetype = int)
	graphs = nx.connected_component_subgraphs(g)
	for graph in graphs:
		print(graph.number_of_nodes(),graph.number_of_edges())
	print(len(graphs))
