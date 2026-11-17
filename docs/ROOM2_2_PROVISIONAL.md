Room2.2 provisional

World: 2172 x 724, original composition at scale 1, nearest.
The cyan platform painted into the background remains TEMPORARY VISUAL PLACEHOLDER, without collision. Only the smaller moving sprite is solid.

Entry FromRoom2: (125,382). Return to Room2: (1550,78), separated from exit at (1630,78).
Transport: AnimatableBody2D, physics-synchronized, x=260..365, top y=440, 60 px/s, waits 1 second at each end. Sprite 150x70, independent collider 146x12.
Main floor is a provisional continuous support at y=500 across the cracked illustrated floor. Fine collision/art alignment is pending.
Room3 door: marker (1960,480); Area2D disabled, without transition script.
Falls recover on the last safe bank without damage, following Room1.5 convention. No player transport via position assignment.
Shared Player, camera (bounds 2172x724), HUD and Room2 health/defeat controller reused.

Focused test: tests/room22_transport_test.gd uses real movement for boarding, riding, reversals, jumping, disembarking and door approach. Transition checks invoke the existing area handler.
