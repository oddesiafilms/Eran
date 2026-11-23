extends Node3D
# Eran: first playable greybox, not final artwork.

var hero: CharacterBody3D
var pivot: Node3D
var look_yaw := 0.0
var look_pitch := -0.12
var movement := Vector2.ZERO
var left_touch := -1
var right_touch := -1
var left_origin := Vector2.ZERO

func _ready() -> void:
    var environment := WorldEnvironment.new()
    var sky := Environment.new()
    sky.background_mode = Environment.BG_COLOR
    sky.background_color = Color(0.55, 0.67, 0.77)
    sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color = Color(0.72, 0.73, 0.69)
    environment.environment = sky
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -35, 0)
    sun.light_color = Color(1.0, 0.88, 0.73)
    add_child(sun)
    _box(Vector3(0, -0.65, 0), Vector3(120, 1.2, 120), Color(0.31, 0.42, 0.28))
    _box(Vector3(0, -0.02, -22), Vector3(4, 0.08, 52), Color(0.48, 0.42, 0.32))
    for i in range(22):
        var x := float((i * 23) % 100) - 50.0
        var z := float((i * 31) % 100) - 50.0
        if abs(x) < 7.0: x += 12.0
        _box(Vector3(x, 2, z), Vector3(0.7, 4, 0.7), Color(0.31, 0.25, 0.18))
        _box(Vector3(x, 5, z), Vector3(3.5, 4, 3.5), Color(0.18, 0.34, 0.22))
    for i in range(7):
        var h := 5.0 + float(i % 3) * 3.0
        _box(Vector3(-21 + i * 6, h / 2, -49), Vector3(4, h, 4), Color(0.43, 0.42, 0.39))
    _make_hero()
    var hud := CanvasLayer.new()
    add_child(hud)
    var label := Label.new()
    label.text = "ERAN — Vale of Heth (prototype)\nDrag left to move, right to look. Keyboard arrows/WASD also work."
    label.position = Vector2(20, 20)
    hud.add_child(label)

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    body.add_child(mesh)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)
    add_child(body)

func _make_hero() -> void:
    hero = CharacterBody3D.new()
    hero.position = Vector3(0, 2, 9)
    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    mesh.mesh = capsule
    hero.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.8
    collision.shape = shape
    hero.add_child(collision)
    add_child(hero)
    pivot = Node3D.new()
    pivot.position.y = 1.4
    hero.add_child(pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.4, 5.5)
    camera.current = true
    pivot.add_child(camera)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var left_half := touch.position.x < get_viewport().get_visible_rect().size.x * 0.5
        if touch.pressed and left_half and left_touch == -1:
            left_touch = touch.index
            left_origin = touch.position
        elif touch.pressed and not left_half and right_touch == -1:
            right_touch = touch.index
        elif not touch.pressed:
            if touch.index == left_touch:
                left_touch = -1
                movement = Vector2.ZERO
            if touch.index == right_touch: right_touch = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == left_touch:
            movement = ((drag.position - left_origin) / 70.0).limit_length(1.0)
        elif drag.index == right_touch:
            _look(drag.relative)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _look(event.relative)

func _look(delta: Vector2) -> void:
    look_yaw -= delta.x * 0.004
    look_pitch = clamp(look_pitch - delta.y * 0.004, -0.7, 0.6)

func _physics_process(delta: float) -> void:
    pivot.rotation = Vector3(look_pitch, look_yaw, 0)
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := keyboard if keyboard.length() > 0.01 else movement
    var forward := Vector3(sin(look_yaw), 0, cos(look_yaw))
    var right := Vector3(cos(look_yaw), 0, -sin(look_yaw))
    var velocity := (right * direction.x + forward * direction.y).normalized() * 5.0
    hero.velocity.x = velocity.x
    hero.velocity.z = velocity.z
    if hero.is_on_floor():
        hero.velocity.y = -0.1
    else:
        hero.velocity.y -= 18.0 * delta
    hero.move_and_slide()
