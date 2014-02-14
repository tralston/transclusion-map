require_relative 'WikiPage.rb'
require 'rubygems'
require 'graphviz'

LEVELS = 10

$g = GraphViz.new(:G, type: :digraph)
$levels = 1

def make_tree(pagename)

	if WikiPages.pages.find_all { |p| p.name == pagename }.count == 0
    w = WikiPages.add(pagename)

    puts "Processing: #{w.name} (level #{$levels})"

    w_name = w.name.gsub(/Template:/, '')
    parent = $g.get_node(w_name)

    # Deletes templates from the list if a link already exists in the graph
    unless parent.nil?
      w.templates.reject! { |t| parent.neighbors.map(&:id).include? t }
      deleted = w.templates.select { |t| parent.neighbors.map(&:id).include? t }
      puts "--- Templates deleted: #{deleted}" unless deleted.empty?
    end

    w.templates.each do |t|
      puts "   #{t}"
      w_name = w.name.gsub(/Template:/, '')
      tt     = t.gsub(/Template:/, '')
      node1  = parent.nil? ? $g.add_nodes(w_name) : parent
      node2  = $g.get_node(tt).nil? ? $g.add_nodes(tt) : $g.get_node(tt)

      $g.add_edges(node1, node2)
    end

    return if $levels == LEVELS
    $levels += 1
    w.templates.each do |t|
      tt    = t.gsub(/Template:/, '')
      child = $g.get_node(tt)
      make_tree(t) if child.neighbors.count == 0
    end
    $levels -= 1
  end
end

make_tree('ABC')

$g.output(png: "test.png")
#$g.output(dot: "nodes.dot")
