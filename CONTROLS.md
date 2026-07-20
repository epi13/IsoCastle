# Controls and Input Remapping

## Default gameplay bindings

- Movement: `W A S D`, arrows, D-pad, or left stick; diagonals use `Q E Z C`.
- Wait: `X` or `.`.
- Interact: `F`, Enter, or controller south/A.
- Search: `V`.
- Inventory: `I` or controller north/Y.
- Spellbook, journal, map: `B`, `J`, `M`.
- Cast prepared spell: `1` or controller west/X.
- Ranged attack: `2` or middle mouse.
- Quick item: `3` or right shoulder.
- Quick save/load: `F8` / `F9`.
- Pause/cancel: Escape or controller east/B.
- Developer overlay and screenshot mode: `F2` / `F3`.

The HUD and relevant help panels show current bindings rather than assuming these defaults.

## Inventory drag-and-drop

Open inventory and drag a carried stack to another carried slot to reorder, swap, or merge compatible variants. Drag equipment to its compatible named slot, or drag equipped items back into an available inventory slot. Invalid destinations tint red and preserve the original state; valid destinations tint green. Releasing elsewhere cancels without mutation. The drag ghost shows the exact item and quantity.

Right-click a stack with quantity greater than one to open the split amount selector. Non-stackable items and quantities that would create zero/negative stacks cannot split. Stack limits, affixes, identification/state metadata, requirements, weight, capacity, and single ownership are enforced by transactional domain operations.

Keyboard and controller users can focus slots and press Accept to equip, use, or unequip. Escape/controller cancel closes inventory. Item tooltips remain available to pointer users.

## Remapping editor

Open Settings & Accessibility, scroll to Input Remapping, then select a binding to replace it or choose `+ Add`. Capture accepts physical keys, mouse buttons, controller buttons, and deliberate controller-axis movement. Mouse motion, key repeat, and small axis noise are ignored. Escape or `Cancel Capture` abandons capture without changing bindings.

Conflicts are never assigned silently: the confirmation dialog can move the binding from the conflicting action or preserve the existing layout. Optional bindings can be cleared. Every action has Reset, and Reset All Defaults has a separate confirmation. The final cancel/back binding cannot be removed, so menu navigation remains recoverable.

Bindings use a stable typed settings format rather than serialized Godot objects. Unknown/removed actions are ignored, renamed actions migrate, and newly introduced actions inherit explicit defaults. Settings are independent from campaign save slots. Browser-critical refresh/window shortcuts are rejected as Web defaults or captures where necessary.
