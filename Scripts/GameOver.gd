# GameOver.gd
extends Panel

@onready var score_label = $ScoreLabel
@onready var restart_button = $RestartButton

func show_game_over(final_score):
	score_label.text = "Final Score: " + str(final_score)
	show()

func _on_restart_button_pressed():
	get_parent().restart_game()
	hide()
