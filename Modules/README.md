# Modules

### `plugin/plugin_pathcreation.lua` - Developer Studio plugin to quickly create custom path objects directly by developer input.
- click to place nodes in the world, attaching in a linear fashion.
- convert linear paths to bezier curves with visual feedback and modification of spline-node capacity. 
- format instances across rigid and curved paths to create fantastical curves or realistic walkways.
- define position,size, and randomize rotation & colors from predefined ranges when iteratively generating instances following these paths
- dynamically move, udpate, and delete paths based on node traversal
- intuitively define instances for later modification by external scripts
- pick-up where you left off with reabsorption and modification of existing paths.

### `stepper.lua` - custom wrapper bringing extended QoL functionality and maintainability to RBXScriptConnections (Event listeners)
- provide named identifiers to lookup event callbacks
- connect all callbacks to a single listener (as opposed to individual), streamlining memory management and listener complexity
- Easily Enable/Disable callbacks without disconnecting entirely
- Defer events which require next-frame actions
- Automatically manage predefined delays between callbacks for events which run on a timer.
- accept the newer ContextActions, RBXScriptConnections, and dynamic Attribute-Change-Listeners.

### `m_gui.lua` - extensive GUI library streamlining UI development of once-primitive UiObjects
- create menu frames which auto-load and separate data for simplified user navigation
- complex UI types such as Drag-and-Drops, Fillbars, Radio Buttons, Dropdowns+Search, Custom Popups, and Custom Notifications
- dynamically convert text-style GuiObjects into Image+Text containers
- Enable dragging and rescaling of any and all UI objects.

### `keybinder.lua` - client-side library to simplify assigning keyboard callbacks to developer functions and events
- name keybinds and allow safe overriding (auto cleanup)
- support any key input, with Ctrl/Alt combinations
- support different callbacks via repetitive presses as well.

### `world_tracing_projection` - 2 modules to simplify creating "traced" objects in the 2d UI-space and 3d world-space.
- `tracers.lua` - simple setup between parts, positions, and the local player to apply 2d or 3d-space tracers. simplify management of multiple tracers with destructors and rendering on-demand.
- `Visualize.lua` - 2D tracer automation utilizing the build in Drawing library of modern executors. Similar purpose to `tracers.lua`

### `collab_switch_server` - had nowhere else to put this, but created for a [friend's game](https://www.roblox.com/games/180364455)
- provide a straightforward user interface allowing users to manually join servers by ID.
- circumvent automatic filling algorithm (which prevents servers from actually being full), for increased gameplay with others.

### `fly` - symlink to Exploits, modularized tool for player flight.
- allow the player to enable flight with simple commands (Stop, Start, Toggle,...)
- modify speed, lock/unlock axes of flight, enable/disable collisions and check states with simple commands
- utilize the stepper module to allow further modification without directly changing the module.

### `fs_data_save` - custom data-saving algorithm which packages primitive lua types into exportable strings.
- support strings, numbers, booleans, and nested tables. Obviously, userdata and closures are stored as bytecode and cannot be exported in their states.
- automatic cyclic table detection and halting to prevent infinite reference cycling.
- morse code-like style of data-saving which obfuscates info from a general reader from viewing (not real encryption, added for fun!)
### `bezier.lua` - simple recursive algorithm to calculate points along a bezier curve, given a set of nodes.

### `circular_exclusion.lua` - made for a [friend's game](https://www.roblox.com/games/4458781057/)
- given a 2D or 3D bounding box, select a random point not within a given radius of the center. Finds points outside a circle/sphere.

### `complex_numbers.lua` - library introducing imaginary and complex numbers to Lua.
- use cases include fractal generation, wave processing, and recreating the quaternion (but why would you do that).

### `partmanipulation.lua` - library to collect unanchored (physics-active) parts and create fantastical patterns with custom parametric equations.
- automatically determine physics-engine owner (as it is split among clients & server) and ignore those which the current client does not own.
- support parametric equation-defining for next-step-on-path rendering by accepting developer lua closures and wrapping with custom environments to support simplified mathematics operations.
- play and automatically separate instances along entire path, looping repeatedly when played on-demand.

### `playerapi.lua` - client-side module to simplify various operations and common player-info fetches
- fetch Humanoid object, player RootPart (center of gravity), with fault protection when unpresent (malformed Player.Character)
- Set WalkSpeed, JumpPower/JumpHeight, ability to ragdoll, ability to collide, and dynamically teleport or tween player position & orientation.
- Exploit specific: enable bunny-hopping (preserving speed mid-air on direction changes), and infinite jump ( reset humanoid jump-state to enable illicit vertical movement)

### `require.lua` - an extension to the default require() function. used in nearly every modern script I wrote.
- preserve searching by instance (default); enable loading by internet-based sources and local files
- Exploit specific: mask legitimacy of caller by remapping script thread identity to match true dev-script permissions (prevent detection when loading game modules).

### `shared.lua` - literally just a shared table to centralize and store persistent data from various modules/scripts


### `trash.lua` - improve garbage collection and avoid memory leak by recursively applying (confusing) metatable tags which aid Lua's garbage collector in freeing memory.