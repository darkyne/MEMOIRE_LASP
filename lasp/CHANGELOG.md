# 0.8.2

* Fix packaging.

# 0.8.1

* Bump partisan dependencies.

# 0.8.0

* Delta dissemination supports forced propagation after update.
* Added experimental Redis backend.

# 0.7.2

* Add partial replication support to the reverse topological sort behavior.

# 0.7.1

* Fix bad plumtree dependency.

# 0.7.0:

* Prototype support for partial replication if you're using the default peer service manager with no broadcast trees.  This feature adds the ability to make nodes interested in certain replication topics using `interested/1` and `disinterested/1`, and tag objects accordingly using `set_topic/2` and `remove_topic/2`.  Objects that have topics not matching the node interests will be not replicated during the normal anti-entropy process using an algorithms inspired by the Footloose protocol.  This dissemination mechanism is *experimental* and not supported when broadcast trees are enabled, nor under any of the partially connected overlays.
