#include "nova_combat_kernel.h"
#include <godot_cpp/core/class_db.hpp>
#include <algorithm>
#include <cmath>
namespace godot {
void NovaCombatKernel::_bind_methods() {
 ClassDB::bind_method(D_METHOD("find_targets_in_attack_arc", "origin", "forward", "target_positions", "max_range", "half_angle_degrees"), &NovaCombatKernel::find_targets_in_attack_arc);
}
PackedInt32Array NovaCombatKernel::find_targets_in_attack_arc(const Vector3 &origin, const Vector3 &forward, const PackedVector3Array &target_positions, double max_range, double half_angle_degrees) const {
 PackedInt32Array result;
 if (max_range <= 0.0 || forward.length_squared() <= 1.0e-8 || target_positions.is_empty()) return result;
 const Vector3 direction = forward.normalized();
 const double degrees = std::clamp(half_angle_degrees, 0.0, 180.0);
 const double threshold = std::cos(degrees * Math_PI / 180.0);
 const double max_range_squared = max_range * max_range;
 for (int32_t index = 0; index < target_positions.size(); ++index) {
  const Vector3 offset = target_positions[index] - origin;
  const double distance_squared = offset.length_squared();
  if (distance_squared <= 1.0e-8 || distance_squared > max_range_squared) continue;
  const double facing = direction.dot(offset) / std::sqrt(distance_squared);
  if (facing >= threshold) result.push_back(index);
 }
 return result;
}
}
