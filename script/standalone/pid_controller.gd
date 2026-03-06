## Credit goes to mattogodoy.
## Slightly edited from:
## https://gist.github.com/mattogodoy/910ef7612950161f4a9871c09b62fec7
extends Object
class_name PIDController

enum DerivativeMeasurement {
	VELOCITY,
	ERROR_RATE_OF_CHANGE
}

# PID coefficients
@export var proportional_gain: float = 0.2
@export var integral_gain: float = 0.1
@export var derivative_gain: float = 0.2

@export var output_min: float = -1.0
@export var output_max: float = 1.0
@export var integral_saturation: float
var derivative_measurement: DerivativeMeasurement = DerivativeMeasurement.VELOCITY

var value_last: float
var error_last: float
var integration_stored: float
var derivative_initialized: bool = false


func reset():
	derivative_initialized = false


func update(current_value: float, target_value: float, delta: float) -> float:
	if delta <= 0:
		push_error("delta must be greater than 0")
		return 0.0

	var error = target_value - current_value

	# calculate P term
	var P = proportional_gain * error

	# calculate I term
	integration_stored = clamp(integration_stored + (error * delta), -integral_saturation, integral_saturation)
	var I = integral_gain * integration_stored

	# calculate both D terms
	var error_rate_of_change = (error - error_last) / delta
	error_last = error

	var value_rate_of_change = (current_value - value_last) / delta
	value_last = current_value

	# choose D term to use
	var derive_measure = 0.0

	if derivative_initialized:
		if derivative_measurement == DerivativeMeasurement.VELOCITY:
			derive_measure = -value_rate_of_change
		else:
			derive_measure = error_rate_of_change
	else:
		derivative_initialized = true

	var D = derivative_gain * derive_measure

	var result = P + I + D

	return clamp(result, output_min, output_max)


func angle_difference(a: float, b: float) -> float:
	return fmod((a - b + 540.0), 360.0) - 180.0  # calculate modular difference, and remap to [-180, 180]


func update_angle(current_angle: float, target_angle: float, delta: float) -> float:
	if delta <= 0:
		push_error("delta must be greater than 0")
		return 0.0

	var error = angle_difference(target_angle, current_angle)

	# calculate P term
	var P = proportional_gain * error

	# calculate I term
	integration_stored = clamp(integration_stored + (error * delta), -integral_saturation, integral_saturation)
	var I = integral_gain * integration_stored

	# calculate both D terms
	var error_rate_of_change = angle_difference(error, error_last) / delta
	error_last = error

	var value_rate_of_change = angle_difference(current_angle, value_last) / delta
	value_last = current_angle

	# choose D term to use
	var derive_measure = 0.0

	if derivative_initialized:
		if derivative_measurement == DerivativeMeasurement.VELOCITY:
			derive_measure = -value_rate_of_change
		else:
			derive_measure = error_rate_of_change
	else:
		derivative_initialized = true

	var D = derivative_gain * derive_measure

	var result = P + I + D

	return clamp(result, output_min, output_max)
