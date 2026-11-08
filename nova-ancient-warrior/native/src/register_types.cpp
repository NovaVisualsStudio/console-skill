#include "register_types.h"
#include <godot_cpp/godot.hpp>
#include "nova_combat_kernel.h"
using namespace godot;
void initialize_nova_combat_kernel(ModuleInitializationLevel p_level) {
 if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
 GDREGISTER_CLASS(NovaCombatKernel);
}
void uninitialize_nova_combat_kernel(ModuleInitializationLevel p_level) {
 if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}
extern "C" {
GDExtensionBool GDE_EXPORT nova_combat_kernel_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
 GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
 init_obj.register_initializer(initialize_nova_combat_kernel);
 init_obj.register_terminator(uninitialize_nova_combat_kernel);
 init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
 return init_obj.init();
}
}
