#ifndef NOVA_COMBAT_KERNEL_H
#define NOVA_COMBAT_KERNEL_H
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/vector3.hpp>
namespace godot {
class NovaCombatKernel : public RefCounted {
 GDCLASS(NovaCombatKernel, RefCounted)
protected:
 static void _bind_methods();
public:
 PackedInt32Array find_targets_in_attack_arc(const Vector3 &origin, const Vector3 &forward, const PackedVector3Array &target_positions, double max_range, double half_angle_degrees) const;
};
}
#endif
