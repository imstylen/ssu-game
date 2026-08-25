class_name GainEnergyBehavior
extends CardBehavior

@export_group("Community Effect Fields")
@export_range(0, 20) var energy_amount: int = 1
@export_group("")


func on_played(context: EffectContext, _card: CardInstance) -> void:
	context.gain_energy(energy_amount)
