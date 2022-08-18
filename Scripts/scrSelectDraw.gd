"""
Handles drawing of Box Select rectangle
"""

extends Node2D


var dragStart = Vector2.ZERO
var dragEnd = Vector2.ZERO
var dragging = false

func _draw():
	if dragging:
		draw_rect(Rect2(dragStart, dragEnd - dragStart), Color(0, 1, 0, 1), false)
		draw_rect(Rect2(dragStart, dragEnd - dragStart), Color(0, 1, 0, .10), true)

func UpdateStatus(start, end, drag):
	dragStart = start
	dragEnd = end
	dragging = drag
	update()
