# function that converts from a particular data format into the generic one
# expected by the plugin
convert = (rawData) ->
  value = 0
  for state in ['RUNNABLE', 'BLOCKED', 'TIMED_WAITING', 'WAITING']
    value += rawData.c[state] if not isNaN(rawData.c[state])

  timeFormat =  countdown.DAYS | countdown.HOURS | countdown.MINUTES | countdown.SECONDS)
  node =
    name: rawData.n,
    value: value,
    samples: value
    totalTime: countdown(new Date(), timeElapsed, timeFormat)
    children: []

  # the a field is the list of children
  return node if not rawData.a

  childSum = 0
  for child in rawData.a
    subTree = convert(child)
    if subTree
      node.children.push(subTree)
      childSum += subTree.value

  if childSum < node.value
    fillerNode =
      value: node.value - childSum
      samples: node.value - childSum
      opacity: 0
      type: 'filler'
    node.children.push(fillerNode)

  node

# augments each node in the tree with the maximum distance
# it is from a terminal node
maxDepth = (node) ->
  return 0 if not node
  return 1 if not node.children
  return node.maxDepth if node.maxDepth

  max = 0
  node.children.forEach (child) ->
    depth = maxDepth(child)
    max = depth if depth > max

  node.maxDepth = max + 1
  return node.maxDepth

d3.json "data/profile.json", (err, data) ->

  profile = convert(data.profile)
  maxDepth(profile)

  d3.flameGraph()
    .containerSelector('#d3-flame-graph')
    .width(1200).height(600).cellHeight(10)
    .data(profile)
    .colorScheme(["#ffffcc","#ffeda0","#fed976","#feb24c","#fd8d3c","#fc4e2a","#e31a1c","#bd0026"])
    .render()