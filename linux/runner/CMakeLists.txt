cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Snap-packaged Flutter links with its own (older) glibc, so symbols that host
# media libraries reference (GLIBC_2.34+) look undefined at link time even
# though they resolve fine at runtime against the host glibc. Defer shared-lib
# symbol resolution to runtime.
target_link_options(${BINARY_NAME} PRIVATE "-Wl,--allow-shlib-undefined")

# Link libmpv into the runner itself. The executable's RUNPATH ($ORIGIN/lib)
# then resolves the *bundled* libmpv.so.2 before any plugin's NEEDED entry can
# pull in a system copy — the process must only ever hold ONE libmpv, or
# mpv_render_context_create aborts on mismatched internal option state.
# --no-as-needed, because the runner references no mpv symbol directly.
pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)
target_link_libraries(${BINARY_NAME} PRIVATE "-Wl,--no-as-needed" PkgConfig::MPV)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
