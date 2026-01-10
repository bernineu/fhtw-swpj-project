# Hungry Dog - Manual Test Checklist

### Player Controls
- [ ] WASD movement works smoothly
- [ ] Camera rotates with mouse (LMB captured)
- [ ] ESC releases camera
- [ ] Player can pick up snacks within 3 units
- [ ] Pickup animation plays
- [ ] Discipline works within 5 units of dog
- [ ] Discipline has 1 second cooldown
- [ ] Clapping animation plays on discipline

### Dog AI Behavior
- [ ] Dog finds and moves to nearest snack
- [ ] Dog navigates around furniture/obstacles
- [ ] Dog eats snack after 2 seconds
- [ ] Dog stops moving while eating
- [ ] Dog pauses 2 seconds when disciplined
- [ ] Dog plays appropriate animations (Gallop, Eating, Idle)

### Snack System
- [ ] Snacks spawn every 3 seconds
- [ ] Snacks spawn on valid floor positions
- [ ] Snacks rotate visually
- [ ] All snack types appear (Dog Food, Cheese, Chocolate)

### Dog Health & Death
- [ ] Dog has 3 lives initially
- [ ] Dog loses 1 life on chocolate (x3 = death)
- [ ] Dog dies instantly on poison
- [ ] Death animation plays
- [ ] Game over triggers on dog death

### Hunger System
- [ ] Hunger increases over time
- [ ] Hunger decreases when eating snacks
- [ ] Hunger is clamped between 0.0 and 1.0

### Score & Overflow
- [ ] Score increases 1 per second
- [ ] Score increases 5 per pickup
- [ ] Overflow bar increases with spawns
- [ ] Overflow bar decreases with pickups
- [ ] Game over at 20 overflow
- [ ] Score stops increasing at game over

### UI/HUD
- [ ] Overflow bar displays correctly
- [ ] Score displays and updates
- [ ] Game over panel shows on game over
- [ ] "Again" button restarts game
- [ ] Returns to menu on restart

### Menu System
- [ ] Can select Male/Female character
- [ ] Start button works
- [ ] Selected gender loads correct player model

### Edge Cases
- [ ] Dog handles snack removed mid-navigation
- [ ] Player can't pick up while animation playing
- [ ] Multiple disciplines respect cooldown
- [ ] Game handles 20+ snacks without lag
- [ ] Discipline during eating interrupts eating

## Performance
- [ ] 60 FPS with 20+ snacks
- [ ] No stuttering during gameplay
- [ ] Smooth camera movement

## Platforms
- [ ] Windows works
- [ ] macOS works (if applicable)
- [ ] Linux works (if applicable)